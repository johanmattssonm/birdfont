/*
    Copyright (C) 2012, 2013 Johan Mattsson

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

namespace Supplement {

/** All the things we want to test listed is here. */
class TestCases {
	
	public List<Test> test_cases;

	public TestCases () {
		add (test_overview, "Overview");
		add (test_data_reader, "Font data reader");
		add (test_argument, "Argument list");
		add (test_glyph_ranges, "Glyph ranges");
		add (test_glyph_table, "Glyph table");
		add (test_active_edit_point, "Active edit point");
		add (test_hex, "Unicode hex values");
		add (test_reverse_path, "Reverse path");
		add (test_reverse_random_paths, "Reverse random paths");
		add (test_coordinates, "Coordinates");
		add (test_drawing, "Pen tool");
		add (test_delete_points, "Delete edit points");
		add (test_convert_to_quadratic_bezier_path, "Convert to quadratic path");
		add (test_notdef, "Notdef");
		add (test_merge, "Merge");
		add (test_over_path, "Over path");
		add (test_preview, "Preview");
		add (test_export, "Export");
		add (test_background_coordinates, "Background coordinates");
		add (test_spin_button, "Spin button");
		add (test_inkscape_import, "Inkscape import");
		add (test_illustrator_import, "Illustrator import");
		add (test_parse_quadratic_paths, "Quadratic paths");
	}

	public static void test_parse_quadratic_paths () {
		Glyph g;
		Tool.test_open_next_glyph ();
		g = MainWindow.get_current_glyph ();
		ImportSvg.parse_svg_data ("M20,300 Q400,50 600,300 T1000,300Q1200 50 1400 300Q1600 50 1800 600 L 1800 700 L 200 700 z", g);
		Toolbox.select_tool_by_name ("full_glyph");
		
		g = MainWindow.get_current_glyph ();
		ImportSvg.parse_svg_data ("M300 400 h-200 l0 1000 h200z", g, true);
		Toolbox.select_tool_by_name ("full_glyph");
	}

	public static void test_illustrator_import () {
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
			
			temp_file = Supplement.get_settings_directory ().get_child ("illustrator_test.svg");
			
			if (temp_file.query_exists ()) {
				temp_file.delete ();
			}
			
			ios = temp_file.create_readwrite (FileCreateFlags.PRIVATE);
			os = ((!) ios).output_stream as FileOutputStream?;
			d = new DataOutputStream ((!) os);
			
			d.put_string (illustrator_data);
			d.close ();
			
			Tool.test_open_next_glyph ();
			ImportSvg.import_svg ((!) temp_file.get_path ());

			temp_file.delete ();
			
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
			
			temp_file = Supplement.get_settings_directory ().get_child ("inkscape_test.svg");
			
			if (temp_file.query_exists ()) {
				temp_file.delete ();
			}
			
			ios = temp_file.create_readwrite (FileCreateFlags.PRIVATE);
			os = ((!) ios).output_stream as FileOutputStream?;
			d = new DataOutputStream ((!) os);
			
			d.put_string (inkscape_data);
			d.close ();
			
			Tool.test_open_next_glyph ();
			ImportSvg.import_svg ((!) temp_file.get_path ());

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
		
		Tool.test_open_next_glyph ();
		g = MainWindow.get_current_glyph ();
				
		p.add (-10, -10);
		p.add (50, 50);
		p.add (10, -10);
		
		p.close ();
		g.add_path (p);	

		MenuTab.preview ();

		// TODO: run this many times on big font
		for (int i = 0; i < 10; i++) {
			ExportTool.export_all ();
			Tool.yield ();
		}		
	}


	public static void test_preview () {
		Glyph g;
		Path p = new Path ();
		
		Tool.test_open_next_glyph ();
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
			MainWindow.get_tab_bar ().select_tab_name ("Menu");
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
		pen_tool.test_select_action ();
		Tool.test_open_next_glyph ();
		
		g = MainWindow.get_current_glyph ();

		pen_tool.test_click_action (3, 10, 10);
		pen_tool.test_click_action (3, 10, 10);
		pen_tool.test_click_action (3, 100, 10);
		pen_tool.test_click_action (3, 100, 100);
		pen_tool.test_click_action (3, 10, 100);
		pen_tool.test_click_action (2, 0, 0);

		g.close_path ();

		warn_if_fail (g.active_paths.length () == 0);

		g.select_path (50, 50);

		warn_if_fail (g.active_paths.length () == 1);
		
		p.add (-10, 10);
		p.add (10, 10);
		p.add (10, -10);
		p.add (-10, -10);
		p.update_region_boundries ();
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
		
		Tool.test_open_next_glyph ();
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
	}

	public static void test_notdef () {
		Font f = Supplement.get_current_font ();
		Glyph n = f.get_not_def_character ();
		Glyph g;
		Path pn;
		
		f.add_glyph (n);
		
		Tool.test_open_next_glyph ();
		g = MainWindow.get_current_glyph ();
		foreach (Path p in n.path_list) {
			pn = p.copy ().get_quadratic_points ();
			g.path_list.append (pn);
			pn.move (50, 0);
			g.path_list.append (p.copy ());
		}
	}

	public static void test_convert_to_quadratic_bezier_path () {
		Glyph g;
		Path gqp;
		Path gqp_points;
		
		Path p = new Path ();
		Path p1 = new Path ();
		List<Path> qpl = new List<Path> (); 
		
		EditPoint e0, e1, e2, e3;
		
		g = MainWindow.get_current_glyph ();
		
		// split_all_cubic_in_half
		foreach (Path gp in g.path_list) {
			gqp_points = gp.copy ();
			gqp_points.split_cubic_in_parts (gqp_points);
			gqp_points.move (50, 0);
			qpl.append (gqp_points);
		}
		
		// convert to quadratic points
		foreach (Path gp in g.path_list) {
			gqp = gp.get_quadratic_points ();
			gqp.move (100, 0);
			qpl.append (gqp);
		}

		foreach (Path gp in qpl) {
			g.add_path (gp);
		}

		Tool.test_open_next_glyph ();
		
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
		
		gr.add_range ('b', 'c');
		gr.add_single ('d');
		gr.add_range ('e', 'h');
		gr.add_range ('k', 'm');
		gr.add_range ('o', 'u');
		gr.add_range ('a', 'd');
		gr.add_range ('f', 'z');
		gr.add_range ('b', 'd');
			
		return_if_fail (gr.length () == 'z' - 'a' + 1);
		return_if_fail (gr.get_ranges ().length () == 1);
		return_if_fail (gr.get_ranges ().first ().data.length () == 'z' - 'a' + 1);
		
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
	}

	public static void test_glyph_table () {
		GlyphTable table = new GlyphTable ();
		List<GlyphCollection> gc = new List<GlyphCollection> ();
		List<unowned GlyphCollection> gc_copy;
		GlyphCollection g;
		
		return_if_fail (table.length () == 0);
		return_if_fail (table.get ("Some glyph") == null);
		
		// generate test data
		for (uint i = 0; i < 1000; i++) {
			gc.append (new GlyphCollection (new Glyph (@"TEST $i", i + 'a')));
		}

		// insert in random order
		gc_copy = gc.copy ();
		for (uint i = 0; gc_copy.length () > 0; i++) {
			int t = (int) ((gc_copy.length () - 1) * Random.next_double ());
			g = gc_copy.nth (t).data;
			
			if (!table.insert (g)) {
				warning (@"Failed to insert $(g.get_name ())");
				return;
			}
			
			gc_copy.remove_all (g);
			
			if (!table.validate_index ()) {
				table.print_all ();
				warning ("index is invalid");
				return;
			}
		}
		
		return_if_fail (table.length () == gc.length ());
		
		// validate table
		for (uint i = 0; i > 1000; i++) {
			g = (!) table.get (gc.nth (i).data.get_name ());
			return_if_fail (gc.nth (i).data == g);
		}
		
		// search 
		for (int i = 0; i < 2000; i++) {
			int t = (int) (999 * Random.next_double ());
			if (table.get (@"TEST $t") == null) {
				table.print_all ();
				warning (@"Did't find TEST $t in glyph table.");
				return;
			}
		}

		// remove
		table.remove ("TEST 0");
		table.remove ("TEST 53");
		return_if_fail (table.get ("TEST 0") == null);
		return_if_fail (table.get ("TEST 53") == null);
		
		// search 
		return_if_fail (table.get ("TEST 52") != null);
		return_if_fail (table.get ("TEST 54") != null);
	}

	public static void test_delete_points () {
		PenTool tool = (PenTool) MainWindow.get_toolbox ().get_tool ("pen_tool");
		tool.test_delete_points ();
	}

	public static void test_active_edit_point () {
		PenTool tool = (PenTool) MainWindow.get_toolbox ().get_tool ("pen_tool");
		tool.test_active_edit_point ();
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

	public static void test_coordinates () {
		PenTool tool = (PenTool) MainWindow.get_toolbox ().get_tool ("pen_tool");
		tool.test_coordinates ();		
	}

	public static void test_reverse_random_paths () {
		PenTool tool = (PenTool) MainWindow.get_toolbox ().get_tool ("pen_tool");
		tool.test_reverse_random_triangles ();		
	}

	public static void test_reverse_path () {
		PenTool tool = (PenTool) MainWindow.get_toolbox ().get_tool ("pen_tool");
		tool.test_reverse_path ();
	}

	public static void test_drawing () {
		Tool tool = MainWindow.get_toolbox ().get_tool ("pen_tool");
		tool.test ();
	}
		
	private void add (Callback callback, string name) {
		test_cases.append (new Test (callback, name));
	}
	
	public unowned List<Test> get_test_functions () {
		return test_cases;
	}
}	
	
}
