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

class Os2Table : Table {
	
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
		
		fd.add_u16 (0x0002); // version

		fd.add_16 (glyf_table.get_average_width ()); // xAvgCharWidth

		// usWeightClass (400 is normal, 700 is bold)
		if (font.subfamily.index_of ("Bold") == -1) {
			fd.add_u16 (400); 
		} else {
			fd.add_u16 (700);
		} 
		
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
		fd.add_16 (40); // sFamilyClass

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

		fd.add_tag ("----"); // VendID
		
		 // fsSelection (1 for italic 0 for upright)
		if (font.subfamily.index_of ("Italic") == -1) {
			fd.add_u16 (0);
		} else {
			fd.add_u16 (1);
		}
		
		fd.add_u16 (glyf_table.get_first_char ()); // usFirstCharIndex
		fd.add_u16 (glyf_table.get_last_char ()); // usLastCharIndex

		ascender = glyf_table.ymax;
		descender = -glyf_table.ymin;
		
		fd.add_16 (ascender); // sTypoAscender
		fd.add_16 (descender); // sTypoDescender
		fd.add_16 (3); // sTypoLineGap

		fd.add_u16 (ascender); // usWinAscent
		fd.add_u16 (descender); // usWinDescent

		// FIXA:
		fd.add_u32 (0); // ulCodePageRange1 Bits 0-31
		fd.add_u32 (0); // ulCodePageRange2 Bits 32-63

		fd.add_16 (ascender); // sHeight
		fd.add_16 (ascender); // sCapHeight

		fd.add_16 (0); // usDefaultChar
		fd.add_16 (0x0020); // usBreakChar also known as space
		
		// FIXME: calculate these values
		fd.add_16 (1); // usMaxContext

		// padding
		fd.pad ();
	
		this.font_data = fd;
	}

}

}
