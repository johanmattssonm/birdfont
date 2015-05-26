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

/**
 * Representation of one XML tag.
 */
public class Tag : GLib.Object {
	internal XmlData entire_file;
	
	public int tag_index; 
	public int attribute_index;
	
	public bool has_tags;
	public bool has_attributes;
	
	public XmlString name;
	public XmlString data;
	public XmlString attributes;
	
	public Tag? next_tag = null;
	public Attribute? next_attribute = null;
	
	public bool error = false;
	public int log_level = WARNINGS;
	
	public int refcount = 1;
	
	internal Tag (XmlString name, XmlString attributes, XmlString content,
		int log_level, XmlData entire_file) {
		
		this.entire_file = entire_file;
		this.log_level = log_level;
		this.name = name;
		this.data = content;
		this.attributes = attributes;
		
		reparse ();
		reparse_attributes ();
	}
	
	internal Tag.empty () {
		entire_file = new XmlData ("", 0);
		data = new XmlString ("", 0);
		attributes = new XmlString ("", 0);
		name = new XmlString ("", 0);
	}
	
	/** 
	 * Get tag attributes for this tag. 
	 * @return a container with all the attributes
	 */
	public Attributes get_attributes () {
		return new Attributes (this);
	}

	/** 
	 * Iterate over all tags inside of this tag.
	 */
	public Iterator iterator () {
		return new Iterator(this);
	}

	/** 
	 * Reset the parser and start from the beginning XML tag.
	 */
	public void reparse () {
		tag_index = 0;
		next_tag = obtain_next_tag ();
	}

	internal void reparse_attributes () {
		attribute_index = 0;
		next_attribute = obtain_next_attribute ();
	}
	
	/** 
	 * Obtain the name of the tag.
	 * @return the name of this tag. 
	 */ 
	public string get_name () {
		return name.to_string ();
	}

	/** 
	 * Obtain tag content.
	 * @return data between the start and end tags.
	 */
	public string get_content () {
		return data.to_string ();
	}

	/** 
	 * @return true if there is one more tags left
	 */
	internal bool has_more_tags () {
		return has_tags;
	}
	
	/** @return the next tag. **/
	internal Tag get_next_tag () {
		Tag r = next_tag == null ? new Tag.empty () : (!) next_tag;
		next_tag = obtain_next_tag ();
		return r;
	}

	/** @return true is there is one or more attributes to obtain with get_next_attribute */
	internal bool has_more_attributes () {
		return has_attributes;
	}
	
	/** @return next attribute. */
	internal Attribute get_next_attribute () {
		Attribute r = next_attribute == null ? new Attribute.empty () : (!) next_attribute;
		next_attribute = obtain_next_attribute ();
		return r;
	}
	
	internal bool has_failed () {
		return error;
	}
	
	Tag obtain_next_tag () {
		int end_tag_index;
		Tag tag;
		
		tag = find_next_tag (tag_index, out end_tag_index);

		if (end_tag_index != -1) {
			tag_index = end_tag_index;
			has_tags = true;
			return tag;
		}
		
		has_tags = false;
		return new Tag.empty ();
	}
	
	Tag find_next_tag (int start, out int end_tag_index) {
		int index;
		unichar c;
		int separator;
		int end;
		int closing_tag;
		XmlString? d;

		XmlString name;
		XmlString attributes;
		XmlString content;

		end_tag_index = -1;
			
		if (start < 0) {
			warn ("Negative index.");
			return new Tag.empty ();
		}
	
		index = start;

		d = data;
		if (d == null) {
			warn ("No data in xml string.");
			return new Tag.empty ();
		}
			
		while (data.get_next_ascii_char (ref index, out c)) {
		
			if (c == '<') {
				separator = find_next_separator (index);

				if (separator < 0) {
					error = true;
					warn ("Expecting a separator.");
					return new Tag.empty ();
				}
				
				name = data.substring (index, separator - index);
				
				if (name.has_prefix ("!")) {
					continue;
				}
				
				end = data.index_of (">", start);
				attributes = data.substring (separator, end - separator);
				
				if (attributes.has_suffix ("/")) {
					content = new XmlString ("", 0);
					end_tag_index = data.index_of (">", index);
					data.get_next_ascii_char (ref end_tag_index, out c);
				} else {
					if (!data.get_next_ascii_char (ref end, out c)) {; // skip >
						warn ("Unexpected end of data.");
						error = true;
						break;
					}
					
					if (c != '>') {
						warn ("Expecting '>'");
						error = true;
						break;
					}
					
					closing_tag = find_closing_tag (name, end);
					
					if (closing_tag == -1) {
						warn ("No closing tag.");
						error = true;
						break;
					}
					
					content = data.substring (end, closing_tag - end);
					end_tag_index = data.index_of (">", closing_tag);
					data.get_next_ascii_char (ref end_tag_index, out c);
				}
				
				return new Tag (name, attributes, content, log_level, entire_file);	
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
			if (!data.get_next_ascii_char (ref index, out c)) {
				break;
			}
			
			if (c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '>' || c == '/') {
				return previous_index;
			}
		}
		
		return -1;
	}
	
	int find_closing_tag (XmlString name, int start) {
		int index = start;
		int slash_index = start;
		int previous_index;
		unichar c, slash;
		int start_count = 1;
		int next_tag;
		
		if (name.length == 0) {
			error = true;
			warn ("No name for tag.");
			return -1;
		}
	
		index = entire_file.get_index (data) + start;
		while (true) {
			while (!entire_file.substring (index).has_prefix ("</")) {
				index = entire_file.find_next_tag_token (index + 1);
				
				if (index == -1) {
					warning (@"No end tag for $(name)");
					return -1;
				}
			}

			previous_index = index - entire_file.get_index (data);
			
			if (!entire_file.get_next_ascii_char (ref index, out c)) {
				warn ("Unexpected end of file");
				break;
			}
			
			if (c == '<') {
				slash_index = index;
				entire_file.get_next_ascii_char (ref slash_index, out slash);

				if (slash == '/' && is_tag (entire_file, name, slash_index)) {
					if (start_count == 1) {
						return previous_index;
					} else {
						start_count--;
						if (start_count == 0) {
							return previous_index;
						}
					}
				} else if (is_tag (entire_file, name, slash_index)) {
					start_count++;
				}
			}
		}
		
		error = true;
		warn (@"No closing tag for $(name.to_string ())");
		
		return -1;
	}
	
	bool is_tag (XmlString tag, XmlString name, int start) {
		int index = 0;
		int data_index = start;
		unichar c;
		unichar c_data;
		
		while (name.get_next_ascii_char (ref index, out c)) {
			if (tag.get_next_ascii_char (ref data_index, out c_data)) {
				if (c_data != c) {
					return false;
				}
			}
		}
		
		if (tag.get_next_ascii_char (ref data_index, out c_data)) {
			return c_data == '>' || c_data == ' ' || c_data == '\t' 
				|| c_data == '\n' || c_data == '\r' || c_data == '/';
		}
		
		return false;
	}

	internal Attribute obtain_next_attribute () {
		int previous_index;
		int index = attribute_index;
		int name_start;
		XmlString attribute_name;		
		XmlString ns;
		XmlString content;
		int ns_separator;
		int content_start;
		int content_stop;
		unichar quote;
		unichar c;
		
		// skip space and other separators
		while (true) {
			previous_index = index;
			
			if (!attributes.get_next_ascii_char (ref index, out c)) {
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
			if (!attributes.get_next_ascii_char (ref index, out c)) {
				error = true;
				warn (@"Unexpected end of attributes in tag $(this.name)");
				has_attributes = false;
				return new Attribute.empty ();
			}
			
			if (c == ' ' || c == '\t' || c == '=' || c == '\n' || c == '\r') {
				break;
			}
		}
		
		attribute_name = attributes.substring (name_start, previous_index - name_start);
		index = name_start + attribute_name.length;
		ns = new XmlString ("", 0);
		ns_separator = attribute_name.index_of (":");
		if (ns_separator != -1) {
			ns = attribute_name.substring (0, ns_separator);
			attribute_name = attribute_name.substring (ns_separator + 1);
		}
		
		// equal sign and space around it
		while (attributes.get_next_ascii_char (ref index, out c)) {
			if (!(c == ' ' || c == '\t' || c == '\n' || c == '\r')) {
				if (c == '=') {
					break;
				} else {
					has_attributes = false;
					error = true;
					warn (@"Expecting equal sign for attribute $(attribute_name).");
					warn (@"Around: $(attributes.substring (index, 10)).");
					warn (@"Row: $(get_row (((size_t) attributes.data) + index))");
					
					return new Attribute.empty ();
				}
			}
		}
		
		while (attributes.get_next_ascii_char (ref index, out c)) {
			if (!(c == ' ' || c == '\t' || c == '\n' || c == '\r')) {
				if (c == '"' || c == '\'') {
					break;
				} else {
					has_attributes = false;
					error = true;
					warn (@"Expecting quote for attribute $(attribute_name).");
					return new Attribute.empty ();
				}
			}
		}
		
		quote = c;
		content_start = index;
		
		while (true) {
			if (!attributes.get_next_ascii_char (ref index, out c)) {
				has_attributes = false;
				error = true;
				warn (@"Expecting end quote for attribute $(attribute_name).");
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

	public class Iterator : GLib.Object {
		public Tag tag;
		public Tag? next_tag = null;
		public int iterator_efcount = 1;
		
		internal Iterator (Tag t) {
			tag = t;
			tag.reparse ();
		}

		public bool next () {
			if (tag.error) { 
				return false;
			}
			
			if (tag.has_more_tags ()) {
				next_tag = tag.get_next_tag ();
			} else {
				next_tag = null;
			}
									
			return next_tag != null;
		}

		public new Tag get () {
			if (next_tag == null) {
				XmlParser.warning ("No tag is parsed yet.");
				return new Tag.empty ();
			}
			return (!) next_tag;
		}
	}
	
	internal int get_row (size_t pos) {
		int index = 0;
		unichar c;
		int row = 1;
		size_t p, e;
		
		e = (size_t) entire_file.data;
		while (entire_file.get_next_ascii_char (ref index, out c)) {
			if (c == '\n') {
				row++;
			}
			
			if (e + index >= pos) {
				break;
			}
		}
		
		return row;
	}
	
	internal void warn (string message) {
		if (log_level == WARNINGS) {
			XmlParser.warning (message);
		}
	}
}

}
