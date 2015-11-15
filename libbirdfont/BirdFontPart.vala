/*
	Copyright (C) 2014 Johan Mattsson

	This library is free software; you can redistribute it and/or modify 
	it under the terms of the GNU Lesser General Public License as 
	published by the Free Software Foundation; either version 3 of the 
	License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful, but 
	WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
	Lesser General Public License for more details.
*/

namespace BirdFont {

/** BirdFontPart is a class for parsing .bfp files. The file format is 
 * identical to .bf but the font is split in many parts. Each part
 * contains a few elements and all parent nodes from the root node and
 * downwards. The .bfp files can be parsed in any order. The root directory
 * of a .bfp tree must have a file with the name "description.bfp", this file 
 * tells the parser that bfp files in parent directories should be excluded.
 */
public class BirdFontPart : GLib.Object{
	unowned Font font;
	Gee.ArrayList<string> parts;
	string root_directory;

	static string FILE_ATTRIBUTES = "standard::*";

	public BirdFontPart (Font font) {	
		this.font = font;

		font.font_deleted.connect (() => {
			this.font = Font.empty;
		});
		
		parts = new Gee.ArrayList<string> ();
		root_directory = "";
	}
	
	public bool load (string bfp_file) {
		BirdFontFile bf = new BirdFontFile (font);
		File bfp_dir;
		File image_dir;
		
		try {
			find_all_parts (bfp_file);
			font.set_bfp (true);
			
			font.background_images.clear ();

			bfp_dir = File.new_for_path (root_directory);
			image_dir = get_child (bfp_dir, "images");
			copy_backgrounds ((!) image_dir.get_path ());

			foreach (string fn in parts) {
				bf.load_part (fn);
			}
		} catch (GLib.Error e) {
			warning (e.message);
			return false;
		}
		
		return true;
	}
	
	public string get_path () {
		string path = "";
		
		try {
			path = (!) get_destination_file (@"$(font.full_name).bfp").get_path ();
		} catch (GLib.Error e) {
			warning (e.message);
		}
		
		return path;
	}
	
	public bool save () {
		DataOutputStream os;
		BirdFontFile bf = new BirdFontFile (font);
		bool error = false;
		string file_name;
		string glyph_dir_name;
		File glyph_file;
		
		if (root_directory == "") {
			warning ("No directory is created for this birdfont part.");
			return false;
		}
			
		try {
			// remove deleted glyphs
			foreach (Glyph g in font.deleted_glyphs) {
				file_name = get_glyph_base_file_name (g) + ".bfp";
				glyph_dir_name = get_subdir_name (file_name);
				glyph_file = get_destination_file (file_name, "glyphs", glyph_dir_name);
				
				if (glyph_file.query_exists ()) {
					glyph_file.delete ();
				}
				
				print (@"$((!)glyph_file.get_path ())\n");
			}
			
			os = create_file (@"$(font.full_name).bfp");
			bf.write_root_tag (os);
			bf.write_closing_root_tag (os);
			os.close ();
			
			os = create_file ("description.bfp");
			bf.write_root_tag (os);
			bf.write_description (os);
			bf.write_closing_root_tag (os);
			os.close ();

			os = create_file ("lines.bfp");
			bf.write_root_tag (os);
			bf.write_lines (os);
			bf.write_closing_root_tag (os);
			os.close ();

			os = create_file ("settings.bfp");
			bf.write_root_tag (os);
			bf.write_settings (os);
			bf.write_closing_root_tag (os);
			os.close ();

			os = create_file ("spacing.bfp");
			bf.write_root_tag (os);
			bf.write_spacing_classes (os);
			bf.write_closing_root_tag (os);
			os.close ();

			os = create_file ("ligatures.bfp");
			bf.write_root_tag (os);
			bf.write_ligatures (os);
			bf.write_closing_root_tag (os);
			os.close ();

			os = create_file ("alternates.bfp");
			bf.write_root_tag (os);
			bf.write_alternates (os);
			bf.write_closing_root_tag (os);
			os.close ();
			
			font.glyph_cache.for_each ((gc) => {
				try {
					string selected_file_name;
					string dir_name;
			
					if (is_null (gc)) {
						warning ("No glyph collection");
					}

					selected_file_name = get_first_number_in_unicode (((!)gc).get_current ());
					dir_name = get_subdir_name (selected_file_name);
								
					os = create_file (@"selected_$(selected_file_name).bfp", "glyphs", dir_name);
					bf.write_root_tag (os);
					bf.write_glyph_collection_start (gc, os);
					bf.write_selected ((!) gc, os);
					bf.write_glyph_collection_end (os);
					bf.write_closing_root_tag (os);
					os.close ();
			
					foreach (Glyph g in gc.glyphs) {
						try {
							write_glyph (bf, gc, g);
							write_glyph_background_image (bf, gc, g);
						} catch (GLib.Error e) {
							warning (e.message);
						}
					}
				} catch (GLib.Error e) {
					warning (@"Can not save bfp files to $root_directory\n");
					warning (@"$(e.message) \n");
					error = true;
				}
			});

			os = create_file ("kerning.bfp");
			bf.write_root_tag (os);
			bf.write_kerning (os);
			bf.write_closing_root_tag (os);
			os.close ();

			os = create_file ("images.bfp");
			bf.write_root_tag (os);
			bf.write_images (os);
			bf.write_closing_root_tag (os);
			os.close ();
						
		} catch (GLib.Error e) {
			warning (@"Failed to save bfp files to $root_directory\n");
			warning (@"$(e.message) \n");
			error = true;
		}
		
		return !error;
	}

	void copy_backgrounds (string folder) throws GLib.Error {
		FileInfo info;
		FileInfo? fi;
		FileEnumerator e;
		string name;
		File image_dir;
		BackgroundImage bg;
		File found;
		File parts;
		File dest;
		
		image_dir = File.new_for_path (folder);
		
		if (image_dir.query_exists ()) {
			info = image_dir.query_info (FILE_ATTRIBUTES, FileQueryInfoFlags.NONE);
			if (info.get_file_type () != FileType.DIRECTORY) {
				warning (@"$((!) image_dir.get_path ()) is not a directory.");
				throw new FileError.NOTDIR ("Not a directory.");
			}

			e = image_dir.enumerate_children (FILE_ATTRIBUTES, 0);
			while ((fi = e.next_file ()) != null) {
				info = (!) fi;
				name = info.get_name ();
				
				if (info.get_file_type () == FileType.DIRECTORY) {
					found = get_child (image_dir, name);
					copy_backgrounds ((!) found.get_path ());
				}
				
				if (name.has_suffix (".png")) {
					found = get_child (image_dir, name);
					parts = get_child (font.get_backgrounds_folder (), "parts");
					dest = get_child (parts, name);
					bg = new BackgroundImage ((!) found.get_path ());
					bg.create_background_folders (font);
					bg.copy_if_new (dest);
				}
			}
		}
	}

	string get_first_number_in_unicode (Glyph g) throws GLib.Error {
		string s = Font.to_hex (g.unichar_code);
		s = s.replace ("U+", "");
		return s;
	}
	
	string get_glyph_base_file_name (Glyph g) throws GLib.Error {
		string s = get_first_number_in_unicode (g);
		s = @"U+$(s)_$(g.version_id)";
		return s;
	}

	public string get_subdir_name (string file_name) {
		string d = file_name;
		
		if (file_name.has_prefix ("U+")) {
			d = file_name.replace ("U+", "");
		} 
		
		return (!) d.get_char ().to_string ();
	}

	void write_glyph (BirdFontFile bf, GlyphCollection gc, Glyph g) throws GLib.Error {
		string file_name;
		string dir_name;
		DataOutputStream os;
	 
		file_name = get_glyph_base_file_name (g);
		dir_name = get_subdir_name (file_name);
					
		os = create_file (@"$(file_name).bfp", "glyphs", dir_name);
		bf.write_root_tag (os);
		bf.write_glyph_collection_start (gc, os);
		bf.write_glyph (g, os);
		bf.write_glyph_collection_end (os);
		bf.write_closing_root_tag (os);
		os.close ();
	}

	void write_glyph_background_image (BirdFontFile bf, GlyphCollection gc, Glyph g) throws GLib.Error {
		string file_name;
		string dir_name;
		BackgroundImage bg;
		File file;
		
		if (g.get_background_image () != null) {
			bg = (!) g.get_background_image ();

			if (bg.is_valid ()) {
				file_name = @"$(bg.get_sha1 ()).png";
				dir_name = get_subdir_name (file_name);
				file = get_destination_file (file_name, "images", dir_name);
				bg.copy_if_new (file);				
				
				// FIXME: GIT ADD
			}			
		}
	}
		
	public void create_directory (string directory) throws GLib.Error {	
		File dir = File.new_for_path (directory);
		File bfp_dir;
		int i = 2;
		
		if (directory.has_suffix (font.get_full_name ())) {
			bfp_dir = dir;
		} else {
			bfp_dir = get_child (dir, font.get_full_name ());
		}
		
		while (bfp_dir.query_exists ()) {
			bfp_dir = get_child (dir, @"$(font.get_full_name ())_$(i)");
			i++;
		}
		
		if (!dir.query_exists ()) {
			DirUtils.create ((!) dir.get_path (), 0755);
		}
		
		root_directory = (!) bfp_dir.get_path ();
		DirUtils.create (root_directory, 0755);
	}

	private void find_all_parts (string bfp_file) throws GLib.Error {	
		File start = File.new_for_path (bfp_file);
		FileInfo info;
		File root;
		
		info = start.query_info (FILE_ATTRIBUTES, FileQueryInfoFlags.NONE);
		if (info.get_file_type () != FileType.DIRECTORY) {
			start = (!) start.get_parent ();
		}

		root = find_root ((!)start.get_path ());
		root_directory = (!)root.get_path ();

		find_parts (root_directory);
	}

	private void find_parts (string directory) throws GLib.Error {	
		File start = File.new_for_path (directory);
		File found;
		FileInfo info;
		FileInfo? fi;
		FileEnumerator e;
		string name;
		
		
		info = start.query_info (FILE_ATTRIBUTES, FileQueryInfoFlags.NONE);
		if (info.get_file_type () != FileType.DIRECTORY) {
			warning (@"$directory is not a directory.");
			throw new FileError.NOTDIR ("Not a directory.");
		}

		e = start.enumerate_children (FILE_ATTRIBUTES, 0);
		while ((fi = e.next_file ()) != null) {
			info = (!) fi;
			name = info.get_name ();
			if (info.get_file_type () == FileType.DIRECTORY) {
				find_parts ((!) ((!) get_child (start, name)).get_path ());
			} else if (name.has_suffix (".bfp")) {
				found = get_child (start, name);
				parts.add ((!) found.get_path ());
			}
		}
	}
		
	private File find_root (string directory) throws GLib.Error {
		File start = File.new_for_path (directory);
		FileInfo info;
		FileInfo? fi;
		FileEnumerator e;
		
		info = start.query_info (FILE_ATTRIBUTES, FileQueryInfoFlags.NONE);
		if (info.get_file_type () != FileType.DIRECTORY) {
			warning ("Not a directory.");
			throw new FileError.NOTDIR ("Not a directory.");
		}

		e = start.enumerate_children (FILE_ATTRIBUTES, 0);
		while ((fi = e.next_file ()) != null) {
			info = (!) fi;
			if (info.get_name () == "description.bfp") {
				return start;
			}
		}
		
		if (start.get_parent () == null) {
			warning ("description.bfp not found");
			throw new FileError.FAILED ("description.bfp not found");
		}
		
		return find_root ((!)((!) start.get_parent ()).get_path ());
	}
	
	private File new_subdirectory (File d, string subdir) throws GLib.Error {
		FileInfo info;
		File dir;
		
		dir = d;
		dir = get_child (dir, subdir);
		
		if (!dir.query_exists ()) {
			DirUtils.create ((!) dir.get_path (), 0755);
		} else {
			info = dir.query_info (FILE_ATTRIBUTES, FileQueryInfoFlags.NONE);
			if (info.get_file_type () != FileType.DIRECTORY) {
				throw new FileError.FAILED (@"Can't save font, $subdir is not a directory.");
			}
		}
		return dir;
	}
	
	private File get_destination_file (string name, string subdir1 = "", string subdir2 = "") throws GLib.Error {
		File file;
		File dir;

		dir = File.new_for_path (root_directory);
		
		if (subdir1 != "") {
			dir = new_subdirectory (dir, subdir1);
		}

		if (subdir2 != "") {
			dir = new_subdirectory (dir, subdir2);
		}
				
		file = get_child (dir, name);

		if (file.query_file_type (0) == FileType.DIRECTORY) {
			throw new FileError.FAILED (@"Can't save font, $name is a directory.");
		}
		
		return file;
	}
	
	private DataOutputStream create_file (string name, string subdir1 = "", string subdir2 = "") throws GLib.Error {
		DataOutputStream os;
		File file;
		string git_path;
		
		file = get_destination_file (name, subdir1, subdir2);

		if (file.query_exists ()) {
			file.delete ();
		}
		
		os = new DataOutputStream (file.create (FileCreateFlags.REPLACE_DESTINATION));
		
		if (subdir2 != "") {
			git_path = subdir1 + "/" + subdir2 + "/" + name;
		} else if (subdir1 != "") {
			git_path = subdir1 + "/" + name;
		} else {
			git_path = name;
		}
		
		// FIXME: git_index.add_path (git_path);
		
		return os;
	}
}

}
