/*
    Copyright (C) 2015 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

namespace BirdFont {

/** Gsub substitutions will be performed kening and spacing tab when 
 * this tool is selected.
 */
public class OtfLabel : LabelTool {

	public bool active_substitution = false;
	public string tag;
	
	public signal void otf_feature_activity (bool enable, string tag);
	
	public OtfLabel (string tag) {
		string label = get_string(tag);
		base (label);
		
		this.tag = tag;
		
		select_action.connect ((self) => {
			active_substitution = !active_substitution;
			self.set_selected (active_substitution);
			otf_feature_activity (active_substitution, tag);
		});
	}
	
	/** @return translated string representation of a OTF feature tag. */
	public static string get_string (string tag) {
		if (tag == "salt") {
			return t_("Stylistic Alternate") + " (salt)";
		} else if (tag == "smcp") {
			return t_("Small Caps") + " (smcp)";
		} else if (tag == "c2sc") {
			return t_("Capitals to Small Caps") + " (c2sc)";
		} else if (tag == "swsh") {
			return t_("Swashes") + " (swsh)";
		}
		
		warning (@"Unknown tag: $tag");
		return tag;
	}
}

}
