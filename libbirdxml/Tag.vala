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

namespace Bird {

public class Tag : GLib.Object {
	
	int tag_index; 
	int attribute_index;
	
	bool has_tags;
	bool has_attributes;
	
	string name;
	string data;
	string attributes;
	
	Tag? next_tag = null;
	Attribute? next_attribute = null;
	
	internal Tag (string name, string attributes, string content) {
		this.name = name;
		this.data = content;
		this.attributes = attributes;
		reparse ();
	}
	
	internal Tag.empty () {
		data = "";
		attributes = "";
		name = "";
	}

	/** Reset the parser and start from the beginning XML tag. */
	public void reparse () {
		tag_index = 0;
		attribute_index = 0;
		next_tag = obtain_next_tag ();
		next_attribute = obtain_next_attribute ();
	}

	/** @return the name of this tag. */
	public string get_name () {
		return name;
	}

	/** @return data between the starty and end tag. */
	public string get_content () {
		return data;
	}

	/** @return true if there is one more tags left */
	public bool has_more_tags () {
		return has_tags;
	}
	
	/** @return the next tag. **/
	public Tag get_next_tag () {
		Tag r = next_tag == null ? new Tag.empty () : (!) next_tag;
		next_tag = obtain_next_tag ();
		return r;
	}

	/** @return true is there is one or more attributes to obtain with get_next_attribute */
	public bool has_more_attributes () {
		return has_attributes;
	}
	
	/** @return next attribute. */
	public Attribute get_next_attribute () {
		Attribute r = next_attribute == null ? new Attribute.empty () : (!) next_attribute;
		next_attribute = obtain_next_attribute ();
		return r;
	}
	
	Tag obtain_next_tag () {
		int end_tag_index;
		Tag tag;
		
		tag = find_next_tag (tag_index, out end_tag_index);
		
		if (end_tag_index != -1) {
			tag_index = end_tag_index;
			has_tags = true;
		} else {
			has_tags = false;
		}
		
		return tag;
	}
	
	Tag find_next_tag (int start, out int end_tag_index) {
		int index;
		unichar c;
		int separator;
		int end;
		int closing_tag;

		string name;
		string attributes;
		string content;
	
		index = start;
		end_tag_index = -1;
		while (data.get_next_char (ref index, out c)) {
			if (c == '<') {
				separator = find_next_separator (index);

				if (separator < 0) {
					warning ("Expecting a separator after index %d.", index);
					return new Tag.empty ();
				}
				
				name = data.substring (index, separator - index);
				
				if (name.has_prefix ("!")) {
					continue;
				}
				
				end = data.index_of (">", start);
				attributes = data.substring (separator, end - separator);
				
				if (attributes.has_suffix ("/")) {
					content = "";
					end_tag_index = data.index_of (">", index);
					data.get_next_char (ref end_tag_index, out c);
				} else {
					data.get_next_char (ref end, out c); // skip >
					closing_tag = find_closing_tag (name, end);
					content = data.substring (end, closing_tag - end);
					end_tag_index = data.index_of (">", closing_tag);
					data.get_next_char (ref end_tag_index, out c);
				}
				
				return new Tag (name, attributes, content);	
			}
		}
		
		return new Tag.empty ();
	}
	
	int find_next_separator (int start) {
		int index = start;
		int previous_index = start;
		unichar c;
		
		while (true) {
			
			previous_index = index;
			if (!data.get_next_char (ref index, out c)) {
				break;
			}
			
			if (c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '>' || c == '/') {
				return previous_index;
			}
		}
		
		return -1;
	}
	
	int find_closing_tag (string name, int start) {
		int index = start;
		int slash_index = start;
		int previous_index;
		unichar c;
		int start_count = 0;
		
		while (true) {
			previous_index = index;
			if (!data.get_next_char (ref index, out c)) {
				break;
			}
			
			if (c == '<') {
				slash_index = index;
				data.get_next_char (ref slash_index, out c);
				if (c == '/' && is_tag (name, slash_index)) {
					if (start_count == 0) {
						return previous_index;
					} else {
						start_count--;
						if (start_count == 0) {
							return previous_index;
						}
					}
				} else if (is_tag (name, index)) {
					start_count++;					
				}
			}
		}
		
		warning (@"No closing tag for $(name).");
		return -1;
	}
	
	bool is_tag (string name, int start) {
		int index = 0;
		int data_index = start;
		unichar c;
		unichar c_data;
		
		while (name.get_next_char (ref index, out c)) {
			if (data.get_next_char (ref data_index, out c_data)) {
				if (c_data != c) {
					return false;
				}
			}
		}
		
		
		if (data.get_next_char (ref data_index, out c_data)) {
			return c_data == '>' || c_data == ' ' || c_data == '\t' 
				|| c_data == '\n' || c_data == '\r' || c_data == '/';
		}
		
		return false;
	}

	Attribute obtain_next_attribute () {
		int previous_index;
		int index = attribute_index;
		int name_start;
		string attribute_name;		
		string ns;
		string content;
		int ns_separator;
		int content_start;
		int content_stop;
		unichar quote;
		unichar c;
		
		// skip space and other separators
		while (true) {
			previous_index = index;
			
			if (!attributes.get_next_char (ref index, out c)) {
				has_attributes = false;
				return new Attribute.empty ();
			}
			
			if (!(c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '/')) {
				break;
			}
		}
		
		name_start = previous_index;

		// read attribute name
		while (true) {
			previous_index = index;
			if (!attributes.get_next_char (ref index, out c)) {
				warning (@"Unexpected end of attributes in tag $(this.name)");
				has_attributes = false;
				return new Attribute.empty ();
			}
			
			if (c == ' ' || c == '\t' || c == '=' || c == '\n' || c == '\r') {
				break;
			}
		}
		
		attribute_name = attributes.substring (name_start, previous_index - name_start);
		index = name_start + attribute_name.length;
		ns = "";
		ns_separator = attribute_name.index_of (":");
		if (ns_separator != -1) {
			ns = attribute_name.substring (0, ns_separator);
			attribute_name = attribute_name.substring (ns_separator + 1);
		}
		
		// equal sign and space around it
		while (attributes.get_next_char (ref index, out c)) {
			if (!(c == ' ' || c == '\t' || c == '\n' || c == '\r')) {
				if (c == '=') {
					break;
				} else {
					has_attributes = false;
					warning (@"Expecting equal sign for attribute $(attribute_name).");
					return new Attribute.empty ();
				}
			}
		}
		
		while (attributes.get_next_char (ref index, out c)) {
			if (!(c == ' ' || c == '\t' || c == '\n' || c == '\r')) {
				if (c == '"' || c == '\'') {
					break;
				} else {
					has_attributes = false;
					warning (@"Expecting quote for attribute $(attribute_name).");
					return new Attribute.empty ();
				}
			}
		}
		
		quote = c;
		content_start = index;
		
		while (true) {
			if (!attributes.get_next_char (ref index, out c)) {
				has_attributes = false;
				warning (@"Expecting end quote for attribute $(attribute_name).");
				return new Attribute.empty ();
			}
			
			if (c == quote) {
				break;
			}
		}
		
		content_stop = index - 1;
		content = attributes.substring (content_start, content_stop - content_start);
		
		has_attributes = true;
		
		attribute_index = content_stop + 1;
		return new Attribute (ns, attribute_name, content);
	}
}

}
