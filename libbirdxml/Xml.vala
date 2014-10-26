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

/** 
 * Tools originally written for the BirdFont project.
 */
namespace Bird {

/** Log levels */
internal const int NONE = 0;
internal const int WARNINGS = 1;

/** 
 * XML parser
 * 
 * A tiny XML parser written in Vala.
 * 
 * Example:
 * {{{
 * 
 * // Print all tags and attributes in an XML document. 
 * // Expected output:
 * // tag1
 * // tag2
 * // attribute1
 * public static int main (string[] arg) {
 * 	Tag root;
 * 	XmlParser parser;
 * 
 * 	parser = new XmlParser ("""<tag1><tag2 attribute1=""/></tag1>""");	
 * 
 * 	if (parser.validate ()) {
 * 		root = parser.get_root_tag ();
 * 		print_tags (root);
 * 	}
 * }
 * 
 * 
 * void print_tags (Tag tag) {
 * 	print (tag.get_name ());
 * 	print ("\n");
 * 	print_attributes (tag);
 * 
 * 	foreach (Tag t in tag) {
 * 		print_tags (t);
 * 	}
 * }
 * 
 * void print_attributes (Tag tag) {
 * 	Attributes attributes = tag.get_attributes ();
 * 	foreach (Attribute attribute in attributes) {
 * 		print (attribute.get_name ()");
 * 		print ("\n");
 * 	}
 * }
 * 
 * }}}
 * 
 */
[Compact]
[CCode (ref_function = "bird_xml_parser_ref", unref_function = "bird_xml_parser_unref")]
public class XmlParser {
	public Tag root;
	public XmlString data;
	public string input;
	public bool error;
	public int refcount = 1;
	
	/** 
	 * Create a new xml parser. 
	 * @param data valid xml data
	 */
	public XmlParser (string data) {
		this.input = data;
		this.data = new XmlString (data, data.length);
		reparse (NONE);
	}

	/** Increment the reference count.
	 * @return a pointer to this object
	 */
	public unowned XmlParser @ref () {
		refcount++;
		return this;
	}
	
	/** Decrement the reference count and free the object when zero object are holding references to it.*/
	public void unref () {
		if (--refcount == 0) {
			this.finalize ();
		}
	}
		
	/** 
	 * Determine if the document can be parsed.
	 * @return true if the xml document is valid xml.
	 */
	public bool validate () {
		reparse (NONE);

		if (error) {
			return false;
		}
		
		validate_tags (root);
			
		reparse (NONE);
		return !error;
	}
	
	void validate_tags (Tag tag) {
		Attributes attributes = tag.get_attributes ();
		
		foreach (Attribute a in attributes) {
			if (tag.has_failed () || a.name.length == 0) {
				error = true;
				return;
			}
		}
		
		foreach (Tag t in tag) {
			if (tag.has_failed ()) {
				error = true;
				return;
			}
			
			validate_tags (t);
		}		
	}
	
	/** 
	 * Obtain the root tag.
	 * @return the root tag. 
	 */
	public Tag get_root_tag () {
		reparse (WARNINGS);
		return root;
	}
	
	/** 
	 * Reset the parser and start from the beginning of the XML document. 
	 */
	internal void reparse (int log_level) {
		int root_index;
		Tag container;
		XmlString content;
		
		error = false;
		
		root_index = find_root_tag ();
		if (root_index == -1) {
			if (log_level == WARNINGS) {
				XmlParser.warning ("No root tag found.");
			}
			error = true;
			root = new Tag.empty ();
		} else {
			content = data.substring (root_index);
			container = new Tag (new XmlString ("", 0), new XmlString ("", 0), content, log_level);
			root = container.get_next_tag ();
		}
	}
	
	int find_root_tag () {
		int index = 0;
		int prev_index = 0;
		int modifier = 0;
		unichar c;
		
		while (true) {
			prev_index = index;
			if (!data.get_next_char (ref index, out c)) {
				break;
			}
			
			if (c == '<') {
				modifier = index;
				data.get_next_char (ref modifier, out c);
				if (c != '?' && c != '[' && c != '!') {
					return prev_index;
				} 
			}
		}
		
		return -1;
	}

	/** Print a warning message. */
	public static void warning (string message) {
		print ("XML error: "); 
		print (message);
		print ("\n");
	}
	
	private extern void finalize ();
}

}
