/*
	Copyright (C) 2012 2013 2014 2015 Johan Mattsson

	This library is free software; you can redistribute it and/or modify 
	it under the terms of the GNU Lesser General Public License as 
	published by the Free Software Foundation; either version 3 of the 
	License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful, but 
	WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
	Lesser General Public License for more details.
*/

using Math;

namespace BirdFont {

public class Os2Table : OtfTable {
	
	public static const uint16 ITALIC = 1;
	public static const uint16 UNDERSCORE = 1 << 1;
	public static const uint16 NEGATIVE  = 1 << 2;
	public static const uint16 OUTLINED  = 1 << 3;
	public static const uint16 STRIKEOUT  = 1 << 4;
	public static const uint16 BOLD  = 1 << 5;
	public static const uint16 REGULAR  = 1 << 6;
	public static const uint16 TYPO_METRICS  = 1 << 7;
	public static const uint16 WWS  = 1 << 8;
	public static const uint16 OBLIQUE = 1 << 9;
	
	GlyfTable glyf_table;
	HmtxTable hmtx_table;
	HheaTable hhea_table;
	
	public Os2Table (GlyfTable gt, HmtxTable hmtx, HheaTable hhea) {
		id = "OS/2";
		glyf_table = gt;
		hmtx_table = hmtx;
		hhea_table = hhea;
	}
			
	public override void parse (FontData dis) throws Error {
	}

	public void process () {
		process_table (false);
	}
	
	public void process_mac () {
		process_table (true);
	}
		
	public void process_table (bool mac) {
		FontData fd = new FontData ();
		Font font = OpenFontFormatWriter.get_current_font ();
		uint16 style = 0;
		UnicodeRangeBits ranges = new UnicodeRangeBits ();
		CodePageBits pages = new CodePageBits ();
		uint32 unicodeRange1, unicodeRange2, unicodeRange3, unicodeRange4;
		uint32 codepage1, codepage2;
		int16 win_descent;
		
		fd.add_u16 (0x0004); // version

		fd.add_16 (hmtx_table.get_average_width ()); // xAvgCharWidth
		
		fd.add_u16 ((uint16) font.weight); // usWeightClass (400 is normal, 700 is bold)
		
		fd.add_u16 (5); // usWidthClass (5 is normal)
		fd.add_u16 (0); // fsType

		//FIXME: 
		fd.add_16 (40); // ySubscriptXSize
		fd.add_16 (40); // ySubscriptYSize
		fd.add_16 (40); // ySubscriptXOffset
		fd.add_16 (40); // ySubscriptYOffset
		fd.add_16 (40); // ySuperscriptXSize
		fd.add_16 (40); // ySuperscriptYSize
		fd.add_16 (40); // ySuperscriptXOffset
		fd.add_16 (40); // ySuperscriptYOffset
		fd.add_16 (40); // yStrikeoutSize
		fd.add_16 (200); // yStrikeoutPosition
		fd.add_16 (0); // sFamilyClass

		// FIXME: PANOSE 
		// Panose, zero means anything will fit.
		fd.add (0); 
		fd.add (0); 
		fd.add (0); 
		fd.add (0); 
		fd.add (0); 
		fd.add (0); 
		fd.add (0); 
		fd.add (0); 
		fd.add (0); 
		fd.add (0); 

		ranges.get_ranges (font, out unicodeRange1, out unicodeRange2, out unicodeRange3, out unicodeRange4);

		if (mac) {
			fd.add_u32 (unicodeRange1); // ulUnicodeRange1 Bits 0-31
			fd.add_u32 (0); // ulUnicodeRange2 Bits 32-63
			fd.add_u32 (0); // ulUnicodeRange3 Bits 64-95
			fd.add_u32 (0); // ulUnicodeRange4 Bits 96-127
		} else {
			fd.add_u32 (unicodeRange1); // ulUnicodeRange1 Bits 0-31
			fd.add_u32 (unicodeRange2); // ulUnicodeRange2 Bits 32-63
			fd.add_u32 (unicodeRange3); // ulUnicodeRange3 Bits 64-95
			fd.add_u32 (unicodeRange4); // ulUnicodeRange4 Bits 96-127
		}
		
		fd.add_tag ("Bird"); // VendID
		
		 // fsSelection (1 for italic 0 for upright)

		if (!font.bold && !font.italic) {
			style |= REGULAR;
		}

		if (font.bold) {
			style |= BOLD;
		}
				
		if (font.italic) {
			style |= ITALIC;
		}
		
		fd.add_u16 (style);
		
		fd.add_u16 (glyf_table.get_first_char ()); // usFirstCharIndex
		fd.add_u16 (glyf_table.get_last_char ()); // usLastCharIndex

		int16 ascender = (int16) rint (font.top_limit * HeadTable.UNITS);
		int16 descender = (int16) rint (font.bottom_limit * HeadTable.UNITS);
	
		fd.add_16 (ascender); // sTypoAscender
		fd.add_16 (descender); // sTypoDescender
		fd.add_16 (100); // sTypoLineGap

		// usWinAscent
		fd.add_u16 (ascender); 
		
		// usWinDescent (not like sTypoDescender)
		win_descent = descender;
		if (win_descent > 0) {
			warning (@"usWinDescent is unsigned, can not write $(win_descent) to the field.");
			fd.add_u16 (0);
		} else {
			fd.add_u16 (-win_descent); 
		}
		
		pages.get_pages (font, out codepage1, out codepage2);
		
		if (mac) {
			fd.add_u32 (1); // ulCodePageRange1 Bits 0-31 (this value is only used fontbook) 
			fd.add_u32 (0); // ulCodePageRange2 Bits 32-63			
		} else {
			fd.add_u32 (codepage1); // ulCodePageRange1 Bits 0-31 (this value is used by Word on Windows)
			fd.add_u32 (codepage2); // ulCodePageRange2 Bits 32-63
		}

		int16 xheight = (int16) rint ((font.xheight_position - font.base_line) * HeadTable.UNITS);
		int16 cap_height = (int16) rint ((font.top_limit - font.base_line) * HeadTable.UNITS);
		
		fd.add_16 (xheight); // sxHeight
		fd.add_16 (cap_height); // sCapHeight

		fd.add_16 (0); // usDefaultChar
		fd.add_16 (0x0020); // usBreakChar, also known as space
		
		// usMaxContext
		int16 num_glyphs = 2; // FIXME: add one for each parts of ligatures
		fd.add_16 (num_glyphs); 

		// padding
		fd.pad ();
	
		this.font_data = fd;
	}
}

}
