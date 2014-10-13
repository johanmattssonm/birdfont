/*
    Copyright (C) 2014 Johan Mattsson

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

public class Row : GLib.Object {

	int index = 0;
	bool delete_button = true;
	Gee.ArrayList<string> columns_labels = new Gee.ArrayList<string> ();
	GLib.Object? row_data = null;
	
	public int columns {
		get {
			return columns_labels.size;
		}
	}
	
	public Row (string label, int index, bool delete_button = true) {
		this.index = index;
		columns_labels.add (label);
		this.delete_button = delete_button;
	}

	public Row.columns_2 (string label0, string label1, int index,
		bool delete_button = true) {
			
		columns_labels.add (label0);
		columns_labels.add (label1);
		this.index = index;
		this.delete_button = delete_button;
	}
		
	public Row.columns_3 (string label0, string label1, string label2,
		int index, bool delete_button = true) {
			
		columns_labels.add (label0);
		columns_labels.add (label1);
		columns_labels.add (label2);
		this.index = index;
		this.delete_button = delete_button;
	}

	public Row.columns_4 (string label0, string label1, string label2, 
		string label3, int index, bool delete_button = true) {
			
		columns_labels.add (label0);
		columns_labels.add (label1);
		columns_labels.add (label2);
		columns_labels.add (label3);
		this.index = index;
		this.delete_button = delete_button;
	}
	
	public Row.columns_5 (string label0, string label1, string label2,
		string label3, string label4, int index, bool delete_button = true) {
			
		columns_labels.add (label0);
		columns_labels.add (label1);
		columns_labels.add (label2);
		columns_labels.add (label3);
		columns_labels.add (label4);
		this.index = index;
		this.delete_button = delete_button;
	}

	public bool has_row_data () {
		return row_data != null;
	}

	public GLib.Object? get_row_data () {
		return row_data;
	}

	public void set_row_data (GLib.Object o) {
		row_data = o;
	}
	
	public bool has_delete_button () {
		return delete_button;
	}
	
	public string get_column (int i) {
		return_val_if_fail (0 <= i < columns, "".dup ());
		return columns_labels.get (i);
	}

	public int get_index () {
		return index;
	}

	public void set_index (int index) {	
		this.index = index;
	}
}

}
