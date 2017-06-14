/*
	Copyright (C) 2012 Johan Mattsson

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

public class Preview : FontDisplay {

	public Preview () {
	}

	public override string get_name () {
		return "Preview";
	}

	public override string get_label () {
		return t_("Preview");
	}

	public override void selected_canvas () {
		MainWindow.set_scrollbar_size (0);
	}

	public static string get_html_path () {
		return (!) get_file ().get_path ();
	}

	public static File get_file () {
		Font font = BirdFont.get_current_font ();
		string fn = get_html_file_name ();
		File dir = ExportTool.get_export_dir ();
		File file = get_child (dir, fn);

		if (!file.query_exists ()) {
			ExportTool.generate_html_document ((!)file.get_path (), font);
		}

		return file;
	}

	public static bool has_html_document () {
		string path = get_html_file_name ();
		File dir = 	ExportTool.get_export_dir ();
		File file = get_child (dir, path);
		return file.query_exists ();
	}

	public static void generate_html_document () {
		Font font = BirdFont.get_current_font ();
		string path = get_html_file_name ();
		File dir = ExportTool.get_export_dir ();
		File file = get_child (dir, path);
		ExportTool.generate_html_document ((!)file.get_path (), font);
	}

	public static void delete_html_document () {
		Font font = BirdFont.get_current_font ();
		string path = get_html_file_name ();
		File dir = font.get_folder ();
		File file = get_child (dir, path);
		try {
			file.delete ();
		} catch (Error e) {
			warning (e.message);
		}
	}

	static string get_html_file_name () {
		Font font = BirdFont.get_current_font ();
		return  @"$(ExportSettings.get_file_name (font)).html";
	}

	public static File get_html_file () {
		return get_file ();
	}

	public static string get_uri () {
		return TabContent.path_to_uri ((!) get_html_file ().get_path ());
	}

	public static string get_windows_uri () {
		Font font = BirdFont.get_current_font ();
		string html = get_html_file_name ();
		File dir = font.get_folder ();
		File file = get_child (dir, html);
		return "file:///" + (!)	file.get_path ();
	}

	public static string get_html_with_absolute_paths () {
		// hack: force webkit to ignore cache in preview
		StringBuilder sb = new StringBuilder ();
		DataInputStream dis;
		string? line;

		uint rid = Random.next_int ();
		Font font = BirdFont.get_current_font ();

		File preview_directory;
		File f_ttf;
		File f_eot;
		File f_svg;

		try {
			dis = new DataInputStream (get_file ().read ());

			string? d = font.get_export_directory ();
			
			if (d == null) {
				warning ("Export dir is not set.");
				ExportTool.set_output_directory ();
				d = font.get_export_directory ();
			}
			
			preview_directory = File.new_for_path ((!) d);
			
			printd (@"previwdir $((!) d)");
			
			if (ExportTool.get_export_dir () == null) {
				ExportTool.set_output_directory ();
			}

			File dir = File.new_for_path ((!) d);
			f_ttf = get_child (dir, @"$(ExportSettings.get_file_name (font)).ttf");
			f_eot = get_child (dir, @"$(ExportSettings.get_file_name (font)).eot");
			f_svg = get_child (dir, @"$(ExportSettings.get_file_name (font)).svg");

			if (!f_ttf.query_exists ()) {
				warning ("TTF file does not exist.");
			}

			if (!f_svg.query_exists ()) {
				warning ("SVG file does not exist.");
			}

			string name = ExportSettings.get_file_name (font);
			
			while ((line = dis.read_line (null)) != null) {
				line = ((!) line).replace (@"$name.ttf", @"$(TabContent.path_to_uri ((!) f_ttf.get_path ()))?$rid");
				line = ((!) line).replace (@"$name.eot", @"$(TabContent.path_to_uri ((!) f_eot.get_path ()))?$rid");
				line = ((!) line).replace (@"$name.svg", @"$(TabContent.path_to_uri ((!) f_svg.get_path ()))?$rid");
				sb.append ((!) line);
			}

		} catch (Error e) {
			warning (e.message);
			warning ("Failed to load html into canvas.");
		}
		
		return sb.str;
	}

	public override bool needs_modifier () {
		return true;
	}

}
}
