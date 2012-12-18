BIRDFONT = [
	'Allocation.vala',
	'Argument.vala',
	'Font.vala',
	'BackgroundTool.vala',
	'BackgroundSelection.vala',
	'Birdfont.vala',
	'EotWriter.vala',
	'Expander.vala',
	'ExportTool.vala',
	'FontDisplay.vala',
	'CharDatabase.vala',
	'Config.vala',
	'Context.vala',
	'CutBackgroundTool.vala',
	'CutTool.vala',
	'ClipTool.vala',
	'DropMenu.vala',
	'EditPoint.vala',
	'EditPointHandle.vala',
	'Glyph.vala',
	'GlyphBackgroundImage.vala',
	'GlyphCanvas.vala',
	'GlyphCollection.vala',
	'GlyphRange.vala',
	'GlyphTable.vala',
	'GridTool.vala',
	'Icons.vala',
	'Kerning.vala', 
	'KeyBindings.vala', 
	'Line.vala',
	'MainWindow.vala',
	'MenuAction.vala',
	'MenuTab.vala',
	'MergeTool.vala',
	'MoveTool.vala',
	'NativeWindow.vala',
	'Intersection.vala',
	'IntersectionList.vala',
	'IOThread.vala',
	'OpenFontFormatWriter.vala',
	'OpenFontFormatReader.vala',
	'OverView.vala',
	'Path.vala',
	'PenTool.vala',
	'Preview.vala',
	'ResizeTool.vala',
	'SaveDialog.vala',
	'Scrollbar.vala',
	'ShrinkTool.vala',
	'SpinButton.vala',
	'Supplement.vala',
	'Svg.vala',
	'SvgFontFormatWriter.vala',
	'Preferences.vala',
	'Tab.vala',
	'TabBar.vala',
	'TestCases.vala', 
	'TestSupplement.vala', 
	'Tool.vala',
	'Toolbox.vala',
	'TooltipArea.vala',
	'UniRange.vala',
	'VersionList.vala',
	'ZoomTool.vala',
]

def task_build ():
	return  {
		'actions': ['echo "Bilding Birdfont"'],
		'file_dep': ['build/libbirdfont.so'],
	}
	
def task_libbirdfont_c ():
	action = "valac -C "
	action += "--basedir ./build/libbirdfont "
	action += "--enable-experimental-non-null "
	action += "--vapidir=./ --thread --save-temps "
	action += """-X '-D GETTEXT_PACKAGE="birdfont"' """
	action += "--library birdfont "
	action += "-H ./build/birdfont.h "
	action += "--vapi ./build/birdfont.vapi "
	action += "-o ../build/libbirdfont.so "
	action += "-X -fPIC "
	action += "-X -shared "
	action += "--pkg gtk+-2.0 " 
	action += "--pkg libxml-2.0 "
	action += "--pkg webkit-1.0 "
	
	actions = [ action + "libbirdfont/*.vala" ]
	
	return {
		'actions': actions,
		'file_dep': [ 'libbirdfont/Config.vala' ],
		'targets': [ 'build/birdfont.h', 'build/birdfont.vapi'],
		'clean': True
	}


def task_libbirdfont_o ():
	action = "gcc "
	param = """ -D 'GETTEXT_PACKAGE="birdfont"' \
			$(pkg-config --cflags --libs glib-2.0) \
			$(pkg-config --cflags --libs libxml-2.0) \
			$(pkg-config --cflags --libs gio-2.0) \
			$(pkg-config --cflags --libs libsoup-2.4) \
			$(pkg-config --cflags --libs cairo) \
			$(pkg-config --cflags --libs gdk-pixbuf-2.0) \
			$(pkg-config --cflags --libs webkit-1.0)"""

	for src in BIRDFONT:
		yield { 
			'name': src.replace ('.vala', '.c'),
			'file_dep': [ 'build/libbirdfont/' + src.replace ('.vala', '.c') ],
			'actions': [action + param + "-c build/libbirdfont/" + src.replace ('.vala', '.c') + " -o build/libbirdfont/" + src.replace ('.vala', '.o')],
			'targets': [ src.replace ('.vala', '.o') ],
			'clean': True
		}
	
def task_libbirdfont_so ():
	action = """gcc -shared build/libbirdfont/*.o \
			$(pkg-config --cflags --libs glib-2.0) \
			$(pkg-config --cflags --libs libxml-2.0) \
			$(pkg-config --cflags --libs gio-2.0) \
			$(pkg-config --cflags --libs libsoup-2.4) \
			$(pkg-config --cflags --libs cairo) \
			$(pkg-config --cflags --libs gdk-pixbuf-2.0) \
			$(pkg-config --cflags --libs webkit-1.0) \
			-o build/libbirdfont.so"""
		
	return {
		'actions': [ action ],
		'file_dep': [ 'build/libbirdfont/Config.c' ],
		'targets': [ 'build/libbirdfont.so' ],
		'clean': True
	}
