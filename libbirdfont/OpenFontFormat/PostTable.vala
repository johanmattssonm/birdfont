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

public class PostTable : Table {
	
	GlyfTable glyf_table;
	
	List<uint16> index = new List<uint16> ();
	List<string> names = new List<string> ();

	List<string> available_names = new List<string> ();
	
	public PostTable (GlyfTable g) {
		id = "post";
		glyf_table = g;
	}
		
	public int get_gid (string name) { // FIXME: do fast lookup
		int i = 0;
		int j = 0;
		foreach (string n in names) {
			if (n == name) {				
				j = 0;
				foreach (uint16 k in index) {
					if (k == i) {
						return j;
					}
					j++;
				}
								
				return i;
			}
			i++;
		}
		return -1;
	}

	public string get_name (int gid) {
		int k;
		
		if (!(0 <= gid < index.length ())) {
			warning ("gid is out of range.");
			return "";
		}
				
		k = (!) index.nth (gid).data;
		
		if (gid != 0 && k == 0) {
			warning (@"Glyph $gid is assigned to name .notdef, only gid 0 can be .notdef character.");
			return "";
		}
		
		if (!(0 <= k < names.length ())) {
			warning ("k is out of range.");
			return "";
		}
				
		return (!) names.nth (k).data;
	}
	
	public override void parse (FontData dis) throws Error {
		dis.seek (offset);
		
		Fixed format = dis.read_fixed ();
		Fixed italic = dis.read_fixed ();
		
		int16 underlie_pos = dis.read_short ();
		int16 underlie_thickness = dis.read_short ();
		uint32 is_fixed_pitch  = dis.read_ulong ();
		
		uint32 mem_min42  = dis.read_ulong ();
		uint32 mem_max42  = dis.read_ulong ();
		uint32 mem_min1  = dis.read_ulong ();
		uint32 mem_max1  = dis.read_ulong ();
		
		uint16 nnames  = dis.read_ushort ();
		
		if (format != 0x00020000) {
			warning ("Only post tables of version 2 will parset got $(format.get_string ())");
			return;
		}
		
		printd (@"format: $(format.get_string ())\n");
		printd (@"italic: $(italic.get_string ())\n");
		printd (@"underlie_pos: $(underlie_pos)\n");
		printd (@"underlie_thickness: $(underlie_thickness)\n");
		printd (@"is_fixed_pitch: $(is_fixed_pitch)\n");
		printd (@"mem_min42: $(mem_min42)\n");
		printd (@"mem_max42: $(mem_max42)\n");
		printd (@"mem_min1: $(mem_min1)\n");
		printd (@"mem_max1: $(mem_max1)\n");
		printd (@"\n");
		
		printd (@"Num names: $(nnames)\n");
		
		uint16 k;
		int non_standard_names = 0;
		for (uint16 i = 0; i < nnames; i++) {
			k = dis.read_ushort ();
			index.append (k);
			
			if (k >= 258) {
				non_standard_names++;
			}
		}
		
		add_standard_names ();
		
		// read non standard names
		for (int i = 0; i < non_standard_names; i++) {
			uint8 len = dis.read_byte ();
			StringBuilder name = new StringBuilder ();
			
			for (int j = 0; j < len; j++) {
				name.append_c (dis.read_char ());
			}

			names.append (name.str);
		}

		populate_available ();
	}

	void populate_available () {
		for (int i = 0; i < index.length (); i++) {
			available_names.append (get_name (i));
		}
	}
	
	// the Macintosh standard order
	private void add_standard_names () {
		names.append (".notdef");
		names.append (".null");
		names.append ("nonmarkingreturn");
		names.append ("space");
		names.append ("exclam");
		names.append ("quotedbl");
		names.append ("numbersign");
		names.append ("dollar");
		names.append ("percent");
		names.append ("ampersand");
		names.append ("quotesingle");
		names.append ("parenleft");
		names.append ("parenright");
		names.append ("asterisk");
		names.append ("plus");
		names.append ("comma");
		names.append ("hyphen");
		names.append ("period");
		names.append ("slash");
		names.append ("zero");
		names.append ("one");
		names.append ("two");
		names.append ("three");
		names.append ("four");
		names.append ("five");
		names.append ("six");
		names.append ("seven");
		names.append ("eight");
		names.append ("nine");
		names.append ("colon");
		names.append ("semicolon");
		names.append ("less");
		names.append ("equal");
		names.append ("greater");
		names.append ("question");
		names.append ("at");
		names.append ("A");
		names.append ("B");
		names.append ("C");
		names.append ("D");
		names.append ("E");
		names.append ("F");
		names.append ("G");
		names.append ("H");
		names.append ("I");
		names.append ("J");
		names.append ("K");
		names.append ("L");
		names.append ("M");
		names.append ("N");
		names.append ("O");
		names.append ("P");
		names.append ("Q");
		names.append ("R");
		names.append ("S");
		names.append ("T");
		names.append ("U");
		names.append ("V");
		names.append ("W");
		names.append ("X");
		names.append ("Y");
		names.append ("Z");
		names.append ("bracketleft");
		names.append ("backslash");
		names.append ("bracketright");
		names.append ("asciicircum");
		names.append ("underscore");
		names.append ("grave");
		names.append ("a");
		names.append ("b");
		names.append ("c");
		names.append ("d");
		names.append ("e");
		names.append ("f");
		names.append ("g");
		names.append ("h");
		names.append ("i");
		names.append ("j");
		names.append ("k");
		names.append ("l");
		names.append ("m");
		names.append ("n");
		names.append ("o");
		names.append ("p");
		names.append ("q");
		names.append ("r");
		names.append ("s");
		names.append ("t");
		names.append ("u");
		names.append ("v");
		names.append ("w");
		names.append ("x");
		names.append ("y");
		names.append ("z");
		names.append ("braceleft");
		names.append ("bar");
		names.append ("braceright");
		names.append ("asciitilde");
		names.append ("Adieresis");
		names.append ("Aring");
		names.append ("Ccedilla");
		names.append ("Eacute");
		names.append ("Ntilde");
		names.append ("Odieresis");
		names.append ("Udieresis");
		names.append ("aacute");
		names.append ("agrave");
		names.append ("acircumflex");
		names.append ("adieresis");
		names.append ("atilde");
		names.append ("aring");
		names.append ("ccedilla");
		names.append ("eacute");
		names.append ("egrave");
		names.append ("ecircumflex");
		names.append ("edieresis");
		names.append ("iacute");
		names.append ("igrave");
		names.append ("icircumflex");
		names.append ("idieresis");
		names.append ("ntilde");
		names.append ("oacute");
		names.append ("ograve");
		names.append ("ocircumflex");
		names.append ("odieresis");
		names.append ("otilde");
		names.append ("uacute");
		names.append ("ugrave");
		names.append ("ucircumflex");
		names.append ("udieresis");
		names.append ("dagger");
		names.append ("degree");
		names.append ("cent");
		names.append ("sterling");
		names.append ("section");
		names.append ("bullet");
		names.append ("paragraph");
		names.append ("germandbls");
		names.append ("registered");
		names.append ("copyright");
		names.append ("trademark");
		names.append ("acute");
		names.append ("dieresis");
		names.append ("notequal");
		names.append ("AE");
		names.append ("Oslash");
		names.append ("infinity");
		names.append ("plusminus");
		names.append ("lessequal");
		names.append ("greaterequal");
		names.append ("yen");
		names.append ("mu");
		names.append ("partialdiff");
		names.append ("summation");
		names.append ("product");
		names.append ("pi");
		names.append ("integral");
		names.append ("ordfeminine");
		names.append ("ordmasculine");
		names.append ("Omega");
		names.append ("ae");
		names.append ("oslash");
		names.append ("questiondown");
		names.append ("exclamdown");
		names.append ("logicalnot");
		names.append ("radical");
		names.append ("florin");
		names.append ("approxequal");
		names.append ("Delta");
		names.append ("guillemotleft");
		names.append ("guillemotright");
		names.append ("ellipsis");
		names.append ("nonbreakingspace");
		names.append ("Agrave");
		names.append ("Atilde");
		names.append ("Otilde");
		names.append ("OE");
		names.append ("oe");
		names.append ("endash");
		names.append ("emdash");
		names.append ("quotedblleft");
		names.append ("quotedblright");
		names.append ("quoteleft");
		names.append ("quoteright");
		names.append ("divide");
		names.append ("lozenge");
		names.append ("ydieresis");
		names.append ("Ydieresis");
		names.append ("fraction");
		names.append ("currency");
		names.append ("guilsinglleft");
		names.append ("guilsinglright");
		names.append ("fi");
		names.append ("fl");
		names.append ("daggerdbl");
		names.append ("periodcentered");
		names.append ("quotesinglbase");
		names.append ("quotedblbase");
		names.append ("perthousand");
		names.append ("Acircumflex");
		names.append ("Ecircumflex");
		names.append ("Aacute");
		names.append ("Edieresis");
		names.append ("Egrave");
		names.append ("Iacute");
		names.append ("Icircumflex");
		names.append ("Idieresis");
		names.append ("Igrave");
		names.append ("Oacute");
		names.append ("Ocircumflex");
		names.append ("apple");
		names.append ("Ograve");
		names.append ("Uacute");
		names.append ("Ucircumflex");
		names.append ("Ugrave");
		names.append ("dotlessi");
		names.append ("circumflex");
		names.append ("tilde");
		names.append ("macron");
		names.append ("breve");
		names.append ("dotaccent");
		names.append ("ring");
		names.append ("cedilla");
		names.append ("hungarumlaut");
		names.append ("ogonek");
		names.append ("caron");
		names.append ("Lslash");
		names.append ("lslash");
		names.append ("Scaron");
		names.append ("scaron");
		names.append ("Zcaron");
		names.append ("zcaron");
		names.append ("brokenbar");
		names.append ("Eth");
		names.append ("eth");
		names.append ("Yacute");
		names.append ("yacute");
		names.append ("Thorn");
		names.append ("thorn");
		names.append ("minus");
		names.append ("multiply");
		names.append ("onesuperior");
		names.append ("twosuperior");
		names.append ("threesuperior");
		names.append ("onehalf");
		names.append ("onequarter");
		names.append ("threequarters");
		names.append ("franc");
		names.append ("Gbreve");
		names.append ("gbreve");
		names.append ("Idotaccent");
		names.append ("Scedilla");
		names.append ("scedilla");
		names.append ("Cacute");
		names.append ("cacute");
		names.append ("Ccaron");
		names.append ("ccaron");
		names.append ("dcroat");
	}
	
	// mapping with char code to standard order
	int get_standard_index (unichar c) {
		switch (c) {
			// entry 0 is the .notdef
			
			case '\0':
				return 1;

			case '\r':
				return 2;

			case ' ': // space
				return 3;

			case '!':
				return 4;

			case '"':
				return 5;

			case '#':
				return 6;

			case '$':
				return 7;

			case '%':
				return 8;

			case '&':
				return 9;

			case '\'':
				return 10;

			case '(':
				return 11;

			case ')':
				return 12;

			case '*':
				return 13;

			case '+':
				return 14;

			case ',':
				return 15;

			case '-':
				return 16;

			case '.':
				return 17;

			case '/':
				return 18;

			case '0':
				return 19;

			case '1':
				return 20;

			case '2':
				return 21;

			case '3':
				return 22;

			case '4':
				return 23;

			case '5':
				return 24;

			case '6':
				return 25;

			case '7':
				return 26;

			case '8':
				return 27;

			case '9':
				return 28;

			case ':':
				return 29;

			case ';':
				return 30;

			case '<':
				return 31;

			case '=':
				return 32;

			case '>':
				return 33;

			case '?':
				return 34;

			case '@':
				return 35;

			case 'A':
				return 36;

			case 'B':
				return 37;

			case 'C':
				return 38;

			case 'D':
				return 39;

			case 'E':
				return 40;

			case 'F':
				return 41;

			case 'G':
				return 42;

			case 'H':
				return 43;

			case 'I':
				return 44;

			case 'J':
				return 45;

			case 'K':
				return 46;

			case 'L':
				return 47;

			case 'M':
				return 48;

			case 'N':
				return 49;

			case 'O':
				return 50;

			case 'P':
				return 51;

			case 'Q':
				return 52;

			case 'R':
				return 53;

			case 'S':
				return 54;

			case 'T':
				return 55;

			case 'U':
				return 56;

			case 'V':
				return 57;

			case 'W':
				return 58;

			case 'X':
				return 59;

			case 'Y':
				return 60;

			case 'Z':
				return 61;

			case '[':
				return 62;

			case '\\':
				return 63;

			case ']':
				return 64;

			case '^':
				return 65;

			case '_':
				return 66;

			case '`':
				return 67;

			case 'a':
				return 68;

			case 'b':
				return 69;

			case 'c':
				return 70;

			case 'd':
				return 71;

			case 'e':
				return 72;

			case 'f':
				return 73;

			case 'g':
				return 74;

			case 'h':
				return 75;

			case 'i':
				return 76;

			case 'j':
				return 77;

			case 'k':
				return 78;

			case 'l':
				return 79;

			case 'm':
				return 80;

			case 'n':
				return 81;

			case 'o':
				return 82;

			case 'p':
				return 83;

			case 'q':
				return 84;

			case 'r':
				return 85;

			case 's':
				return 86;

			case 't':
				return 87;

			case 'u':
				return 88;

			case 'v':
				return 89;

			case 'w':
				return 90;

			case 'x':
				return 91;

			case 'y':
				return 92;

			case 'z':
				return 93;

			case '{':
				return 94;

			case '|':
				return 95;

			case '}':
				return 96;

			case '~':
				return 97;

			case 'Ä':
				return 98;

			case 'Å':
				return 99;

			case 'Ç':
				return 100;

			case 'É':
				return 101;

			case 'Ñ':
				return 102;

			case 'Ö':
				return 103;

			case 'Ü':
				return 104;

			case 'á':
				return 105;

			case 'à':
				return 106;

			case 'â':
				return 107;

			case 'ä':
				return 108;

			case 'ã':
				return 109;

			case 'å':
				return 110;

			case 'ç':
				return 111;

			case 'é':
				return 112;

			case 'è':
				return 113;

			case 'ê':
				return 114;

			case 'ë':
				return 115;

			case 'í':
				return 116;

			case 'ì':
				return 117;

			case 'î':
				return 118;

			case 'ï':
				return 119;

			case 'ñ':
				return 120;

			case 'ó':
				return 121;

			case 'ò':
				return 122;

			case 'ô':
				return 123;

			case 'ö':
				return 124;

			case 'õ':
				return 125;

			case 'ú':
				return 126;

			case 'ù':
				return 127;

			case 'û':
				return 128;

			case 'ü':
				return 129;

			case '†':
				return 130;

			case '°':
				return 131;

			case '¢':
				return 132;

			case '£':
				return 133;

			case '§':
				return 134;

			case '•':
				return 135;

			case '¶':
				return 136;

			case 'ß':
				return 137;

			case '®':
				return 138;

			case '©':
				return 139;

			case '™':
				return 140;

			case '´':
				return 141;

			case '¨':
				return 142;

			case '≠':
				return 143;

			case 'Æ':
				return 144;

			case 'Ø':
				return 145;

			case '∞':
				return 146;

			case '±':
				return 147;

			case '≤':
				return 148;

			case '≥':
				return 149;

			case '¥':
				return 150;

			case 'µ':
				return 151;

			case '∂':
				return 152;

			case '∑':
				return 153;

			case '∏':
				return 154;

			case 'π':
				return 155;

			case '∫':
				return 156;

			case 'ª':
				return 157;

			case 'º':
				return 158;

			case 'Ω':
				return 159;

			case 'æ':
				return 160;

			case 'ø':
				return 161;

			case '¿':
				return 162;

			case '¡':
				return 163;

			case '¬':
				return 164;

			case '√':
				return 165;

			case 'ƒ':
				return 166;

			case '≈':
				return 167;

			case '∆':
				return 168;

			case '«':
				return 169;

			case '»':
				return 170;

			case '…':
				return 171;

			case ' ': // non breaking space
				return 172;
							
			case 'À':
				return 173;

			case 'Ã':
				return 174;

			case 'Õ':
				return 175;

			case 'Œ':
				return 176;

			case 'œ':
				return 177;

			case '–':
				return 178;

			case '—':
				return 179;

			case '“':
				return 180;

			case '”':
				return 181;

			case '‘':
				return 182;

			case '’':
				return 183;

			case '÷':
				return 184;

			case '◊':
				return 185;

			case 'ÿ':
				return 186;

			case 'Ÿ':
				return 187;

			case '⁄':
				return 188;

			case '¤':
				return 189;

			case '‹':
				return 190;

			case '›':
				return 191;

			case 'ﬁ':
				return 192;

			case 'ﬂ':
				return 193;

			case '‡':
				return 194;

			case '·':
				return 195;

			case '‚':
				return 196;

			case '„':
				return 197;

			case '‰':
				return 198;

			case 'Â':
				return 199;

			case 'Ê':
				return 200;

			case 'Á':
				return 201;

			case 'Ë':
				return 202;

			case 'È':
				return 203;

			case 'Í':
				return 204;

			case 'Î':
				return 205;

			case 'Ï':
				return 206;

			case 'Ì':
				return 207;

			case 'Ó':
				return 208;

			case 'Ô':
				return 209;
				
			// Machintosh apple goes here
			// return 210;

			case 'Ò':
				return 211;

			case 'Ú':
				return 212;

			case 'Û':
				return 213;

			case 'Ù':
				return 214;

			case 'ı':
				return 215;

			case 'ˆ':
				return 216;

			case '˜':
				return 217;

			case '¯':
				return 218;

			case '˘':
				return 219;

			case '˙':
				return 220;

			case '˚':
				return 221;

			case '¸':
				return 222;

			case '˝':
				return 223;

			case '˛':
				return 224;

			case 'ˇ':
				return 225;

			case 'Ł':
				return 226;

			case 'ł':
				return 227;

			case 'Š':
				return 228;

			case 'š':
				return 229;

			case 'Ž':
				return 230;

			case 'ž':
				return 231;

			case '¦':
				return 232;

			case 'Ð':
				return 233;

			case 'ð':
				return 234;

			case 'Ý':
				return 235;

			case 'ý':
				return 236;

			case 'Þ':
				return 237;

			case 'þ':
				return 238;

			case '−':
				return 239;

			case '×':
				return 240;

			case '¹':
				return 241;
				
			case '²':
				return 242;

			case '³':
				return 243;

			case '½':
				return 244;

			case '¼':
				return 245;

			case '¾':
				return 246;

			case '₣':
				return 247;

			case 'Ğ':
				return 248;

			case 'ğ':
				return 249;

			case 'İ':
				return 250;

			case 'Ş':
				return 251;

			case 'ş':
				return 252;

			case 'Ć':
				return 253;

			case 'ć':
				return 254;

			case 'Č':
				return 255;

			case 'č':
				return 256;

			case 'đ':
				return 257;
		}
		
		return 0;
	}
	
	public void process () throws Error {
		FontData fd = new FontData ();
		string n;
		
		fd.add_fixed (0x00020000); // Version
		fd.add_fixed (0x00000000); // italicAngle
		
		fd.add_short (-2); // underlinePosition
		fd.add_short (1); // underlineThickness

		fd.add_ulong (0); // non zero for monospaced font
		
		// mem boundries may be omitted
		fd.add_ulong (0); // min mem for type 42
		fd.add_ulong (0); // max mem for type 42
		
		fd.add_ulong (0); // min mem for Type1
		fd.add_ulong (0); // max mem for Type1

		fd.add_ushort ((uint16) glyf_table.glyphs.length ());

		// this part of the spec is so weird
		
		fd.add_ushort ((uint16) 0); // first index is .notdef
		index.append (0);
		
		assert (names.length () == 0);
		add_standard_names ();

		int index;
		Glyph g;
		for (int i = 1; i < glyf_table.glyphs.length (); i++) {
			g = (!) glyf_table.glyphs.nth (i).data;
			index = get_standard_index (g.unichar_code);
			
			if (index != 0) {
				fd.add_ushort ((uint16) index);  // use standard name
			} else {
				printd (@"Adding non standard postscript name $(g.get_name ())\n");
				
				index = (int) names.length (); // use font specific name
				fd.add_ushort ((uint16) index);
				names.append (g.get_name ());
			}
			
			this.index.append ((uint16) index);
		}

		for (int i = 258; i < names.length (); i++) {
			n = (!) names.nth (i).data;
			
			if (n.length > 0xFF) {
				warning (@"too long name for glyph $n");
			}
						
			fd.add ((uint8) n.length); // length of string
			fd.add_str (n);
		}		

		fd.pad ();
		
		this.font_data = fd;
	}

}

}
