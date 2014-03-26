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
	public List<Expander> expanders;
	public Expander classes;
	
	private static bool suppress_event = false;
	
	public PreviewTools () {
		Expander webview_tools = new Expander ();
		
		Tool update_webview_button = new Tool ("update_webview", t_("Reload webview"));
		update_webview_button.select_action.connect ((self) => {
			update_preview ();
		});
		webview_tools.add_tool (update_webview_button);
		
		Tool export_fonts_button = new Tool ("export_fonts", t_("Export fonts"));
		export_fonts_button.select_action.connect ((self) => {
			export_fonts ();
		});
		webview_tools.add_tool (export_fonts_button);

		Tool generate_html_button = new Tool ("generate_html_document", t_("Generate html document"));
		generate_html_button.select_action.connect ((self) => {
			generate_html_document ();
		});
		webview_tools.add_tool (generate_html_button);
		
		webview_tools.set_open (true);
		
		expanders.append (webview_tools);
	}

	
	/** Export fonts and update html canvas. */
	public static void update_preview () {
		export_fonts ();

		if (!Preview.has_html_document ()) {
			Preview.generate_html_document ();
		}
		
		MainWindow.tabs.select_tab_name ("Preview");
	}
		
	/** Export TTF, EOT and SVG fonts. */
	public static void export_fonts () {
		if (!suppress_event) {
			suppress_event = true;
			ExportTool.export_ttf_font_sync ();
			ExportTool.export_svg_font ();
			MainWindow.get_tool_tip ().show_text (t_("Three font files has been created."));	
			suppress_event = false;
		}
	}

	/** Generate the preview document. */
	public static void generate_html_document () {
		Preview.delete_html_document ();
		Preview.generate_html_document ();
	}
		
	public override unowned List<Expander> get_expanders () {
		return expanders;
	}
}

}
