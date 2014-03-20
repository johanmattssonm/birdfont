/*
    Copyright (C) 2012, 2013 Johan Mattsson

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

public class Os2Table : Table {
	
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
	
	public Os2Table () {
		id = "OS/2";
	}
	
	public override void parse (FontData dis) throws Error {
	}
	
	public void process (GlyfTable glyf_table) {
		FontData fd = new FontData ();
		Font font = OpenFontFormatWriter.get_current_font ();
		int16 ascender;
		int16 descender;
		uint16 style = 0;
		
		fd.add_u16 (0x0002); // version

		fd.add_16 (glyf_table.get_average_width ()); // xAvgCharWidth
		
		fd.add_u16 ((uint16) font.weight); // usWeightClass (400 is normal, 700 is bold)
		
		fd.add_u16 (5); // usWidthClass (5 is normal)
		fd.add_u16 (0); // fsType

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

		// FIXME:
		fd.add_u32 (0); // ulUnicodeRange1 Bits 0-31
		fd.add_u32 (0); // ulUnicodeRange2 Bits 32-63
		fd.add_u32 (0); // ulUnicodeRange3 Bits 64-95
		fd.add_u32 (0); // ulUnicodeRange4 Bits 96-127

		fd.add_tag ("Vend"); // VendID
		
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

		ascender = glyf_table.ymax;
		descender = glyf_table.ymin;
		
		fd.add_16 (ascender); // sTypoAscender
		fd.add_16 (descender); // sTypoDescender
		fd.add_16 (10); // sTypoLineGap

		fd.add_u16 (ascender); // usWinAscent
		
		if (descender > 0) {
			warning (@"usWinDescent is unsigned, can not write $(-descender) to the field.");
			fd.add_u16 (0);
		} else {
			fd.add_u16 (-descender); // usWinDescent (not like sTypoDescender)
		}
		
		// FIXME:
		fd.add_u32 (0); // ulCodePageRange1 Bits 0-31
		fd.add_u32 (0); // ulCodePageRange2 Bits 32-63

		fd.add_16 (ascender); // sHeight
		fd.add_16 (ascender); // sCapHeight

		fd.add_16 (0); // usDefaultChar
		fd.add_16 (0x0020); // usBreakChar also known as space
		
		fd.add_16 (2); // usMaxContext (two becase it has kernings but not ligatures).

		// padding
		fd.pad ();
	
		this.font_data = fd;
	}

}

}
