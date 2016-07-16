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

using Cairo;
using Math;

extern class svg_bird_font_item {}
extern void svg_bird_draw_text (Context cr, svg_bird_font_item* font, string text);

extern void svg_bird_font_item_delete (svg_bird_font_item* item);
extern svg_bird_font_item svg_bird_font_item_create (string font_file, int font_size);

namespace SvgBird {

public class Text : Object {
	public string font_family = "";
	public int font_size = 12;
	public double x = 0;
	public double y = 0;
	public string content;
	
	svg_bird_font_item* font;
	
	public Text () {
		font = svg_bird_font_item_create ("resources/Roboto-Regular.ttf", 34);
	}

	~Text () {
		svg_bird_font_item_delete (font);
	}

	public void set_text (string t) {
		content = t.replace ("\n", " ");
		content = content.replace ("\t", " ");
		
		while (content.index_of ("  ") > -1) {
			content = content.replace ("  ", " ");
		}
		
		content = content.strip ();
	}

	public Text.create_copy (Text c) {
		Object.copy_attributes (c, this);
		font_family = c.font_family;
		x = c.x;
		y = c.y;
		font_size = c.font_size;
	}
	
	public override void draw_outline (Context cr) {
		cr.save ();
		cr.translate (x, y);
		svg_bird_draw_text (cr, font, content);
		cr.restore ();
	}

	public override bool is_empty () {
		return false;
	}
	
	public override Object copy () {
		return new Text.create_copy (this);
	}

	public override string to_string () {
		return "Text";
	}
}

}
