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
		
		fd.add_u16 (0x0002); // USHORT Version 0x0000, 0x0001, 0x0002, 0x0003, 0x0004

		fd.add_16 (glyf_table.get_average_width ()); // SHORT xAvgCharWidth

		fd.add_u16 (400); // USHORT usWeightClass (400 is normal)
		fd.add_u16 (5); // USHORT usWidthClass (5 is normal)
		fd.add_u16 (0); // USHORT fsType

		fd.add_16 (40); // SHORT ySubscriptXSize
		fd.add_16 (40); // SHORT ySubscriptYSize
		fd.add_16 (40); // SHORT ySubscriptXOffset
		fd.add_16 (40); // SHORT ySubscriptYOffset
		fd.add_16 (40); // SHORT ySuperscriptXSize
		fd.add_16 (40); // SHORT ySuperscriptYSize
		fd.add_16 (40); // SHORT ySuperscriptXOffset
		fd.add_16 (40); // SHORT ySuperscriptYOffset
		fd.add_16 (40); // SHORT yStrikeoutSize
		fd.add_16 (200); // SHORT yStrikeoutPosition
		fd.add_16 (40); // SHORT sFamilyClass

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
		fd.add_u32 (0); // ULONG ulUnicodeRange2 Bits 32-63
		fd.add_u32 (0); // ULONG ulUnicodeRange3 Bits 64-95
		fd.add_u32 (0); // ULONG ulUnicodeRange4 Bits 96-127

		fd.add_tag ("----"); // VendID

		fd.add_u16 (0); // USHORT fsSelection
		
		fd.add_u16 (glyf_table.get_first_char ()); // USHORT usFirstCharIndex
		fd.add_u16 (glyf_table.get_last_char ()); // USHORT usLastCharIndex

		ascender = (int16) (glyf_table.xmax + font.base_line * HeadTable.UNITS);
		descender = (int16) (-glyf_table.xmin  + font.base_line * HeadTable.UNITS);
		
		fd.add_16 (ascender); // SHORT sTypoAscender
		fd.add_16 (descender); // SHORT sTypoDescender
		fd.add_16 (3); // SHORT sTypoLineGap

		fd.add_u16 (ascender); // USHORT usWinAscent
		fd.add_u16 (descender); // USHORT usWinDescent

		// FIXA:
		fd.add_u32 (0); // ULONG ulCodePageRange1 Bits 0-31
		fd.add_u32 (0); // ULONG ulCodePageRange2 Bits 32-63

		fd.add_16 (ascender); // SHORT sxHeight version 0x0002 and later
		fd.add_16 (ascender); // SHORT sCapHeight version 0x0002 and later

		fd.add_16 (0); // USHORT usDefaultChar version 0x0002 and later
		fd.add_16 (0x0020); // USHORT usBreakChar version 0x0002 and later, also known as space
		
		// FIXA: calculate these values
		fd.add_16 (1); // USHORT usMaxContext version 0x0002 and later

		// padding
		fd.pad ();
	
		this.font_data = fd;
	}

}

}
