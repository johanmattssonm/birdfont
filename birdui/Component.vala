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

public abstract class Component : GLib.Object {
	public double width { get; protected set; }
	public double height { get; protected set; }
	
	public double padded_width {
		get {
			return width + get_padding_left () + get_padding_right ();
		}
	}
	
	public double padded_height { 
		get {
			return height + get_padding_top () + get_padding_bottom ();
		}
	}

	public double padded_x {
		get {
			return x + get_padding_left ();
		}
	}
	
	public double padded_y { 
		get {
			return y + get_padding_top ();
		}
	}
	
	/** Vertical placement for this component relative to the parent container. */
	public double x { get; protected set; }
	
	/** Horizontal placement for this component relative to the parent container. */
	public double y { get; protected set; }

	/** The parts this component is made of. */
	protected ArrayList<Component> components = new ArrayList<Component> ();

	XmlElement component_tag;
	
	/** Style sheet and other SVG definitions. */
	Defs defs = new Defs ();
	protected SvgStyle style = new SvgStyle ();

	public string? css_class = null;
	public string? id = null;

	Overflow overflow = Overflow.VISIBLE;

	public Component.load (string file_name, double width, double height) {
		this.width = width;
		this.height = height;
		load_file (file_name, null);
		layout (width, height);
	}

	/** Parse component ui file but don't do layout. */
	internal Component.load_component (string file_name, Component parent) {
		load_file (file_name, parent);
	}
	
	public Component (XmlElement component_tag, Defs defs) {
		this.defs = defs;
		this.component_tag = component_tag;
		set_identification ();
		parse (component_tag);
	}

	public Component.embedded (XmlElement component_tag, Defs defs) {
		this.defs = defs;
		this.component_tag = component_tag;
		set_identification ();
	}

	void set_identification () {
		foreach (Attribute attribute in component_tag.get_attributes ()) {
			string attribute_name = attribute.get_name ();
			
			if (attribute_name == "id") {
				id = attribute.get_content ();
			} else if (attribute_name == "class") {
				css_class = attribute.get_content ();
			}
		}
	}

	private void inherit_styles_sheet (Defs defs) {
		this.defs = defs;
	}

	protected void parse_style (XmlElement style_tag) {
		defs = defs.shallow_copy ();
		StyleSheet style_sheet = StyleSheet.parse (defs, style_tag);
		defs.style_sheet.merge (style_sheet);
	}
	
	protected void parse_svg (XmlElement svg_tag) {
		foreach (Attribute attribute in svg_tag.get_attributes ()) {
			string attribute_name = attribute.get_name ();
			
			if (attribute_name == "file") {
				string file_name = attribute.get_content ();
				SvgComponent svg = new SvgComponent (svg_tag, defs, file_name);
				add_component (svg);	
			}
		}
	}

	protected void add_component (Component component) {
		components.add (component);
		component.set_style_properties (this);
	}

	protected void set_style_properties (Component parent) {
		inherit_styles_sheet (parent.defs);
		style = SvgStyle.parse (parent.defs, parent.style, component_tag);		
		set_overflow_property_from_css ();
		set_identification ();
	}
	
	protected void set_overflow_property_from_css () {
		string? css_overflow = style.get_css_property ("overflow");
		
		if (css_overflow != null) {
			string overflow_property = (!) css_overflow;
			
			if (overflow_property == "hidden") {
				overflow = Overflow.HIDDEN;
			} else if (overflow_property == "visible") {
				overflow = Overflow.VISIBLE;
			}
		}
	}

	protected void parse_layout (XmlElement layout_tag) {
		string type = "";
		
		foreach (Attribute attribute in layout_tag.get_attributes ()) {
			string attribute_name = attribute.get_name ();
			
			if (attribute_name == "type") {
				type = attribute.get_content ();				
			}
		}
		
		if (type == "hbox") {
			HBox hbox = new HBox (layout_tag, defs);
			add_component (hbox);
		} else if (type == "vbox") {
			VBox vbox = new VBox (layout_tag, defs);
			add_component (vbox);
		} else {
			warning (type + " layout of type is supported in this verison.");
		}
	}
	
	protected void parse_component (XmlElement component_tag) {
		foreach (Attribute attribute in component_tag.get_attributes ()) {
			string attribute_name = attribute.get_name ();
			
			if (attribute_name == "file") {
				string file_name = attribute.get_content ();
				UI ui = new UI.load_component (file_name, this);
				
				foreach (Component component in ui.components) {
					add_component (component);
					
					SvgStyle copied_style;
					copied_style = SvgStyle.parse (defs, style, component_tag);		
					copied_style.apply (component.style);
					component.style = copied_style;
				}
			}
		}
	}
	
	protected void parse (XmlElement component_tag) {
		foreach (XmlElement tag in component_tag) {
			string tag_name = tag.get_name ();
			
			if (tag_name == "ui") {
				parse (tag);
			} else if (tag_name == "layout") {
				parse_layout (tag);
			} else if (tag_name == "component") {
				parse_component (tag);
			} else if (tag_name == "svg") {
				parse_svg (tag);
			} else if (tag_name == "style") {
				parse_style (tag);
			} else {
				unused_tag (tag_name);
			}
		}
	}

	internal void unused_attribute (string attribute) {
		warning ("The attribute " + attribute + " is not known in this version.");
	}
	
	internal void unused_tag (string tag_name) {
		warning ("The tag " + tag_name + " is not known in this version.");
	}

	public void load_file (string file_name, Component? parent) {
		if (file_name.has_suffix (".ui")) {
			load_layout (file_name, parent);
		} else if (file_name.has_suffix (".svg")) {
			SvgComponent svg = new SvgComponent.for_file (file_name);
			add_component (svg);	
		} else {
			warning (file_name + " is not a ui file or svg file.");
		}
	}

	public void load_layout (string file_name, Component? parent) {
		string? path = find_file (file_name);
		
		if (path == null) {
			warning (file_name + " not found.");
			return;
		}
		
		string xml_data;
		File layout_file = File.new_for_path ((!) path); 
		
		try {
			FileUtils.get_contents((!) layout_file.get_path (), out xml_data);
		} catch (GLib.Error error) {
			warning (error.message);
			return;
		}

		XmlTree xml_parser = new XmlTree (xml_data);		
		XmlElement tag = xml_parser.get_root ();
		
		if (parent == null) {
			component_tag = tag;
			defs = new Defs ();
		} else {
			Component p = (!) parent;
			component_tag = p.component_tag;
			defs = p.defs;
		}
		
		parse (tag);
	}
	
	public static string find_file (string file_name) {
		File file = File.new_for_path ("birdui/" + file_name);
		
		if (file.query_exists ()) {
			return (!) file.get_path ();
		}
		
		return file_name;
	}
	
	public virtual void get_min_size (out double min_width, out double min_height) {
		min_width = width;
		min_height = height;
		
		if (unlikely (components.size > 1)) {
			warning ("A component has several parts but no layout has been set.");
		}
		
		foreach (Component component in components) {
			component.get_min_size (out min_width, out min_height);
		}

		min_width += get_padding_left ();
		min_width += get_padding_right ();
		min_height += get_padding_top ();
		min_height += get_padding_bottom ();
	}
	
	public virtual void layout (double parent_width, double parent_height) {
		warning ("A component without a layout was added to the view.");

		double w, h;
		get_min_size (out w, out h);

		width = w;
		height = h;
		
		foreach (Component component in components) {
			component.layout (parent_width, parent_height);
		}
	}
	
	public void clip (Context cairo) {
		if (overflow == Overflow.HIDDEN) {
			cairo.rectangle (0, 0, width, height);
			cairo.clip ();
		}
	}
	
	public abstract void draw (Context cairo);
	
	public virtual void motion_notify_event (double x, double y) {	
	}
	
	public virtual void button_press_event (uint button, double x, double y) {	
	}
	
	public virtual string to_string () {
		return @"$(component_tag.get_name ())";
	}
	
	public void print_tree () {
		print_tree_level (0);
	}

	protected void print_tree_level (int indent) {
		for (int i = 0; i < indent; i++) {
			print ("\t");
		}
		
		print (@"$(to_string ()) width: $padded_width, height: $padded_height x $x y $y $(style)\n");
		
		foreach (Component component in components) {
			component.print_tree_level (indent + 1);
		}
	}
	
	protected double get_padding_bottom () {
		return SvgFile.parse_number (style.get_css_property ("padding-bottom"));
	}

	protected double get_padding_top () {
		return SvgFile.parse_number (style.get_css_property ("padding-top"));
	}

	protected double get_padding_left () {
		return SvgFile.parse_number (style.get_css_property ("padding-left"));
	}

	protected double get_padding_right () {
		return SvgFile.parse_number (style.get_css_property ("padding-right"));
	}

	protected void limit_size (ref double width, ref double height) {
		string? min_width = style.get_css_property ("min-width");
		if (min_width != null) {
			double w = SvgFile.parse_number (min_width);
			if (width < w) {
				width = w;
			}
		}

		string? min_height = style.get_css_property ("min-height");
		if (min_height != null) {
			double h = SvgFile.parse_number (min_height);
			
			if (height < h) {
				height = h;
			}
		}
		
		string? max_width = style.get_css_property ("max-width");
		if (max_width != null) {
			double w = SvgFile.parse_number (max_width);
			
			if (width > w) {
				width = w;
			}
		}

		string? max_height = style.get_css_property ("max-height");
		if (max_height != null) {
			double h = SvgFile.parse_number (max_height);
			
			if (height > h) {
				height = h;
			}
		}
		
		if (width < 0) {
			width = 0;
		}

		if (height < 0) {
			height = 0;
		}
	}
}

}

