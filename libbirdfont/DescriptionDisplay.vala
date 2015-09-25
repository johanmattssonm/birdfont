/*
    Copyright (C) 2014 2015 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

using Cairo;
using Math;

namespace BirdFont {

public class DescriptionDisplay : TableLayout {
	TextArea postscript_name;
	TextArea name;
	TextArea style;
	CheckBox bold;
	CheckBox italic;
	TextArea weight;
	TextArea full_name;
	TextArea unique_id;
	TextArea version;
	TextArea description;
	TextArea copyright;
	TextArea license;
	LineTextArea license_url;
	TextArea trademark;
	LineTextArea manufacturer;
	LineTextArea designer;
	LineTextArea vendor_url;
	LineTextArea designer_url;
	
	private static bool disable_copyright = false;
	
	public DescriptionDisplay () {
		double margin = 12 * MainWindow.units;
		double label_size = 20 * MainWindow.units;
		double label_margin = 4 * MainWindow.units;
		Headline headline;
		Font font = BirdFont.get_current_font ();
		
		postscript_name = new LineTextArea (label_size);
		name = new LineTextArea (label_size);
		style = new LineTextArea (label_size);
		weight = new LineTextArea (label_size);
		full_name = new LineTextArea (label_size);
		unique_id = new LineTextArea (label_size);
		version = new LineTextArea (label_size);
		description = new TextArea (label_size);
		copyright = new TextArea (label_size);
		license = new TextArea (label_size);
		license_url = new LineTextArea (label_size);
		trademark = new TextArea (label_size);
		manufacturer = new LineTextArea (label_size);
		designer = new LineTextArea (label_size);
		vendor_url = new LineTextArea (label_size);
		designer_url = new LineTextArea (label_size);
	
		headline = new Headline (t_("Name and Description"));
		headline.margin_bottom = 20 * MainWindow.units;
		widgets.add (headline);

		widgets.add (new Text (t_("PostScript Name"), label_size, label_margin));
		postscript_name.margin_bottom = margin;
		postscript_name.set_text (font.postscript_name);
		postscript_name.text_changed.connect ((t) => {
			font.postscript_name = t;
			font.touch ();
		});
		widgets.add (postscript_name);
		focus_ring.add (postscript_name);
		
		widgets.add (new Text (t_("Name"), label_size, label_margin));
		name.margin_bottom = margin;
		name.set_text (font.name);
		name.text_changed.connect ((t) => {
			font.name = t;
			font.touch ();
		});
		widgets.add (name);
		focus_ring.add (name);
		
		widgets.add (new Text (t_("Style"), label_size, label_margin));
		style.margin_bottom = 1.5 * margin;
		style.set_text (font.subfamily);
		style.text_changed.connect ((t) => {
			font.subfamily = t;
			font.touch ();
		});
		widgets.add (style);
		focus_ring.add (style);
		
		bold = new CheckBox (t_("Bold"), label_size);
		bold.updated.connect ((c) => {
			font.bold = c;
			font.touch ();
		});
		bold.checked = font.bold;
		widgets.add (bold);
		focus_ring.add (bold);
		
		italic = new CheckBox (t_("Italic"), label_size);
		italic.updated.connect ((c) => {
			font.italic = c;
			font.touch ();
		});
		italic.checked = font.italic;
		italic.margin_bottom = margin;
		widgets.add (italic);
		focus_ring.add (italic);
		
		widgets.add (new Text (t_("Weight"), label_size, label_margin));
		weight.margin_bottom = margin;
		weight.set_text (font.get_weight ());
		weight.text_changed.connect ((t) => {
			font.set_weight (t);
			font.touch ();
		});
		widgets.add (weight);
		focus_ring.add (weight);
		
		widgets.add (new Text (t_("Full Name (Name and Style)"), label_size, label_margin));
		full_name.margin_bottom = margin;
		full_name.set_text (font.full_name);
		full_name.text_changed.connect ((t) => {
			font.full_name = t;
			font.touch ();
			MainWindow.get_toolbox ().update_all_expanders ();
		});
		widgets.add (full_name);
		focus_ring.add (full_name);
		
		widgets.add (new Text (t_("Unique Identifier"), label_size, label_margin));
		unique_id.margin_bottom = margin;
		unique_id.set_text (font.unique_identifier);
		unique_id.text_changed.connect ((t) => {
			font.unique_identifier = t;
			font.touch ();
		});
		widgets.add (unique_id);
		focus_ring.add (unique_id);
		
		widgets.add (new Text (t_("Version"), label_size, label_margin));
		version.margin_bottom = margin;
		version.set_text (font.version);
		version.text_changed.connect ((t) => {
			font.version = t;
			font.touch ();
		});
		widgets.add (version);
		focus_ring.add (version);

		widgets.add (new Text (t_("Description"), label_size, label_margin));
		description.margin_bottom = margin;
		description.set_text (font.description);
		description.scroll.connect (scroll_event);
		description.text_changed.connect ((t) => {
			font.description = t;
			font.touch ();
		});
		widgets.add (description);
		focus_ring.add (description);
		
		widgets.add (new Text (t_("Copyright"), label_size, label_margin));
		copyright.margin_bottom = margin;
		copyright.set_text (font.copyright);
		copyright.scroll.connect (scroll_event);
		copyright.text_changed.connect ((t) => {
			font.copyright = t;
			font.touch ();
		});
		copyright.set_editable (!disable_copyright);
		widgets.add (copyright);
		focus_ring.add (copyright);

		widgets.add (new Text (t_("License"), label_size, label_margin));
		license.margin_bottom = margin;
		license.set_text (font.license);
		license.scroll.connect (scroll_event);
		license.text_changed.connect ((t) => {
			font.license = t;
			font.touch ();
		});
		license.set_editable (!disable_copyright);
		widgets.add (license);
		focus_ring.add (license);

		widgets.add (new Text (t_("License URL"), label_size, label_margin));
		license_url.margin_bottom = margin;
		license_url.set_text (font.license_url);
		license_url.scroll.connect (scroll_event);
		license_url.text_changed.connect ((t) => {
			font.license_url = t;
			font.touch ();
		});
		license_url.set_editable (!disable_copyright);
		widgets.add (license_url);
		focus_ring.add (license_url);

		widgets.add (new Text (t_("Trademark"), label_size, label_margin));
		trademark.margin_bottom = margin;
		trademark.set_text (font.trademark);
		trademark.scroll.connect (scroll_event);
		trademark.text_changed.connect ((t) => {
			font.trademark = t;
			font.touch ();
		});
		trademark.set_editable (!disable_copyright);
		widgets.add (trademark);
		focus_ring.add (trademark);

		widgets.add (new Text (t_("Manufakturer"), label_size, label_margin));
		manufacturer.margin_bottom = margin;
		manufacturer.set_text (font.manufacturer);
		manufacturer.scroll.connect (scroll_event);
		manufacturer.text_changed.connect ((t) => {
			font.manufacturer = t;
			font.touch ();
		});
		widgets.add (manufacturer);
		focus_ring.add (manufacturer);

		widgets.add (new Text (t_("Designer"), label_size, label_margin));
		designer.margin_bottom = margin;
		designer.set_text (font.designer);
		designer.scroll.connect (scroll_event);
		designer.text_changed.connect ((t) => {
			font.designer = t;
			font.touch ();
		});
		widgets.add (designer);
		focus_ring.add (designer);

		widgets.add (new Text (t_("Vendor URL"), label_size, label_margin));
		vendor_url.margin_bottom = margin;
		vendor_url.set_text (font.vendor_url);
		vendor_url.scroll.connect (scroll_event);
		vendor_url.text_changed.connect ((t) => {
			font.vendor_url = t;
			font.touch ();
		});
		widgets.add (vendor_url);
		focus_ring.add (vendor_url);

		widgets.add (new Text (t_("Designer URL"), label_size, label_margin));
		designer_url.margin_bottom = margin;
		designer_url.set_text (font.designer_url);
		designer_url.scroll.connect (scroll_event);
		designer_url.text_changed.connect ((t) => {
			font.designer_url = t;
			font.touch ();
		});
		widgets.add (designer_url);
		focus_ring.add (designer_url);
				
		set_focus (postscript_name);
		
		foreach (Widget w in widgets) {
			if (w is Text) {
				Theme.text_color ((Text) w, "Text Foreground");
			}
		}
	}

	public static void set_copyright_editable (bool t) {
		disable_copyright = !t;
	}

	public override string get_label () {
		return t_("Name and Description");
	}

	public override string get_name () {
		return "Description";
	}
	
	public override void selected_canvas () {
		copyright.set_editable (!disable_copyright);
		base.selected_canvas ();
	}
}

}
