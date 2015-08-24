/*
    Copyright (C) 2012 2013 2014 Johan Mattsson

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

/** Table with list of tables sorted by table tag. */
public class DirectoryTable : OtfTable {
	
	public CmapTable cmap_table;
	public CvtTable  cvt_table;
	public GaspTable gasp_table;
	public GdefTable gdef_table;
	public GlyfTable glyf_table;
	public GposTable gpos_table;
	public GsubTable gsub_table;
	public HeadTable head_table;
	public HheaTable hhea_table;
	public HmtxTable hmtx_table;
	public KernTable kern_table;
	public MaxpTable maxp_table;
	public NameTable name_table;
	public Os2Table  os_2_table;
	public PostTable post_table;
	public LocaTable loca_table;
	
	public OffsetTable offset_table;
	
	Gee.ArrayList<OtfTable> tables;
	
	public DirectoryTable () {
		offset_table = new OffsetTable (this);
		
		loca_table = new LocaTable ();
		gasp_table = new GaspTable ();
		gdef_table = new GdefTable ();
		glyf_table = new GlyfTable (loca_table);
		gsub_table = new GsubTable (glyf_table);
		cmap_table = new CmapTable (glyf_table);
		cvt_table  = new CvtTable ();
		head_table = new HeadTable (glyf_table);
		hmtx_table = new HmtxTable (head_table, glyf_table);
		hhea_table = new HheaTable (glyf_table, head_table, hmtx_table);
		kern_table = new KernTable (glyf_table);
		gpos_table = new GposTable ();
		maxp_table = new MaxpTable (glyf_table);
		name_table = new NameTable ();
		os_2_table = new Os2Table (); 
		post_table = new PostTable (glyf_table);
		
		id = "Directory table";
		
		tables = new Gee.ArrayList<OtfTable> ();
	}

	public void process () throws GLib.Error {
		// generate font data
		glyf_table.process ();
		gsub_table.process ();
		gasp_table.process ();
		gdef_table.process ();
		cmap_table.process (glyf_table);
		cvt_table.process ();
		hmtx_table.process ();
		hhea_table.process ();
		maxp_table.process ();
		name_table.process ();
		os_2_table.process (glyf_table, hmtx_table);
		head_table.process ();
		loca_table.process (glyf_table, head_table);
		post_table.process ();
		kern_table.process ();
		gpos_table.process (glyf_table);
		
		offset_table.process ();
		process_directory (); // this table
	}

	public void process_mac ()  throws GLib.Error {
		os_2_table.process_mac (glyf_table, hmtx_table);
		offset_table.process ();
		process_directory (); // this table
	}

	public Gee.ArrayList<OtfTable> get_tables () {
		if (tables.size == 0) {
			tables.add (offset_table);
			tables.add (this);
			
			tables.add (gpos_table);
			tables.add (gsub_table);
			
			tables.add (os_2_table);

			// tables.append (gdef_table); // invalid table
			
			tables.add (cmap_table);
			// tables.append (cvt_table);
			tables.add (gasp_table);
			tables.add (glyf_table);
			tables.add (head_table);
			
			tables.add (hhea_table);
			tables.add (hmtx_table);

			// It looks like the old kerning table is no longer needed
			// since the most browsers uses the GPOS table
			// but Windows does not accept fonts without a kern table.
			
			tables.add (kern_table);
							
			tables.add (loca_table);
			tables.add (maxp_table);
			tables.add (name_table);
			
			tables.add (post_table);
		}

		return tables;
	}

	public void set_offset_table (OffsetTable ot) {
		offset_table = ot;
	}
	
	public new void parse (FontData dis, OpenFontFormatReader reader_callback) throws Error {
		StringBuilder tag = new StringBuilder ();
		uint32 checksum;
		uint32 offset;
		uint32 length;
		
		return_if_fail (offset_table.num_tables > 0);
		
		for (uint i = 0; i < offset_table.num_tables; i++) {
			tag.erase ();
			
			tag.append_unichar ((unichar) dis.read_byte ());
			tag.append_unichar ((unichar) dis.read_byte ());
			tag.append_unichar ((unichar) dis.read_byte ());
			tag.append_unichar ((unichar) dis.read_byte ());
			
			checksum = dis.read_ulong ();
			offset = dis.read_ulong ();
			length = dis.read_ulong ();
			
			printd (@"$(tag.str) \toffset: $offset \tlength: $length \tchecksum: $checksum.\n");
			
			if (tag.str == "cvt") {
				cvt_table.id = tag.str;
				cvt_table.checksum = checksum;
				cvt_table.offset = offset;
				cvt_table.length = length;
			} else if (tag.str == "hmtx") {
				hmtx_table.id = tag.str;
				hmtx_table.checksum = checksum;
				hmtx_table.offset = offset;
				hmtx_table.length = length;
			} else if (tag.str == "hhea") {
				hhea_table.id = tag.str;
				hhea_table.checksum = checksum;
				hhea_table.offset = offset;
				hhea_table.length = length;	
			} else if (tag.str == "loca") {
				loca_table.id = tag.str;
				loca_table.checksum = checksum;
				loca_table.offset = offset;
				loca_table.length = length;	
			} else if (tag.str == "cmap") {
				cmap_table.id = tag.str;
				cmap_table.checksum = checksum;
				cmap_table.offset = offset;
				cmap_table.length = length;
			} else if (tag.str == "maxp") {
				maxp_table.id = tag.str;
				maxp_table.checksum = checksum;
				maxp_table.offset = offset;
				maxp_table.length = length;
			} else if (tag.str == "gasp") {
				gasp_table.id = tag.str;
				gasp_table.checksum = checksum;
				gasp_table.offset = offset;
				gasp_table.length = length;
			} else if (tag.str == "gdef") {
				gdef_table.id = tag.str;
				gdef_table.checksum = checksum;
				gdef_table.offset = offset;
				gdef_table.length = length;
			} else if (tag.str == "glyf") {
				glyf_table.id = tag.str;
				glyf_table.checksum = checksum;
				glyf_table.offset = offset;
				glyf_table.length = length;
			} else if (tag.str == "head") {
				head_table.id = tag.str;
				head_table.checksum = checksum;
				head_table.offset = offset;
				head_table.length = length;
			} else if (tag.str == "name") {
				name_table.id = tag.str;
				name_table.checksum = checksum;
				name_table.offset = offset;
				name_table.length = length;
			} else if (tag.str == "OS/2") {
				os_2_table.id = tag.str;
				os_2_table.checksum = checksum;
				os_2_table.offset = offset;
				os_2_table.length = length;
			} else if (tag.str == "post") {
				post_table.id = tag.str;
				post_table.checksum = checksum;
				post_table.offset = offset;
				post_table.length = length;
			} else if (tag.str == "kern") {
				kern_table.id = tag.str;
				kern_table.checksum = checksum;
				kern_table.offset = offset;
				kern_table.length = length;
			} else if (tag.str == "GPOS") {
				gpos_table.id = tag.str;
				gpos_table.checksum = checksum;
				gpos_table.offset = offset;
				gpos_table.length = length;
			}
		}
	}
	
	public void parse_all_tables (FontData dis, OpenFontFormatReader reader_callback) throws Error {
		head_table.parse (dis);
		
		hhea_table.parse (dis);
		reader_callback.set_limits ();
		
		name_table.parse (dis);
		post_table.parse (dis);
		os_2_table.parse (dis);
		maxp_table.parse (dis);
		loca_table.parse (dis, head_table, maxp_table);
		hmtx_table.parse (dis, hhea_table, loca_table);
		cmap_table.parse (dis);
		gpos_table.parse (dis);
		
		if (kern_table.has_data ()) {
			kern_table.parse (dis);
		}
		
		glyf_table.parse (dis, cmap_table, loca_table, hmtx_table, head_table, post_table, kern_table);
		
		if (kern_table.has_data ()) {
			gasp_table.parse (dis);
		}
		
		if (kern_table.has_data ()) {
			cvt_table.parse (dis);
		}
	}
	
	public void parse_kern_table (FontData dis) throws Error {
		if (kern_table.has_data ()) {
			kern_table.parse (dis);
		} else {
			warning ("Kern table is empty.");
		}
	}

	public void parse_cmap_table (FontData dis) throws Error {
		if (cmap_table.has_data ()) {
			cmap_table.parse (dis);
		} else {
			warning ("Cmap table is empty.");
		}
	}

	public void parse_head_table (FontData dis) throws Error {
		if (head_table.has_data ()) {
			head_table.parse (dis);
		} else {
			warning ("Head table is empty.");
		}
	}
		
	public bool validate_tables (FontData dis, File file) {
		bool valid = true;
		
		try {
			dis.seek (0);
			
			if (!validate_checksum_for_entire_font (dis, file)) {
				warning ("file has invalid checksum");
			} else {
				printd ("Font file has valid checksum.\n");
			}

			// Skip validation of head table for now it should be simple but it seems to
			// be broken in some funny way.

			if (!glyf_table.validate (dis)) {
				warning ("glyf_table has invalid checksum");
				valid = false;
			}
			
			if (!maxp_table.validate (dis)) {
				warning ("maxp_table has is invalid checksum");
				valid = false;
			}
			
			if (!loca_table.validate (dis)) {
				warning ("loca_table has invalid checksum");
				valid = false;
			}
			
			if (!cmap_table.validate (dis)) {
				warning ("cmap_table has invalid checksum");
				valid = false;
			}
			
			if (!hhea_table.validate (dis)) {
				warning ("hhea_table has invalid checksum");
				valid = false;
			}
			
			if (!hmtx_table.validate (dis)) {
				warning ("hmtx_table has invalid checksum");
				valid = false;
			}

			if (!name_table.validate (dis)) {
				warning ("name_table has invalid checksum");
				valid = false;
			}

			if (!os_2_table.validate (dis)) {
				warning ("os_2_table has invalid checksum");
				valid = false;
			}

			if (!post_table.validate (dis)) {
				warning ("post_table has invalid checksum");
				valid = false;
			}
			
			if (kern_table.has_data () && !kern_table.validate (dis)) {
				warning ("kern_table has invalid checksum");
				valid = false;
			}
			
			if (!gpos_table.validate (dis)) {
				warning (@"gpos_table has invalid checksum");
				
				if (gpos_table.font_data != null) {
					warning (@"Length: $(((!)gpos_table.font_data).length ())\n");
				} else {
					warning ("font_data is null");
				}
				
				valid = false;
			}		
		} catch (GLib.Error e) {
			warning (e.message);
			valid = false;
		}
		
		return valid;
	}
	
	bool validate_checksum_for_entire_font (FontData dis, File f) throws GLib.Error {
		uint p = head_table.offset + head_table.get_checksum_position ();
		uint32 checksum_font, checksum_head;

		checksum_head = head_table.get_font_checksum ();
		
		dis.seek (0);
		
		// zero out checksum entry in head table before validating it
		dis.write_at (p + 0, 0);
		dis.write_at (p + 1, 0);
		dis.write_at (p + 2, 0);
		dis.write_at (p + 3, 0);
		
		checksum_font = (uint32) (0xB1B0AFBA - dis.checksum ());

		if (checksum_font != checksum_head) {
			warning (@"Fontfile checksum in head table does not match calculated checksum. checksum_font: $checksum_font checksum_head: $checksum_head");
			return false;
		}
		
		return true;
	}
	
	public long get_font_file_size () {
		long length = 0;
		
		foreach (OtfTable t in tables) {
			length += t.get_font_data ().length_with_padding ();
		}
		
		return length;
	}
	
	public void process_directory () throws GLib.Error {
		create_directory (); // create directory without offsets to calculate length of offset table and checksum for entre file
		create_directory (); // generate a valid directory
	}

	// Check sum adjustment for the entire font
	public uint32 get_font_file_checksum () {
		uint32 checksum = 0;
		foreach (OtfTable t in tables) {
			t.get_font_data ().continous_checksum (ref checksum);
		}
		return checksum;
	}

	public void create_directory () throws GLib.Error {
		FontData fd;
	
		uint32 table_offset = 0;
		uint32 table_length = 0;
		
		uint32 checksum = 0;
		
		fd = new FontData ();

		return_if_fail (offset_table.num_tables > 0);
		
		table_offset += offset_table.get_font_data ().length_with_padding ();
		
		if (this.font_data != null) {
			table_offset += this.get_font_data ().length_with_padding ();
		}

		head_table.set_checksum_adjustment (0); // Set this to zero, calculate checksums and update the value
		head_table.process ();
		
		// write the directory 
		foreach (OtfTable t in tables) {
						
			if (t is DirectoryTable || t is OffsetTable) {
				continue;
			}
			
			printd (@"c $(t.id)  offset: $(table_offset)  len with pad  $(t.get_font_data ().length_with_padding ())\n");

			table_length = t.get_font_data ().length (); // without padding
			
			fd.add_tag (t.get_id ()); // name of table
			fd.add_u32 (t.get_font_data ().checksum ());
			fd.add_u32 (table_offset);
			fd.add_u32 (table_length);
			
			table_offset += t.get_font_data ().length_with_padding ();
		}

		// padding
		fd.pad ();
						
		this.font_data = fd;

		checksum = get_font_file_checksum ();
		head_table.set_checksum_adjustment ((uint32)(0xB1B0AFBA - checksum));
		head_table.process (); // update the value		
	}
	
}

}
