/*
    Copyright (C) 2012 Johan Mattsson

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

namespace BirdFont {

/** Javascripts in webkit do use this callback. */
public class PropertyFunction {
	public delegate void PropertyCallback (string val);
	public PropertyCallback call;
}

public abstract class FontDisplay : GLib.Object {
	
	List<string> property = new List<string> ();
	List<PropertyFunction> call = new List<PropertyFunction> ();
	
	/** Queue redraw area */
	public signal void redraw_area (double x, double y, double w, double h);
	
	/** Name of symbol or set of symbols in display selections like the tab panel. */
	public virtual string get_name () {
		return "";
	}
	
	public virtual bool has_scrollbar () {
		return false;
	}
	
	public virtual void scroll_to (double percent) {
	}
	
	public virtual bool is_html_canvas () {
		return false;
	}

	public static string path_to_uri (string path) {
		string uri = path;
		string wp;
		
		// wine uri hack
		if (BirdFont.win32) {
			wp = wine_to_unix_path (uri);
			
			if (find_file (wp, "").query_exists ()) {
				uri = wp;
			}

			if (uri.index_of ("\\") > -1) {
				uri = uri.replace ("\\", "/");
			}
		}

		if (uri.index_of ("/") == 0) {
			uri = @"file://$uri";
		} else {
			uri = @"file:///$uri";
		}
		
		return uri;
	}

	public virtual string get_uri () {
		return "";
	}
	
	public virtual string get_html_file () {
		return "index.html";
	}
	
	public virtual string get_html () {
		return "";
	}
	
	public virtual void draw (Allocation allocation, Context cr) {
	}
	
	public virtual void selected_canvas () {
	}
	
	public virtual void key_press (uint keyval) {
	}
	
	public virtual void key_release (uint keyval) {
	}
	
	public virtual void motion_notify (double x, double y) {
	}
	
	public virtual void button_release (int button, double x, double y) {
	}
	
	public virtual void button_press (uint button, double x, double y) {
	}

	public virtual void double_click (uint button, double ex, double ey) {
	}	

	public virtual void zoom_in () {
	}
	
	public virtual void zoom_out () {
	}
	
	public virtual void zoom_max () {
	}
	
	public virtual void zoom_min () {
	}
	
	public virtual void reset_zoom () {
	}
	
	public virtual void store_current_view () {
		warning ("store_current_view not implemented for this class.");
	}
	
	public virtual void restore_last_view () {
		warning ("restore_last_view not implemented for this class.");
	}

	public virtual void next_view () {
		warning ("next_view not implemented for this class.");
	}
	
	public virtual void scroll_wheel_up (double x, double y) {
	}
	
	public virtual void scroll_wheel_down (double x, double y) {
	}

	public virtual void undo () {
	}

	public static File find_layout_dir () {
		File f = find_file (null, "layout");
		return f;		
	}

	public void add_html_callback (string prop, PropertyFunction.PropertyCallback cb) {
		PropertyFunction pf = new PropertyFunction ();
		pf.call = cb;
		property.append (prop);
		call.append (pf);
	}
	
	public void process_property (string prop) {
		string k, v;
		int i, j;
		PropertyFunction cb;
		
		if (prop == "" || prop == "done") {
			return;
		}
		
		i = prop.index_of (":");
		
		if (i <= 0) {
			return;
		}
		
		k = prop.substring (0, i);
		v = prop.substring (i + 1);
		
		j = 0;
		
		foreach (string p in property) {
			if (p == k) {
				break;
			}
			j++;
		}
		
		if (j >= property.length ()) {
			warning (@"key  \"$k\" not found in property list, value: $v");
			return;
		}
		
		cb = call.nth (j).data;
		cb.call (v);
	}

	public static File find_file (string? dir, string name) {
		return SearchPaths.find_file (dir, name);	
	}
}

}
