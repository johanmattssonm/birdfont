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
using Math;

namespace SvgBird {

public enum AttributePatternType {
	NONE,
	ANYTHING,
	LIST,
	EQUALS,
	STARTS_WITH
}

public class AttributePattern : GLib.Object {
	public string name = "";
	public string? content = null;
	public AttributePatternType type = AttributePatternType.NONE;
	
	public bool match (Attributes attributes) {
		switch (type) {
		case AttributePatternType.ANYTHING:
			return match_attribute_name (attributes);
		case AttributePatternType.LIST:
			return match_list (attributes);
		case AttributePatternType.EQUALS:
			return attribute_equals (attributes);
		case AttributePatternType.STARTS_WITH:
			return attribute_start_with (attributes);
		}
		
		return false;
	}

	string remove_hypen (string content) {
		int hyphen = content.index_of ("-");
		
		if (hyphen == -1) {
			return content;
		}
		
		return content.substring (0, hyphen);
	}

	bool attribute_start_with (Attributes attributes) {
		foreach (Attribute attribute in attributes) {
			if (attribute.get_name () == name 
				&& remove_hypen (attribute.get_content ()) == content) {
				return true;
			}
		}
		
		return false;
	}

	bool attribute_equals (Attributes attributes) {
		foreach (Attribute attribute in attributes) {
			if (attribute.get_name () == name 
				&& attribute.get_content () == content) {
				return true;
			}
		}
		
		return false;
	}
	
	bool match_attribute_name (Attributes attributes) {
		foreach (Attribute attribute in attributes) {
			if (attribute.get_name () == name) {
				return true;
			}
		}
		
		return false;
	}
	
	bool match_list (Attributes attributes) {
		if (content == null) {
			return false;
		}
		
		string[] list = ((!) content).split (" ");
		foreach (Attribute attribute in attributes) {
			if (attribute.get_name () == name) {
				
				string attribute_content = attribute.get_content ();
				foreach (string list_item in list) {
					if (attribute_content == list_item) {
						return true;
					}
				}
			}
		}
		
		return false;
	}
}

}
