/*
	Copyright (C) 2016 Johan Mattsson

	This library is free software; you can redistribute it and/or modify 
	it under the terms of the GNU Lesser General Public License as 
	published by the Free Software Foundation; either version 3 of the 
	License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful, but 
	WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
	Lesser General Public License for more details.
*/

using B;
using SvgBird;
using Gee;
using Cairo;

namespace Bird {

class SvgComponent : Component {
	string? path = null;
	string file_name = "";
	SvgDrawing? drawing = null;
	
	public SvgComponent (XmlElement svg_component_tag, Defs defs, string svg_file) {
		base.embedded (svg_component_tag, defs);
		load_svg (svg_file);
	}

	public SvgComponent.for_file (string svg_file) {
		base.embedded (new XmlElement.empty (), new Defs ());
		load_svg (svg_file);
	}

	public override void layout () {
		if (unlikely (components.size > 0)) {
			warning ("SVG files can not have subviews.");
		}
		
		if (drawing != null) {
			SvgDrawing svg = (!) drawing;
			width = svg.width;
			height = svg.height;
		}
	}
			
	public override string to_string () {
		return "Svg: " + file_name;
	}

	private void load_svg (string file_name) {
		this.file_name = file_name;
		path = find_file (file_name);
		
		if (path == null) {
			warning (file_name + " not found.");
			return;
		}
				
		string xml_data;
		File svg_file = File.new_for_path ((!) path); 
		try {
			FileUtils.get_contents((!) svg_file.get_path (), out xml_data);
		} catch (GLib.Error error) {
			warning (error.message);
			return;
		}
		
		SvgFile svg_parser = new SvgFile ();
		drawing = svg_parser.parse_svg_data (xml_data);
	}

	public override void draw (Context cairo) {
		if (drawing != null) {
			SvgDrawing svg = (!) drawing;
			svg.draw (cairo);
		}
	}

}

}

