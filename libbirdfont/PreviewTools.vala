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

namespace BirdFont {

public class PreviewTools : ToolCollection  {
	public Gee.ArrayList<Expander> expanders = new Gee.ArrayList<Expander> ();
	public Expander classes;
	
	public PreviewTools () {
		Expander webview_tools = new Expander ();

		Expander font_name = new Expander ();
		font_name.add_tool (new FontName ());
		font_name.draw_separator = false;
				
		Tool update_webview_button = new Tool ("update_webview", t_("Reload webview"));
		update_webview_button.select_action.connect ((self) => {
			update_preview ();
		});
		webview_tools.add_tool (update_webview_button);
		
		Tool export_fonts_button = new Tool ("export_fonts", t_("Export fonts"));
		export_fonts_button.select_action.connect ((self) => {
			MenuTab.export_fonts_in_background ();
		});
		webview_tools.add_tool (export_fonts_button);

		Tool generate_html_button = new Tool ("generate_html_document", t_("Generate html document"));
		generate_html_button.select_action.connect ((self) => {
			generate_html_document ();
		});
		webview_tools.add_tool (generate_html_button);
		
		expanders.add (font_name);
		expanders.add (webview_tools);
	}

	/** Export fonts and update html canvas. */
	public static void update_preview () {
		MenuTab.export_callback = new ExportCallback ();
		MenuTab.export_callback.file_exported.connect (signal_preview_updated);
		MenuTab.export_callback.export_fonts_in_background ();
	}

	private static void signal_preview_updated () {
		IdleSource idle = new IdleSource ();

		idle.set_callback (() => {
			if (!Preview.has_html_document ()) {
				Preview.generate_html_document ();
			}
			
			MainWindow.tabs.select_tab_name ("Preview");
			return false;
		});
		
		idle.attach (null);	
	}

	/** Generate the preview document. */
	public static void generate_html_document () {
		Preview.delete_html_document ();
		Preview.generate_html_document ();
	}
		
	public override Gee.ArrayList<Expander> get_expanders () {
		return expanders;
	}
}

}
