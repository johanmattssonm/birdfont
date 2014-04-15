/*
    Copyright (C) 2012, 2013, 2014 Johan Mattsson

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

/** All the things we want to test listed is here. */
class TestCases {
	
	public List<Test> test_cases;

	public TestCases () {
		add (test_overview, "Overview");
		add (test_data_reader, "Font data reader");
		add (test_argument, "Argument list");
		add (test_glyph_ranges, "Glyph ranges");
		add (test_hex, "Unicode hex values");
		add (test_reverse_path, "Reverse path");
		add (test_reverse_random_triangles, "Reverse random paths");
		add (test_coordinates, "Coordinates");
		add (test_drawing, "Pen tool");
		add (test_delete_points, "Delete edit points");
		add (test_convert_to_quadratic_bezier_path, "Convert to quadratic path");
		add (test_notdef, "Notdef");
		add (test_merge, "Merge");
		add (test_over_path, "Over path");
		add (test_export, "Export");
		add (test_background_coordinates, "Background coordinates");
		add (test_spin_button, "Spin button");
		add (test_inkscape_import, "Inkscape import");
		add (test_illustrator_import, "Illustrator import");
		add (test_parse_quadratic_paths, "Quadratic paths");
		add (test_freetype, "Freetype");
		add (test_preview, "Preview");
		add (test_kerning, "Kerning");
		add (test_boundaries, "Boundaries");
		add (test_extrema, "Extrema");
		add (test_codepages, "Codepages");
			
		add_bechmark (benchmark_stroke, "Stroke");
	}
	
	private void add_bechmark (Callback callback, string name) {
		test_cases.append (new Test (callback, name, true));
	}
	
	private void add (Callback callback, string name) {
		test_cases.append (new Test (callback, name));
	}
	
	public unowned List<Test> get_test_functions () {
		return test_cases;
	}
	
	public static void test_codepages () {
		CodePageBits pages = new CodePageBits ();
		
		if (pages.get_bits ('ó').length () == 0) {
			warning ("Codepage for Hungarian is not set.");
		}
		
		if (pages.get_bits ('ö').length () == 0) {
			warning ("Codepage for Swedish is not set.");
		}

		if (pages.get_bits ('ﾂ').length () == 0) {
			warning ("Codepage for Japanese is not set.");
		}

		if (pages.get_bits ('马').length () == 0) {
			warning ("Codepage for Chinese is not set.");
		}
	}
	
	public static void load_test_font () {
		string fn = "./fonts/Decibel.bf";
		Font f = BirdFont.new_font ();
		
		f.set_read_only (true);
		
		if (!f.load (fn)) {
			warning (@"Failed to load fond $fn");
			return;
		}
		
		if (f.length () == 0) {
			warning ("No glyphs in font.");
		}
	}

	public static void test_kerning () {
		KerningDisplay k;
		Font font;
		Glyph? g;

		load_test_font ();
		
		k = MainWindow.get_kerning_display ();		
		font = BirdFont.get_current_font ();
		MenuTab.show_kerning_context ();
		
		if (font.length () == 0) {
			warning ("No font loaded.");
		}
		
		for (int i = 0; i < 10; i++) {
			for (int j = 0; j < 10; j++) {
				g = font.get_glyph_indice (Random.int_range (0, (int) font.length () - 1));
				return_if_fail (g != null);
				if (Random.int_range (1, 9) % 3 == 0) {
					k.add_kerning_class (Random.int_range (0, 9));
				} else {
					k.add_text (((!)g).get_unichar_string ());
				}
				
				GlyphCanvas.redraw ();
				Tool.yield ();
			}
			
			for (int j = 0; j < 10; j++) {
				k.set_absolute_kerning (Random.int_range (1, 9), Random.int_range (0, 30));
				GlyphCanvas.redraw ();								
				Tool.yield ();
			}
			
			k.new_line ();
			GlyphCanvas.redraw ();
			Tool.yield ();
		}
	}

	public static void benchmark_stroke () {
		Glyph glyph;
		test_open_next_glyph ();
		test_illustrator_import ();
		
		glyph = MainWindow.get_current_glyph ();
		for (int i = 0; i < 5; i++) {
			foreach (Path p in glyph.path_list) {
				p.set_stroke (i / 100.0);
				glyph.update_view ();
				Tool.yield ();
			}
		}
	}
	
	public static void test_extrema () {
		Glyph g;
		SvgParser parser = new SvgParser ();
		
		test_open_next_glyph ();
		g = MainWindow.get_current_glyph ();
		
		parser.set_format (SvgFormat.INKSCAPE);
		parser.add_path_to_glyph ("m -163.59375,-250.78125 c -42.43208,51.5679 -78.92929,123.30265 -109.59375,216.03125 l 94.9375,31.375 c 27.9767,-84.600883 60.86301,-146.18598 91.875,-183.875 48.545803,-62.79748 104.513616,-52.47212 139.34375,-5.46875 25.619399,35.30837 51.38402,95.22476 69.625,178.625 l 97.6875,-21.375 c -20.20842,-92.39565 -48.64621,-164.00261 -86.375,-216 -88.811818,-115.9163 -218.868232,-92.82539 -297.5,0.6875 z", g);
		
		Toolbox.select_tool_by_name ("full_glyph");
		
		foreach (Path p in g.path_list) {
			p.add_extrema ();
		}
	}
	
	public static void test_freetype () {
		StringBuilder? data;
		int error;
		File f = BirdFont.get_settings_directory ();
		Font font = BirdFont.get_current_font ();
		
		font.set_name ("TEST_FONT");
				
		// draw some test glyphs
		test_illustrator_import ();
		test_inkscape_import ();
		
		Tool.yield ();
		
		if (!ExportTool.export_ttf_font_path (f, false)) {
			warning ("TTF export failed.");
		}
		
		f = f.get_child (font.get_name () + ".ttf");
		if (!f.query_exists ()) {
			warning ("File does not exist.");
		}
		
		data = load_freetype_font ((!) f.get_path (), out error);
		if (error != 0) {
			warning ("Failed to load font.");
			return;
		}
		
		if (data == null) {
			warning ("No bf data.");
			return;
		}
		
		Tool.yield ();
		
		font.load ((!) f.get_path ());
	}

	public static void test_parse_quadratic_paths () {
		Glyph g;
		SvgParser parser = new SvgParser ();
		
		test_open_next_glyph ();
		
		parser.set_format (SvgFormat.INKSCAPE);
		
		g = MainWindow.get_current_glyph ();
		parser.parse_svg_data ("M20,300 Q400,50 600,300 T1000,300Q1200 50 1400 300Q1600 50 1800 600 L 1800 700 L 200 700 z", g);
		Toolbox.select_tool_by_name ("full_glyph");
		
		g = MainWindow.get_current_glyph ();
		parser.parse_svg_data ("M300 400 h-200 l0 1000 h200z", g, true);
		Toolbox.select_tool_by_name ("full_glyph");


		parser.set_format (SvgFormat.ILLUSTRATOR);
		
		g = MainWindow.get_current_glyph ();
		parser.parse_svg_data ("M20,300 Q400,50 600,300 T1000,300Q1200 50 1400 300Q1600 50 1800 600 L 1800 700 L 200 700 z", g);
		Toolbox.select_tool_by_name ("full_glyph");
		
		g = MainWindow.get_current_glyph ();
		parser.parse_svg_data ("M300 400 h-200 l0 1000 h200z", g, true);
		Toolbox.select_tool_by_name ("full_glyph");
		
	}

	public static void test_illustrator_import () {
		Glyph g;
		SvgParser parser = new SvgParser ();
		string illustrator_data = """<?xml version="1.0" encoding="utf-8"?>
<!-- Generator: Adobe Illustrator 15.0.2, SVG Export Plug-In . SVG Version: 6.00 Build 0)  -->
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px"
	 width="595.28px" height="841.89px" viewBox="0 0 595.28 841.89" enable-background="new 0 0 595.28 841.89" xml:space="preserve">
<path fill="#FFFFFF" stroke="#000000" stroke-miterlimit="10" d="M49.102,263.776"/>
<g>
	<g>
		<path d="M3.037,3.799c0.006-0.057,0.013-0.114,0.019-0.171c0.111-1.002-1.577-0.438-1.89,0.01c0.007-0.012,0.013-0.024,0.02-0.036
			C1.49,3.626,1.795,3.651,2.1,3.676C2.061,3.954,2.195,4.022,2.5,3.88c0.346-0.007,0.691-0.009,1.036-0.006
			C4.45,3.876,5.367,3.971,6.279,4.015c1.569,0.075,3.033-0.056,4.441-0.776c1.18-0.604,0.111-1.501-0.824-1.022
			c-2.19,1.121-5.157,0.242-7.563,0.39C1.281,2.67,0.104,3.19,0.182,4.371C0.218,4.488,0.29,4.577,0.395,4.639
			C1.397,5.095,2.39,4.668,2.997,3.797c-0.63,0.003-1.26,0.006-1.89,0.01C1.101,3.864,1.095,3.921,1.088,3.979
			C0.985,4.903,2.948,4.596,3.037,3.799L3.037,3.799z"/>
	</g>
</g>
<g>
	<g>
		<path d="M4.668,3.559C4.614,5.102,4.586,6.642,4.63,8.186c0.02,0.679-0.033,1.363-0.054,2.041
			c-0.017,0.587,0.309,1.136-0.299,1.16c-0.563,0.022-1.708,1.045-0.669,1.263c1.091,0.229,2.12,0.154,3.229,0.118
			c1.057-0.035,1.522-1.348,0.201-1.305c-0.76,0.025-1.539,0.124-2.293-0.035c-0.223,0.421-0.446,0.842-0.669,1.263
			c1.091-0.043,2.411-0.278,2.5-1.583c0.173-2.551-0.048-5.164,0.042-7.728C6.65,2.432,4.696,2.761,4.668,3.559L4.668,3.559z"/>
	</g>
</g>
<g>
	<g>
		<path d="M10.014,7.024C9.189,7.82,8.786,8.42,8.661,9.58c-0.098,0.906-0.05,1.599,0.515,2.346
			c1.215,1.608,3.572,0.777,5.021,0.102c0.216-0.101,0.627-0.469,0.208-0.612c-0.437-0.149-0.964,0.034-1.358,0.218
			c-1.281,0.597-2.335-0.241-2.516-1.55C10.356,8.81,10.916,7.8,11.784,6.961c0.336-0.325-0.288-0.434-0.486-0.427
			C10.843,6.55,10.346,6.704,10.014,7.024L10.014,7.024z"/>
	</g>
</g>
<g>
	<g>
		<path d="M11.415,7.436c0.267-0.022,0.588-0.066,0.852,0.006c-0.072-0.02-0.12-0.251-0.072-0.044
			c0.021,0.091-0.01,0.268-0.007,0.372c0.003,0.135,0.007,0.264-0.003,0.399c0.001-0.022,0.038-0.029-0.014-0.024
			c-0.343,0.036-0.735,0.108-1.079,0.09c-0.478-0.026-1.041,0.124-1.254,0.606c-0.187,0.423,0.169,0.847,0.604,0.87
			c1.314,0.07,3.575-0.07,3.716-1.796c0.043-0.535,0.063-1.19-0.354-1.581c-0.544-0.511-1.554-0.451-2.239-0.394
			c-0.441,0.037-1.006,0.31-1.056,0.81C10.459,7.24,11.007,7.47,11.415,7.436L11.415,7.436z"/>
	</g>
</g>
<g>
	<g>
		<path d="M17.85,6.628c-0.13,0.059-0.265,0.102-0.404,0.131c0.104-0.019,0.122-0.021,0.051-0.008
			c0.112-0.013,0.218-0.015,0.33-0.013c0.152,0.002,0.394,0.013,0.466,0.17c0.207,0.454,2.073-0.208,1.932-0.518
			c-0.203-0.445-0.951-0.422-1.354-0.417c-0.719,0.01-1.468,0.13-2.126,0.43c-0.143,0.065-0.675,0.39-0.243,0.477
			C16.934,6.969,17.461,6.806,17.85,6.628L17.85,6.628z"/>
	</g>
</g>
<g>
	<g>
		<path d="M16.858,6.049c-1.111,0.292-2.424,1.692-1.018,2.544c1.076,0.653,3.576,0.595,2.513,2.572
			c-0.206,0.382,0.683,0.367,0.816,0.348c0.419-0.059,0.897-0.228,1.107-0.619c0.548-1.019,0.155-1.903-0.79-2.432
			c-0.418-0.234-0.906-0.356-1.363-0.491c-0.251-0.075-0.492-0.155-0.732-0.259c-0.302-0.131-0.08-0.863-0.304-0.804
			c0.242-0.063,0.952-0.313,0.851-0.688C17.838,5.842,17.1,5.985,16.858,6.049L16.858,6.049z"/>
	</g>
</g>
<g>
	<g>
		<path d="M14.983,10.708c-0.036,0.299-0.137,0.716,0.08,0.972c0.244,0.286,0.663,0.358,1.01,0.435
			c0.994,0.221,1.846,0.177,2.792-0.243c0.185-0.082,0.844-0.417,0.533-0.711c-0.296-0.28-0.951-0.124-1.269,0.018
			c-0.317,0.141-0.505,0.035-0.853-0.039c-0.444-0.095-0.42-0.276-0.369-0.702C16.991,9.74,15.055,10.114,14.983,10.708
			L14.983,10.708z"/>
	</g>
</g>
<g>
	<g>
		<path d="M21.915,6.956c1.207,0.189,2.389,0.085,3.601,0.082c0.424-0.001,1.009-0.321,1.063-0.784
			c0.06-0.506-0.514-0.641-0.895-0.639c-1.048,0.003-2.059,0.093-3.103-0.071C21.625,5.394,20.618,6.752,21.915,6.956L21.915,6.956z
			"/>
	</g>
</g>
<g>
	<g>
		<path d="M21.948,5.359c-0.002,1.245-0.005,2.491-0.045,3.735c-0.023,0.708-0.252,1.594,0.142,2.241
			c0.911,1.494,3.401,0.492,4.227-0.546c0.544-0.685-1.407-0.547-1.802-0.051c-0.708,0.891-0.653-1.618-0.634-1.881
			c0.087-1.235,0.043-2.497,0.045-3.735C23.883,4.302,21.949,4.715,21.948,5.359L21.948,5.359z"/>
	</g>
</g>
</svg>""";
		try {
			File temp_file;
			FileIOStream? ios;
			DataOutputStream d;
			FileOutputStream? os;
			
			temp_file = BirdFont.get_settings_directory ().get_child ("illustrator_test.svg");
			
			if (temp_file.query_exists ()) {
				temp_file.delete ();
			}
			
			ios = temp_file.create_readwrite (FileCreateFlags.PRIVATE);
			os = ((!) ios).output_stream as FileOutputStream?;
			d = new DataOutputStream ((!) os);
			
			d.put_string (illustrator_data);
			d.close ();
			
			test_open_next_glyph ();
			SvgParser.import_svg ((!) temp_file.get_path ());

			temp_file.delete ();
			
			g = MainWindow.get_current_glyph ();
			
			parser.set_format (SvgFormat.ILLUSTRATOR);
			parser.add_path_to_glyph ("M67.4,43.5c0,1.1-0.9,2-2,2c-1.1,0-2-0.9-2-2c0-1.1,0.9-2,2-2C66.5,41.5,67.4,42.4,67.4,43.5z", g);
			
			Toolbox.select_tool_by_name ("full_glyph");
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}

	public static void test_inkscape_import () {
		string inkscape_data = """<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg
   xmlns:dc="http://purl.org/dc/elements/1.1/"
   xmlns:cc="http://creativecommons.org/ns#"
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns:svg="http://www.w3.org/2000/svg"
   xmlns="http://www.w3.org/2000/svg"
   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
   width="56"
   height="111"
   id="glyph_A"
   version="1.1"
   inkscape:version="0.48.2 r9819"
   sodipodi:docname="Glyph_template.svg">
  <metadata
     id="metadata10">
    <rdf:RDF>
      <cc:Work
         rdf:about="">
        <dc:format>image/svg+xml</dc:format>
        <dc:type
           rdf:resource="http://purl.org/dc/dcmitype/StillImage" />
        <dc:title></dc:title>
      </cc:Work>
    </rdf:RDF>
  </metadata>
  <defs
     id="defs8" />
  <sodipodi:namedview
     id="namedview3"
     showgrid="false"
     inkscape:zoom="1"
     inkscape:cx="-27.517479"
     inkscape:cy="43.414876"
     inkscape:window-width="721"
     inkscape:window-height="429"
     inkscape:window-x="557"
     inkscape:window-y="24"
     inkscape:window-maximized="0"
     inkscape:current-layer="glyph_A"
     inkscape:object-paths="true">
    <sodipodi:guide
       orientation="0,1"
       position="0,39"
       id="baseline" />
  </sodipodi:namedview>
  <path
     style="fill:#000000;fill-opacity:1;stroke:none"
     id="path3142"
     d="M 2.4461236,18.613363 C 3.4535706,17.30804 4.565697,16.070157 5.7189269,14.889064 9.7698153,10.543221 17.324067,7.5616696 21.327378,5.1981153 25.286661,2.860555 13.350954,9.773823 9.3627418,12.061677 16.280624,7.4352732 19.834614,4.1353939 26.808001,3.7441018 c 1.967367,-0.074299 3.936743,-0.05736 5.905091,-0.051608 1.741423,0.3127973 3.428071,0.6890467 5.085162,1.2943721 1.392556,0.6843074 2.448976,1.7917908 3.622959,2.766069 1.120096,1.0121812 2.001523,2.1988012 2.819774,3.4625798 0.849867,1.417783 1.525325,2.83856 1.899606,4.455126 0.609221,1.591091 0.969893,3.232962 1.176184,4.91949 0.18844,1.961102 0.190368,3.933599 0.19931,5.901817 -0.02338,1.98962 0.05666,3.98236 -0.06167,5.96929 -0.326157,1.726864 -0.640714,3.446402 -0.799219,5.198174 -0.141202,1.943199 -0.145653,3.892792 -0.153936,5.840056 -0.0035,2.000837 7.65e-4,4.001679 0.0028,6.002516 0.0019,2.000867 0.0023,4.001735 0.0026,6.002602 -0.119448,1.837413 0.05012,3.609162 0.411903,5.404108 0.436533,1.339043 1.162712,2.583413 2.144788,3.594149 1.406807,1.142779 3.002396,1.683088 4.761485,1.987684 1.194717,0.02857 2.577648,0.517596 3.736705,0.02255 0.232429,-0.09927 0.843546,-0.555586 0.622914,-0.432299 -4.033997,2.254157 -8.043973,4.551038 -12.065959,6.826557 0.179915,-0.145379 0.359829,-0.290757 0.539744,-0.436135 0,0 13.621702,-5.579012 13.621702,-5.579012 l 0,0 c -0.167578,0.175551 -0.335155,0.351102 -0.502733,0.526654 -8.740107,5.12179 -10.300507,8.97968 -17.955597,7.404265 -1.957383,-0.50948 -3.799128,-1.304798 -5.299977,-2.701355 -1.123481,-1.261267 -2.039019,-2.666586 -2.534331,-4.296084 -0.383149,-1.891076 -0.646571,-3.750061 -0.493931,-5.690321 -1.27e-4,-2.000559 -2.84e-4,-4.001119 -0.0017,-6.001678 -0.0017,-2.002107 -0.0049,-4.004212 -0.0062,-6.00632 0.0014,-1.974097 -0.0026,-3.949232 0.08455,-5.921848 0.102996,-1.775437 0.264342,-3.552014 0.742963,-5.2725 0.434483,-1.889017 0.07193,-3.87962 0.190989,-5.804901 -0.0055,-1.914254 -0.0023,-3.8318 -0.157754,-5.741122 -0.175482,-1.642594 -0.511621,-3.23618 -1.128362,-4.775955 -0.299347,-1.455042 -0.914171,-2.699067 -1.678627,-3.966466 -0.757218,-1.14089 -1.561752,-2.21279 -2.610877,-3.106654 -1.010538,-0.897967 -2.015327,-1.827459 -3.298779,-2.322908 -1.523105,-0.512447 -3.13219,-0.816768 -4.732721,-0.938511 -1.950528,0.0034 -3.90631,-0.0079 -5.849616,0.18331 C 9.3832464,13.223396 1.1561405,19.629883 23.07831,6.7491978 18.671333,9.2959874 14.344902,11.987543 9.8573789,14.389567 5.8103531,16.555807 17.78997,9.7680895 21.756041,7.4569649 c 0.21409,-0.1247553 -0.441297,0.229177 -0.642719,0.3734938 -0.63252,0.4531925 -1.255742,0.879984 -1.87055,1.3612245 -0.990862,1.2263148 -2.173114,2.3052708 -3.210427,3.4772508 0,0 -13.5862214,5.944429 -13.5862214,5.944429 z"
     inkscape:connector-curvature="0" />
  <path
     style="fill:#000000;fill-opacity:1;stroke:none"
     id="path3150"
     d="m 44.537632,32.349942 c -5.147586,4.026032 -10.873455,6.771035 -16.655502,10.098737 -0.71409,0.686928 -1.63002,0.452279 -2.474519,0.671405 -0.401059,0.104064 -0.753081,0.349262 -1.144818,0.484244 0.736676,0.02838 -2.473393,1.416554 -1.731752,0.983942 29.062029,-16.9524 1.81009,-0.272962 -1.896399,1.014801 -1.286917,0.200555 -2.275566,1.042375 -3.532153,1.301287 -0.405308,0.554267 -1.065095,0.524248 -1.613699,0.795566 -0.662739,0.327763 -1.122742,0.692276 -1.857371,0.928714 -0.760106,0.785065 -1.819224,0.812321 -2.767366,1.163123 -0.474696,0.175632 -0.902223,0.461763 -1.370835,0.653036 -0.256593,0.07288 -0.525961,0.110449 -0.76978,0.218632 C 8.268551,50.865263 6.9846029,51.632281 7.4154555,51.383232 27.533295,39.754369 22.52409,42.532955 18.240391,45.295266 c -1.165488,0.819073 -2.012315,1.89418 -2.774998,3.081098 -0.845284,1.267918 -1.306169,2.696946 -1.894144,4.085429 -0.709336,1.412367 -0.787279,2.808431 -0.584867,4.335462 0.415146,1.308403 0.866784,2.618592 1.690615,3.729211 0.711541,1.116569 1.843939,1.954136 3.05544,2.471647 1.434799,0.587706 2.820424,1.107721 4.370221,1.331222 1.863012,0.201467 3.740237,0.197001 5.61174,0.204627 1.061154,-0.422861 2.259141,-0.406524 3.338121,-0.726337 0.500528,-0.148359 0.95492,-0.423492 1.442889,-0.609031 0.259577,-0.07197 0.531931,-0.107987 0.778732,-0.215924 0.228316,-0.09985 0.420765,-0.267119 0.631148,-0.400678 0.226794,-0.107396 0.447133,-0.229644 0.680383,-0.322187 0.768356,-0.304847 1.479129,-0.382367 2.210911,-0.783628 0.236171,-0.09699 0.929553,-0.418726 0.708513,-0.290959 -3.986257,2.304163 -8.00314,4.554946 -12.009817,6.823414 -0.211901,0.119973 0.413749,-0.25711 0.625248,-0.37779 4.424854,-2.524796 8.855737,-5.039013 13.283606,-7.55852 0,0 -11.493423,9.1721 -11.493423,9.1721 l 0,0 c 25.632954,-14.826031 4.799005,-2.558131 -2.652451,1.337169 -1.491162,0.456817 -2.849157,1.212206 -4.348056,1.647882 -1.608784,0.520829 -3.334322,0.82218 -5.021523,0.881289 -1.937875,-0.0244 -3.888043,-0.04197 -5.802052,-0.381372 C 8.46504,72.371171 6.9529525,71.749159 5.4402732,71.071006 4.1002399,70.2927 2.824761,69.338054 2,68 1.0937305,66.666625 0.5063194,65.186179 6.26e-5,63.660049 -0.2882245,61.935817 -0.448618,60.290055 0.2235018,58.61527 c 0.1864285,-0.460298 0.454071,-0.886178 0.6246649,-1.352577 0.3555415,-0.972041 0.4430375,-2.039925 1.2194084,-2.823626 0.4742277,-1.223862 1.4594908,-2.851226 2.5303973,-3.615873 0.5972416,-0.654754 0.3607951,-0.495492 1.1169283,-0.93613 5.5407473,-3.22888 9.7725723,-6.443379 15.3177753,-8.545059 1.391905,-0.595239 2.821693,-1.08014 4.148056,-1.823818 1.170505,-0.612883 2.349173,-1.244779 3.589444,-1.688564 1.099136,-0.541341 2.265558,-0.860322 3.384995,-1.366026 5.518505,-3.123477 -15.359314,8.690656 -11.325042,6.562985 4.683757,-2.470209 9.826663,-6.265044 15.072968,-8.467654 1.169288,-0.37991 2.379509,-0.540929 3.409749,-1.289413 -29.666352,17.271684 -10.82022,7.119963 -8.585469,4.48399 0,0 13.810255,-5.403563 13.810255,-5.403563 z"
     inkscape:connector-curvature="0" />
</svg>""";
		try {
			File temp_file;
			FileIOStream? ios;
			DataOutputStream d;
			FileOutputStream? os;
			
			temp_file = BirdFont.get_settings_directory ().get_child ("inkscape_test.svg");
			
			if (temp_file.query_exists ()) {
				temp_file.delete ();
			}
			
			ios = temp_file.create_readwrite (FileCreateFlags.PRIVATE);
			os = ((!) ios).output_stream as FileOutputStream?;
			d = new DataOutputStream ((!) os);
			
			d.put_string (inkscape_data);
			d.close ();
			
			test_open_next_glyph ();
			SvgParser.import_svg ((!) temp_file.get_path ());

			temp_file.delete ();
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}

	public static void test_spin_button () {
		SpinButton s = new SpinButton ();
		double last;
		string e = "Wrong value in SpinButton";
		
		s.set_max (1);
		s.set_min (0);
		s.set_value ("0.000");
		
		if (s.get_display_value () != "0.000") {
			warning (e);
		}

		s.increase ();
		
		if (s.get_display_value () != "0.001") {
			warning (e);
		}
		
		last = s.get_value ();
		for (int i = 0; i < 100; i++) {
			s.increase ();
			if (last > s.get_value ()) {
				warning (e);
			}
			last = s.get_value ();
		}

		if (s.get_display_value () != "0.101") {
			warning (e);
		}
		
		s.set_value ("1.000");

		if (s.get_display_value () != "1.000") {
			warning (e);
		}

		last = s.get_value ();
		for (int i = 0; i < 100; i++) {
			s.decrease ();
			if (last < s.get_value ()) {
				warning (e);
			}
			last = s.get_value ();
		}

		if (s.get_display_value () != "0.900") {
			warning (e);
		}
	}

	public static void test_background_coordinates () {
		GlyphBackgroundImage bg = new GlyphBackgroundImage ("");
		
		bg.set_position (100, 100);
		bg.set_img_offset (bg.img_offset_x, bg.img_offset_y);
		warn_if_fail (bg.img_x == 100 && bg.img_y == 100);

		bg.set_img_offset (100, 100);
		bg.set_position (bg.img_x, bg.img_y);
		warn_if_fail (bg.img_offset_x == 100 && bg.img_offset_y == 100);
	}

	public static void test_export () {
		Glyph g;
		Path p = new Path ();
		
		test_open_next_glyph ();
		g = MainWindow.get_current_glyph ();
				
		p.add (-10, -10);
		p.add (50, 50);
		p.add (10, -10);
		
		p.close ();
		g.add_path (p);	

		MenuTab.preview ();

		// TODO: run this many times on big fonts
		for (int i = 0; i < 10; i++) {
			ExportTool.export_all ();
			Tool.yield ();
		}		
	}


	public static void test_preview () {
		Glyph g;
		Path p = new Path ();
		
		test_open_next_glyph ();
		g = MainWindow.get_current_glyph ();
				
		p.add (-10, 10);
		p.add (10, 10);
		p.add (10, -10);
		p.add (-10, -10);
		p.close ();
		g.add_path (p);	

		MenuTab.preview ();

		// TODO: run this many times on big font
		for (int i = 0; i < 100; i++) {
			MainWindow.get_tab_bar ().select_tab_name ("Files");
			Tool.yield ();
			
			MainWindow.get_tab_bar ().select_tab_name ("Preview");
			Tool.yield ();
		}
		
	}

	public static void test_over_path () {
		Glyph g;
		Path p = new Path ();
		Tool pen_tool;
		
		pen_tool = MainWindow.get_toolbox ().get_tool ("pen_tool");
		test_select_action (pen_tool);
		test_open_next_glyph ();
		
		g = MainWindow.get_current_glyph ();

		test_click_action (pen_tool, 3, 10, 10);
		test_click_action (pen_tool, 3, 10, 10);
		test_click_action (pen_tool, 3, 100, 10);
		test_click_action (pen_tool, 3, 100, 100);
		test_click_action (pen_tool, 3, 10, 100);
		test_click_action (pen_tool, 2, 0, 0);

		g.close_path ();

		warn_if_fail (g.active_paths.size == 0);

		g.select_path (50, 50);

		warn_if_fail (g.active_paths.size == 1);
		
		p.add (-10, 10);
		p.add (10, 10);
		p.add (10, -10);
		p.add (-10, -10);
		p.update_region_boundaries();
		g.add_path (p);
		g.close_path ();

		if (!p.is_over_coordinate (0, 0)) {
			warning ("Coordinate 0, 0 is not in path.");
		}
		
		if (!p.is_over_coordinate (-10, 10)) {
			warning ("Corner corrdinate -10, 10 is not in path.");
		}
		
		warn_if_fail (!p.is_over_coordinate (-20, -20));
		
		for (double x = -10; x <= 10; x += 0.1) {
			for (double y = 10; y <= 10; y += 0.1) {
				warn_if_fail (p.is_over_coordinate (x, y));
			} 
		} 
		
	}

	public static void test_merge () {
		Glyph g;
		Path p = new Path ();
		Path p2 = new Path ();
		
		test_open_next_glyph ();
		g = MainWindow.get_current_glyph ();
				
		p.add (-10, 10);
		p.add (10, 10);
		p.add (10, -10);
		p.add (-10, -10);
		p.close ();
		g.add_path (p);

		p2.add (10, 10);
		p2.add (10, -10);		
		p2.add (20, -10);
		p2.add (20, 10);
		p2.reverse ();
		p2.close ();
		g.add_path (p2);
		
		g.add_active_path (p);
		g.add_active_path (p);
		
		g.add_active_path (p);
		g.merge_all	();
		
		test_merge_second_triangle ();
		test_merge_simple_path_box_and_triangle ();
		test_merge_simple_path_box ();
		test_merge_odd_paths ();
	}

	public static void test_notdef () {
		Font f = BirdFont.get_current_font ();
		Glyph n = f.get_not_def_character ();
		Glyph g;
		Path pn;
		
		test_open_next_glyph ();
		g = MainWindow.get_current_glyph ();
		foreach (Path p in n.path_list) {
			pn = p.copy ().get_quadratic_points ();
			g.path_list.add (pn);
			pn.move (50, 0);
			g.path_list.add (p.copy ());
		}
	}

	public static void test_convert_to_quadratic_bezier_path () {
		Glyph g;
		Path p, p1;
		EditPoint e0, e1, e2, e3;
		List<Path> paths = new List<Path> ();
		
		// convert the current path
		g = MainWindow.get_current_glyph ();
		
		foreach (Path path in g.path_list) {
			paths.append (path.get_quadratic_points ());
			paths.append (path.copy ());
		}
				
		// create a new path and convert it
		test_open_next_glyph ();
		
		p = new Path ();
		p1 = new Path ();
				
		g = MainWindow.get_current_glyph ();
		
		p.add (-10, 10);
		p.add (10, 10);
		p.add (10, -10);
		p.add (-10, -10);
		p.close ();
		g.add_path (p);
		g.add_path (p1.get_quadratic_points ());

		e0 = new EditPoint (20, 40);
		e1 = new EditPoint (40, 40);
		e2 = new EditPoint (40, 20);
		e3 = new EditPoint (20, 20);

		p1.add_point (e0);
		p1.add_point (e1);
		p1.add_point (e2);
		p1.add_point (e3);
		p1.close ();

		e0.set_tie_handle (true);
		e1.set_tie_handle (true);
		e2.set_tie_handle (true);
		e3.set_tie_handle (true);

		e0.process_tied_handle ();
		e1.process_tied_handle ();
		e2.process_tied_handle ();
		e3.process_tied_handle ();

		g.add_path (p1);
		g.add_path (p1.get_quadratic_points ());
		
		foreach (Path path in paths) {
			g.add_path (path);
		}
	}

	public static void test_overview () {
		OverView o = MainWindow.get_overview ();

		warn_if_fail (o.selected_char_is_visible ());
	
		for (int i = 0; i < 10; i++) {
			o.key_down ();
			warn_if_fail (o.selected_char_is_visible ());
		}

		for (int i = 0; i < 15; i++) {
			o.key_up ();
			warn_if_fail (o.selected_char_is_visible ());
		}

		for (int i = 0; i < 6; i++) {
			o.key_down ();
			warn_if_fail (o.selected_char_is_visible ());
		}

		for (int i = 0; i < 3; i++) {
			o.key_down ();
			warn_if_fail (o.selected_char_is_visible ());
		}
		
		for (int i = 0; i < 2000; i++) {
			o.scroll_adjustment (5);
		}

		for (int i = 0; i < 2000; i++) {
			o.scroll_adjustment (-5);
		}
	}

	public static void test_data_reader () {
		FontData fd = new FontData ();
		uint len;
		int v;
		
		try {
			fd.add (7);
			fd.add_ulong (0x5F0F3CF5);
			fd.add_ulong (9);
			
			warn_if_fail (fd.table_data[0] == 7);
			warn_if_fail (fd.read () == 7);
			warn_if_fail (fd.read_ulong () == 0x5F0F3CF5);
			warn_if_fail (fd.read_ulong () == 9);
			
			fd = new FontData ();
			for (int16 i = 0; i < 2048; i++) {
				fd.add_short (i);
			}
			
			fd.seek (2 * 80);
			warn_if_fail (fd.read_short () == 80);
			
			fd.seek (100);
			fd.add_short (7);
			fd.seek (100);
			warn_if_fail (fd.read_short () == 7);
			
			fd.seek_end ();
			len = fd.length ();
			fd.add (0);
			warn_if_fail (len + 1 == fd.length ());
			
			fd.seek_end ();
			for (int i = -1131; i < 1131; i++) {
				fd.add_charstring_value (i);
			}

			for (int i = -1131; i < 1131; i++) {
				v = fd.read_charstring_value ();
				if (v != i) {
					warning (@"expecting $i got $v\n");
				}
			}

		} catch (GLib.Error e) {
			warning (e.message);
		}
	}


	public static void test_argument () {
		Argument arg = new Argument ("supplement -t \"Argument list\" --unknown -unknown --help -s");
		
		return_if_fail (arg.has_argument ("--test"));
		return_if_fail ((!) arg.get_argument ("--test") == "\"Argument list\"" );
		return_if_fail (arg.has_argument ("--unknown"));
		return_if_fail (arg.has_argument ("--help"));
		return_if_fail (arg.has_argument ("--slow"));
		return_if_fail (arg.validate () != 0);

		arg = new Argument ("supplement --test \"Argument list\"");
		return_if_fail ((!) arg.get_argument ("--test") == "\"Argument list\"" );
		return_if_fail (!arg.has_argument ("--help"));
		return_if_fail (!arg.has_argument ("--slow"));
		return_if_fail (arg.validate () == 0);
		
	}

	public static void test_glyph_ranges () {
		GlyphRange gr = new GlyphRange ();
		GlyphRange gr_az = new GlyphRange ();
		
		gr.add_range ('b', 'c');
		gr.add_single ('d');
		gr.add_range ('e', 'h');
		gr.add_range ('k', 'm');
		gr.add_range ('o', 'u');
		gr.add_range ('a', 'd');
		gr.add_range ('f', 'z');
		gr.add_range ('b', 'd');
		
		gr.print_all ();
		
		return_if_fail (gr.length () == 'z' - 'a' + 1);
		return_if_fail (gr.get_ranges ().size == 1);
		return_if_fail (gr.get_ranges ().get (0).length () == 'z' - 'a' + 1);
		
		for (unichar i = 'a'; i <= 'z'; i++) {
			uint index = i - 'a';
			string c = gr.get_char (index);
			StringBuilder s = new StringBuilder ();
			s.append_unichar (i);
			
			if (c != s.str) {
				warning (@"wrong glyph in glyph range got \"$c\" expected \"$(s.str)\" for index $(index).");
			}
		}
		
		gr = new GlyphRange ();
		gr.add_single ('a');
		gr.add_range ('c', 'e');
		gr.add_single ('◊');
		return_if_fail (gr.get_char (0) == "a");
		return_if_fail (gr.get_char (1) == "c");
		return_if_fail (gr.get_char (2) == "d");
		return_if_fail (gr.get_char (3) == "e");
		return_if_fail (gr.get_char (4) == "◊");
		
		// a-z 
		gr_az.add_range ('a', 'z');
		if (!gr_az.has_character ("g")) {
			warning ("Can not g in range a-z ");
		}
		
		if (gr_az.has_character ("å")) {
			warning ("Range a-z has å");
		}
		
		// codepage test for Latin 2
		try {
			gr = new GlyphRange ();
			gr.parse_ranges ("- Ç ü-ý é á-â ä Ů-ű ç Ł-ń ë Ő-ő í-î Ä É Ĺ-ĺ ó-ô ö-÷ Ľ-ľ Ö-× Ü-Ý ú Ź-ž Ę-ě «-­ » ░-▓ │ ┤ Á-Â ╣ ═-║ ╗ ╝ ┐ └ ┴ ┬ ├ ─ ┼ Ă-ć ╚ ╔ ╩ ╦ ╠ ╬ ¤ Č-đ Ë Ň-ň Í-Î ┘ ┌ █ ▄ Ş-ť ▀ Ó-Ô ß Ŕ-ŕ Ú ´ ˝ ˛ ˇ ˘-˙ §-¨ ¸ ° Ř-ś ■  ");
			if (!gr.has_character ("Ă")) {
				warning ("Latin 2 range does not have Ă");
			}
			
			if (!gr.has_unichar ('Ă')) {
				warning ("Latin 2 range  does not have Ă");
			}
		
			if (!gr.has_unichar ('ó')) {
				warning ("Latin 2 range  does not have ó");
			}
		} catch (MarkupError e) {
			warning (e.message);
		}
	}

	public static void test_hex () {
		test_hex_conv ('H', "U+48", 72);
		test_hex_conv ('1', "U+31", 49);
		test_hex_conv ('å', "U+e5", 229);
		test_hex_conv ('◊', "U+25ca", 9674);
	}

	private static void test_hex_conv (unichar h, string sr, int r) {
		string s = Font.to_hex (h);
		unichar t = Font.to_unichar (sr);
		
		if (s != sr) warning (@"($s != \"$sr\")");
		if ((int)t != r || t != h) warning (@"$((int)t) != $r || $t != '$h'");
	}

	// test pen tool
	/** Draw a test glyph. */
	public static void test_drawing () {
		Tool pen_tool = MainWindow.get_toolbox ().get_tool ("pen_tool");
		
		test_select_action (pen_tool);
		
		test_open_next_glyph ();
		
		// paint
		test_click_action (pen_tool, 1, 30, 30); 
		test_click_action (pen_tool, 1, 60, 30);
		test_click_action (pen_tool, 1, 60, 60);
		test_click_action (pen_tool, 1, 30, 60);
		
		// close
		test_click_action (pen_tool, 3, 0, 0);

		// reopen
		test_click_action (pen_tool, 3, 35, 35);
		
		// move around
		test_move_action (pen_tool, 100, 200);
		test_move_action (pen_tool, 20, 300);
		test_move_action (pen_tool, 0, 0);
		
		// add to path
		test_move_action (pen_tool, 70, 50);
		
		test_click_action (pen_tool, 1, 70, 50);
		test_click_action (pen_tool, 1, 70, 50);
		test_click_action (pen_tool, 1, 70, 100);
		test_click_action (pen_tool, 1, 50, 100); 
		test_click_action (pen_tool, 1, 50, 50);
		
		// close
		test_click_action (pen_tool, 3, 0, 0);
		Tool.yield ();
	}

	/** Test path coordinates and reverse path coordinates. */
	public static void test_coordinates () {
		int x, y, xc, yc;
		double px, py, mx, my;
		string n;
		Tool pen_tool = MainWindow.get_toolbox ().get_tool ("pen_tool");
		
		test_open_next_glyph ();
		Glyph g = MainWindow.get_current_glyph ();
		
		xc = (int) (g.allocation.width / 2.0);
		yc = (int) (g.allocation.height / 2.0);

		g.default_zoom ();
		
		x = 10;
		y = 15;
		
		px = Glyph.path_coordinate_x (x);
		py = Glyph.path_coordinate_y (y);

		mx = x * Glyph.ivz () - Glyph.xc () + g.view_offset_x;
		my = Glyph.yc () - y * Glyph.ivz () - g.view_offset_y;
		
		if (mx != px || my != py) {
			warning (@"bad coordinate $mx != $px || $my != $py");
		}
			
		test_reverse_coordinate (x, y, px, py, "ten fifteen");
		test_click_action (pen_tool, 1, x, y);
	
		// offset no zoom
		n = "Offset no zoom";
		g.reset_zoom ();
		
		px = Glyph.path_coordinate_x (x);
		py = Glyph.path_coordinate_y (y);
		
		test_reverse_coordinate (x, y, px, py, n);
		test_click_action (pen_tool, 1, x, y);
		
		// close path
		test_click_action (pen_tool, 3, x, y);
	}
	
	private static void test_reverse_coordinate (int x, int y, double px, double py, string n) {
		if (x != Glyph.reverse_path_coordinate_x (px) || Glyph.reverse_path_coordinate_y (py) != y) {
			warning (@"Reverse coordinates does not match current point for test case \"$n\".\n $x != $(Glyph.reverse_path_coordinate_x (px)) || $(Glyph.reverse_path_coordinate_y (py)) != $y (x != Glyph.reverse_path_coordinate_x (px) || Glyph.reverse_path_coordinate_y (py) != y)");
		}
	}
	
	private static void test_last_is_clockwise (string name) {
		bool d = ((!)MainWindow.get_current_glyph ().get_last_path ()).is_clockwise ();
		
		if (!d) {
			critical (@"\nPath $name is counter clockwise, in test_last_is_clockwise");
		}

	}
	
	private static bool test_reverse_last (string name) 
		requires (MainWindow.get_current_glyph ().get_last_path () != null)
	{
		Glyph g = MainWindow.get_current_glyph ();
		Path p = (!) g.get_last_path ();
		bool direction = p.is_clockwise ();

		p.reverse ();
		
		if (direction == p.is_clockwise ()) {
			critical (@"Direction did not change after reverseing path \"$name\"\n");
			stderr.printf (@"Path length: $(p.points.length ()) \n");
			return false;
		}

		Tool.yield ();
		return true;
	}
	
	class Point {
		
		public int x;
		public int y;
		
		public Point (int x, int y) {
			this.x = x;
			this.y = y;
		}
	}
	
	private static Point p (int x, int y) {
		return new Point (x, y);
	}
	
	private static void test_triangle (Point a, Point b, Point c, string name = "") {
		Tool pen_tool = MainWindow.get_toolbox ().get_tool ("pen_tool");
		
		Tool.yield ();
		MainWindow.get_tab_bar ().select_overview ();

		Tool.yield ();
		MainWindow.get_overview ().open_current_glyph ();
		
		test_select_action (pen_tool);
		
		test_click_action (pen_tool, 3, a.x, a.y);
		test_click_action (pen_tool, 3, b.x, b.y);
		test_click_action (pen_tool, 3, c.x, c.y);
		
		test_reverse_last (@"Triangle reverse \"$name\" ($(a.x), $(a.y)), ($(b.x), $(b.y)), ($(c.x), $(c.y)) failed.");
		
		Tool.yield ();
	}
	
	private static void test_various_triangles () {
		test_triangle (p (287, 261), p (155, 81), p (200, 104), "First");
		test_triangle (p (65, 100), p (168, 100), p (196, 177), "Second");
		test_triangle (p (132, 68), p (195, 283), p (195, 222), "Third");
		test_triangle (p (144, 267), p (147, 27), p (296, 267), "Fourth");
	}
	
	public static void test_reverse_path () {
		// open a new glyph
		Tool pen_tool = MainWindow.get_toolbox ().get_tool ("pen_tool");

		Tool.yield ();
		MainWindow.get_tab_bar ().select_overview ();

		Tool.yield ();
		MainWindow.get_overview ().open_current_glyph ();
		
		test_select_action (pen_tool);
		
		// paint
		int x_offset = 10;
		int y_offset = 10;
		
		test_open_next_glyph ();
		test_various_triangles ();
		
		test_open_next_glyph ();
		// draw clockwise and check direction		

		y_offset += 160;
		test_click_action (pen_tool, 3, 10 + x_offset, 20 + y_offset);
		test_click_action (pen_tool, 3, 17 + x_offset, 17 + y_offset);
		test_click_action (pen_tool, 3, 20 + x_offset, 0 + y_offset);
		test_click_action (pen_tool, 2, 0, 0);
		test_last_is_clockwise ("Clockwise triangle 1.2");

		// draw paths clockwise / counter clockwise and reverse them
		
		test_click_action (pen_tool, 3, 115, 137);
		test_click_action (pen_tool, 3, 89, 74);
		test_click_action (pen_tool, 3, 188, 232);
		test_click_action (pen_tool, 2, 0, 0);
		test_reverse_last ("Triangle 0");

		// draw incomplete paths
		y_offset += 20;
		test_click_action (pen_tool, 3, 10 + x_offset, 20 + y_offset);
		test_reverse_last ("Point");
		test_click_action (pen_tool, 2, 0, 0);

		y_offset += 20;
		test_click_action (pen_tool, 3, 10 + x_offset, 20 + y_offset);
		test_click_action (pen_tool, 3, 10 + x_offset, 20 + y_offset);
		test_reverse_last ("Double point");
		test_click_action (pen_tool, 2, 0, 0);
		
		y_offset += 20;
		test_click_action (pen_tool, 3, 10 + x_offset, 30 + y_offset);
		test_click_action (pen_tool, 3, 10 + x_offset, 20 + y_offset);
		test_reverse_last ("Vertical line");
		test_click_action (pen_tool, 2, 0, 0);
		
		y_offset += 20;
		test_click_action (pen_tool, 1, 30 + x_offset, 20 + y_offset);
		test_click_action (pen_tool, 1, 10 + x_offset, 20 + y_offset);
		test_click_action (pen_tool, 3, 0, 0);
		test_reverse_last ("Horisontal line");
		test_click_action (pen_tool, 2, 0, 0);
		
		// triangle 1
		y_offset += 20;
		test_click_action (pen_tool, 3, 10 + x_offset, -10 + y_offset);
		test_click_action (pen_tool, 3, 20 + x_offset, 20 + y_offset);
		test_click_action (pen_tool, 3, 30 + x_offset, 0 + y_offset);
		test_reverse_last ("Triangle reverse 1");
		test_click_action (pen_tool, 2, 0, 0);
		
		// box
		y_offset += 20;
		test_click_action (pen_tool, 3, 100 + x_offset, 150 + y_offset);
		test_click_action (pen_tool, 3, 150 + x_offset, 150 + y_offset);
		test_click_action (pen_tool, 3, 150 + x_offset, 100 + y_offset);
		test_click_action (pen_tool, 3, 100 + x_offset, 100 + y_offset); 
		test_reverse_last ("Box 1");
		test_click_action (pen_tool, 2, 0, 0);
	}
	
	private static Tool select_pen () {
		Tool pen_tool = MainWindow.get_toolbox ().get_tool ("pen_tool");
		test_select_action (pen_tool);
		return pen_tool;
	}
	
	public static void test_delete_points () {
		PenTool pen;

		test_open_next_glyph ();
				
		pen = (PenTool) select_pen ();
		
		// draw a line with ten points
		for (int i = 1; i <= 10; i++) {
			test_click_action (pen, 3, 20*i, 20);
		}	
	
		// TODO: it would be nice to test if points were created here
		
		// delete points
		for (int i = 1; i <= 10; i++) {
			test_move_action (pen, 20 * i, 20);
			test_click_action (pen, 1, 20*i, 20);
			PenTool.delete_selected_points ();
		}
	}

	public static void test_reverse_random_triangles () {
		Tool pen;
		
		int ax, bx, cx;
		int ay, by, cy;

		bool r = true;

		test_open_next_glyph ();
		pen = select_pen ();

		for (int i = 0; i < 30; i++) {
			Tool.yield ();
			
			ax = Random.int_range (0, 300);
			bx = Random.int_range (0, 300);
			cx = Random.int_range (0, 300);

			ay = Random.int_range (0, 300);
			by = Random.int_range (0, 300);
			cy = Random.int_range (0, 300);

			test_click_action (pen, 3, ax, ay);
			test_click_action (pen, 3, bx, by);
			test_click_action (pen, 3, cx, cy);
			test_click_action (pen, 2, 0, 0);
			
			r = test_reverse_last (@"Random triangle № $(i + 1) ($ax, $ay), ($bx, $by), ($cx, $cy)");
			if (!r) {
				test_open_next_glyph ();
				pen = select_pen ();

				test_click_action (pen, 3, ax, ay);
				test_click_action (pen, 3, bx, by);
				test_click_action (pen, 3, cx, cy);
				test_click_action (pen, 2, 0, 0);
				
				return;
			}
			
			test_open_next_glyph ();
		}
		
		if (r) test_open_next_glyph ();
	}

	
	/** Help function to test button press actions. */
	public static void test_click_action (Tool t, int b, int x, int y) {
		Tool.yield ();
		t.press_action (t, b, x, y);
		
		Tool.yield ();
		t.release_action (t, b, x, y);
	}

	/** Help function to test select action for this tool. */
	public static  void test_select_action (Tool t) {
		Toolbox tb = MainWindow.get_toolbox ();
		Tool.yield ();
		tb.select_tool (t);
	}

	public static  void test_move_action (Tool t, int x, int y) {
		Tool.yield ();
		t.move_action (t, x, y);
	}

	public static void test_press_action (Tool t, int b, int x, int y) {
		Tool.yield ();
		t.press_action (t, b, x, y);
	}

	public static void test_release_action (Tool t, int b, int x, int y) {
		Tool.yield ();
		t.release_action (t, b, x, y);
	}

	public static void test_open_next_glyph () {
		OverView o = MainWindow.get_overview ();
		
		MainWindow.get_tab_bar ().select_overview ();
		Toolbox.select_tool_by_name ("utf_8");
		
		o.select_next_glyph ();
		Tool.yield ();
		
		o.open_current_glyph ();
		Tool.yield ();
	}

	private static  void test_merge_odd_paths () {
		Tool pen_tool = MainWindow.get_toolbox ().get_tool ("pen_tool");

		Tool.yield ();
		MainWindow.get_tab_bar ().select_overview ();

		Tool.yield ();
		MainWindow.get_overview ().open_current_glyph ();
		
		test_select_action (pen_tool);

		// paint
		int x_offset = 100;
		int y_offset = 100;
						
		// rectangle
		test_click_action (pen_tool, 1, 100 + x_offset, 100 + y_offset);
		test_click_action (pen_tool, 1, 170 + x_offset, 100 + y_offset);
		test_click_action (pen_tool, 1, 170 + x_offset, 120 + y_offset);
		test_click_action (pen_tool, 1, 100 + x_offset, 120 + y_offset); 
		test_click_action (pen_tool, 3, 0, 0); // close
		
		// triangle
		test_click_action (pen_tool, 1, 100 + x_offset, 110 + y_offset);
		test_click_action (pen_tool, 1, 180 + x_offset, 130 + y_offset);
		test_click_action (pen_tool, 1, -10 + x_offset, 140 + y_offset);
		test_click_action (pen_tool, 3, 0, 0);

		// several triangles
		test_click_action (pen_tool, 1, 198, 379); 
		test_click_action (pen_tool, 1, 274, 328); 
		test_click_action (pen_tool, 1, 203, 286); 
		test_click_action (pen_tool, 3, 230, 333);

		test_click_action (pen_tool, 1, 233, 429); 
		test_click_action (pen_tool, 1, 293, 382); 
		test_click_action (pen_tool, 1, 222, 322); 
		test_click_action (pen_tool, 3, 225, 406);

		test_click_action (pen_tool, 1, 164, 316); 
		test_click_action (pen_tool, 1, 262, 289); 
		test_click_action (pen_tool, 1, 203, 260); 
		test_click_action (pen_tool, 3, 203, 260); 

		Tool.yield ();
		
		Toolbox.select_tool_by_name ("merge");
	}	
	
	private static void test_merge_simple_path_box () {
		Tool pen_tool = MainWindow.get_toolbox ().get_tool ("pen_tool");

		Tool.yield ();
		MainWindow.get_tab_bar ().select_overview ();

		Tool.yield ();
		MainWindow.get_overview ().open_current_glyph ();
		
		test_select_action (pen_tool);

		int x_offset = 10;
		int y_offset = 350;
		
		// draw it
		test_click_action (pen_tool, 1, 10 + x_offset, 10 + y_offset);
		test_click_action (pen_tool, 1, 20 + x_offset, 10 + y_offset);
		test_click_action (pen_tool, 1, 20 + x_offset, 20 + y_offset);
		test_click_action (pen_tool, 1, 10 + x_offset, 20 + y_offset); 
		test_click_action (pen_tool, 3, 0, 0);

		test_press_action (pen_tool, 1, 1, 1);
		test_move_action (pen_tool, 15 + x_offset, 15 + y_offset);
		test_release_action (pen_tool, 1, 15 + x_offset, 15 + y_offset);
				
		test_click_action (pen_tool, 1, 25 + x_offset, 15 + y_offset);
		test_click_action (pen_tool, 1, 25 + x_offset, 25 + y_offset);
		test_click_action (pen_tool, 1, 15 + x_offset, 25 + y_offset); 
		test_click_action (pen_tool, 3, 0, 0);
		
		// merge it
		Toolbox.select_tool_by_name ("union_paths");
		
		// test result
		Path merged_outline = new Path ();
		add_point_on_path (merged_outline, 10 + x_offset, 10 + y_offset);
		add_point_on_path (merged_outline, 20 + x_offset, 10 + y_offset);
		add_point_on_path (merged_outline, 20 + x_offset, 15 + y_offset);
		add_point_on_path (merged_outline, 25 + x_offset, 15 + y_offset);
		add_point_on_path (merged_outline, 25 + x_offset, 25 + y_offset);
		add_point_on_path (merged_outline, 15 + x_offset, 25 + y_offset);
		add_point_on_path (merged_outline, 15 + x_offset, 20 + y_offset);
		add_point_on_path (merged_outline, 10 + x_offset, 20 + y_offset);
		merged_outline.close ();
		
		// select path
		test_click_action (pen_tool, 3, 12 + x_offset, 12 + y_offset);
		
		Glyph g = MainWindow.get_current_glyph ();
		Path? l = g.get_active_path ();
		
		if (l == null) {
			critical ("No path found in merge test, it did not merge correctly.");
			return;
		}
		
		Path last = (!) l;
		bool merged_path_looks_good = false;
		 merged_path_looks_good = last.test_is_outline (merged_outline);
		
		if (!merged_path_looks_good) critical ("Failed to merge path correctly.");
	}

	private static void test_merge_simple_path_box_and_triangle () {
		Tool pen_tool = MainWindow.get_toolbox ().get_tool ("pen_tool");

		Tool.yield ();
		MainWindow.get_tab_bar ().select_overview ();

		Tool.yield ();
		MainWindow.get_overview ().open_current_glyph ();
		
		test_select_action (pen_tool);

		int x_offset = 40;
		int y_offset = 350;
		
		// draw it
		test_click_action (pen_tool, 1, 0 + x_offset, -50 + y_offset);
		test_click_action (pen_tool, 1, 25 + x_offset, -50 + y_offset);
		test_click_action (pen_tool, 1, 25 + x_offset, 0 + y_offset);
		test_click_action (pen_tool, 1, 0 + x_offset, 0 + y_offset); 
		test_click_action (pen_tool, 3, 0, 0);
		
		test_click_action (pen_tool, 1, 0 + x_offset, 0 + y_offset);
		test_click_action (pen_tool, 1, 50 + x_offset, -50 + y_offset);
		test_click_action (pen_tool, 1, 50 + x_offset, 0 + y_offset); 
		test_click_action (pen_tool, 3, 0, 0);

		// merge it
		Toolbox.select_tool_by_name ("union_paths");
		
		// test result
		Path merged_outline = new Path ();
		add_point_on_path (merged_outline, 0 + x_offset, -50 + y_offset);
		add_point_on_path (merged_outline, 25 + x_offset, -50 + y_offset);
		add_point_on_path (merged_outline, -50 + x_offset, -50 + y_offset);
		add_point_on_path (merged_outline, -50 + x_offset, 0 + y_offset);
		add_point_on_path (merged_outline, 0 + x_offset, 0 + y_offset);
		merged_outline.close ();

		// select path
		test_click_action (pen_tool, 3, 21 + x_offset, -11 + y_offset);
		
		Glyph g = MainWindow.get_current_glyph ();
		Path? l = g.get_active_path ();
		
		if (l == null) {
			critical ("No path found in test_merge_simple_path_box_and_triangle, it did not merge correctly.");
			return;
		}
		
		Path last = (!) l;
		bool merged_path_looks_good = false;
		 merged_path_looks_good = last.test_is_outline (merged_outline);
		
		if (!merged_path_looks_good) critical ("Failed to merge path correctly.");
	}

	private static void test_merge_second_triangle () {
		Tool pen_tool = MainWindow.get_toolbox ().get_tool ("pen_tool");

		Tool.yield ();
		MainWindow.get_tab_bar ().select_overview ();

		Tool.yield ();
		MainWindow.get_overview ().open_current_glyph ();
		
		test_select_action (pen_tool);

		int x_offset = 100;
		int y_offset = 350;
		
		// draw it
		test_click_action (pen_tool, 1, 25 + x_offset, 0 + y_offset);
		test_click_action (pen_tool, 1, 25 + x_offset, -50 + y_offset);
		test_click_action (pen_tool, 1, 0 + x_offset, -50 + y_offset);
		test_click_action (pen_tool, 1, 0 + x_offset, 0 + y_offset); 

		test_click_action (pen_tool, 3, 0, 0);
		
		test_click_action (pen_tool, 1, 40 + x_offset, -50 + y_offset);
		test_click_action (pen_tool, 1, 10 + x_offset, -20 + y_offset);
		test_click_action (pen_tool, 1, 25 + x_offset, -20 + y_offset); 
		test_click_action (pen_tool, 3, 0, 0);
		
		// merge it
		Toolbox.select_tool_by_name ("union_paths");
		
		// test result
		Path merged_outline = new Path ();
		add_point_on_path (merged_outline, 0 + x_offset, -50 + y_offset);
		add_point_on_path (merged_outline, 25 + x_offset, -50 + y_offset);
		add_point_on_path (merged_outline, -50 + x_offset, -50 + y_offset);
		add_point_on_path (merged_outline, -50 + x_offset, 0 + y_offset);
		add_point_on_path (merged_outline, 0 + x_offset, 0 + y_offset);
		merged_outline.close ();

		// select path
		test_click_action (pen_tool, 3, 21 + x_offset, -11 + y_offset);
		
		Glyph g = MainWindow.get_current_glyph ();
		Path? l = g.get_active_path ();
		
		if (l == null) {
			critical ("No path found in triangle_right, it did not merge correctly.");
			return;
		}
		
		Path last = (!) l;
		bool merged_path_looks_good = false;
		 merged_path_looks_good = last.test_is_outline (merged_outline);
		
		if (!merged_path_looks_good) critical ("Failed to merge path correctly.");
	}
	
	private static void add_point_on_path (Path p, int x, int y) {
		p.add (Glyph.path_coordinate_x (x), Glyph.path_coordinate_y (y));
	}
	
	private static void test_boundaries () {
		Preferences.draw_boundaries = true;
	}
}

}
