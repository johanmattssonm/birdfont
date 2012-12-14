.. _featuremap:

Feature reference
=================

.. include:: featuremap_example.txt
Feature \*
==========

.. graphviz::

	digraph feature_all {
	size="8.0, 12.0";
		"apply_intltool_in_f" [style="setlinewidth(0.5)",URL="tools/intltool.html#waflib.Tools.intltool.apply_intltool_in_f",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"process_source" [style="setlinewidth(0.5)",URL="TaskGen.html#waflib.TaskGen.process_source",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"process_rule" [style="setlinewidth(0.5)",URL="TaskGen.html#waflib.TaskGen.process_rule",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"jar_files" [style="setlinewidth(0.5)",URL="tools/javaw.html#waflib.Tools.javaw.jar_files",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"process_marshal" [style="setlinewidth(0.5)",URL="tools/glib2.html#waflib.Tools.glib2.process_marshal",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"link_lib_test_fun" [style="setlinewidth(0.5)",URL="tools/c_tests.html#waflib.Tools.c_tests.link_lib_test_fun",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"process_enums" [style="setlinewidth(0.5)",URL="tools/glib2.html#waflib.Tools.glib2.process_enums",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_java" [style="setlinewidth(0.5)",URL="tools/javaw.html#waflib.Tools.javaw.apply_java",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"link_main_routines_tg_method" [style="setlinewidth(0.5)",URL="tools/fc_config.html#waflib.Tools.fc_config.link_main_routines_tg_method",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"process_subst" [style="setlinewidth(0.5)",URL="TaskGen.html#waflib.TaskGen.process_subst",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_cs" [style="setlinewidth(0.5)",URL="tools/cs.html#waflib.Tools.cs.apply_cs",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_tex" [style="setlinewidth(0.5)",URL="tools/tex.html#waflib.Tools.tex.apply_tex",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"process_rule" -> "process_subst" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"process_source" -> "process_rule" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"process_source" -> "process_subst" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"process_source" -> "link_lib_test_fun" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"process_source" -> "link_main_routines_tg_method" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"process_source" -> "apply_tex" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"process_source" -> "apply_java" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"process_source" -> "jar_files" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"process_source" -> "process_marshal" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"process_source" -> "process_enums" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"process_source" -> "apply_cs" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"process_source" -> "apply_intltool_in_f" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}



Feature asm
===========

.. graphviz::

	digraph feature_asm {
	size="8.0, 12.0";
		"process_use" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.process_use",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_nasm_vars" [style="setlinewidth(0.5)",URL="tools/nasm.html#waflib.Tools.nasm.apply_nasm_vars",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"init_perlext" [style="setlinewidth(0.5)",URL="tools/perl.html#waflib.Tools.perl.init_perlext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_ruby_so_name" [style="setlinewidth(0.5)",URL="tools/ruby.html#waflib.Tools.ruby.apply_ruby_so_name",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"process_source" [style="setlinewidth(0.5)",URL="TaskGen.html#waflib.TaskGen.process_source",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_incpaths" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_incpaths",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_link" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_link",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"init_pyext" [style="setlinewidth(0.5)",URL="tools/python.html#waflib.Tools.python.init_pyext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"init_rubyext" [style="setlinewidth(0.5)",URL="tools/ruby.html#waflib.Tools.ruby.init_rubyext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"set_lib_pat" [style="setlinewidth(0.5)",URL="tools/fc_config.html#waflib.Tools.fc_config.set_lib_pat",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"propagate_uselib_vars" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.propagate_uselib_vars",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_bundle" [style="setlinewidth(0.5)",URL="tools/c_osx.html#waflib.Tools.c_osx.apply_bundle",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_incpaths" -> "propagate_uselib_vars" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "process_source" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "process_use" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "init_rubyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "init_perlext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "apply_bundle" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "process_source" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "set_lib_pat" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "init_rubyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "apply_ruby_so_name" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "init_pyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "init_perlext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}



Feature c
=========

.. graphviz::

	digraph feature_c {
	size="8.0, 12.0";
		"process_use" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.process_use",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"process_source" [style="setlinewidth(0.5)",URL="TaskGen.html#waflib.TaskGen.process_source",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_incpaths" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_incpaths",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"set_lib_pat" [style="setlinewidth(0.5)",URL="tools/fc_config.html#waflib.Tools.fc_config.set_lib_pat",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_bundle" [style="setlinewidth(0.5)",URL="tools/c_osx.html#waflib.Tools.c_osx.apply_bundle",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"set_macosx_deployment_target" [style="setlinewidth(0.5)",URL="tools/c_osx.html#waflib.Tools.c_osx.set_macosx_deployment_target",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"init_perlext" [style="setlinewidth(0.5)",URL="tools/perl.html#waflib.Tools.perl.init_perlext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_ruby_so_name" [style="setlinewidth(0.5)",URL="tools/ruby.html#waflib.Tools.ruby.apply_ruby_so_name",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_link" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_link",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"init_pyext" [style="setlinewidth(0.5)",URL="tools/python.html#waflib.Tools.python.init_pyext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"init_rubyext" [style="setlinewidth(0.5)",URL="tools/ruby.html#waflib.Tools.ruby.init_rubyext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_flags_msvc" [style="setlinewidth(0.5)",URL="tools/msvc.html#waflib.Tools.msvc.apply_flags_msvc",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"propagate_uselib_vars" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.propagate_uselib_vars",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"init_pyembed" [style="setlinewidth(0.5)",URL="tools/python.html#waflib.Tools.python.init_pyembed",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"process_use" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"process_use" -> "process_source" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "propagate_uselib_vars" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "process_source" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "process_use" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "init_rubyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "init_perlext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "apply_bundle" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "process_source" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "set_lib_pat" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "init_rubyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "apply_ruby_so_name" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "init_pyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "init_perlext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_flags_msvc" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "apply_bundle" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "process_use" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "set_lib_pat" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "init_pyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "init_pyembed" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "init_perlext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_bundle" -> "init_rubyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}



Feature cprogram
================

.. graphviz::

	digraph feature_cprogram {
	size="8.0, 12.0";
		"create_task_macapp" [style="setlinewidth(0.5)",URL="tools/c_osx.html#waflib.Tools.c_osx.create_task_macapp",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"create_task_macplist" [style="setlinewidth(0.5)",URL="tools/c_osx.html#waflib.Tools.c_osx.create_task_macplist",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_link" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_link",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_manifest" [style="setlinewidth(0.5)",URL="tools/msvc.html#waflib.Tools.msvc.apply_manifest",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"create_task_macapp" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"create_task_macplist" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_manifest" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}



Feature cs
==========

.. graphviz::

	digraph feature_cs {
	size="8.0, 12.0";
		"process_use" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.process_use",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"init_perlext" [style="setlinewidth(0.5)",URL="tools/perl.html#waflib.Tools.perl.init_perlext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"debug_cs" [style="setlinewidth(0.5)",URL="tools/cs.html#waflib.Tools.cs.debug_cs",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"init_pyext" [style="setlinewidth(0.5)",URL="tools/python.html#waflib.Tools.python.init_pyext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"use_cs" [style="setlinewidth(0.5)",URL="tools/cs.html#waflib.Tools.cs.use_cs",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"set_lib_pat" [style="setlinewidth(0.5)",URL="tools/fc_config.html#waflib.Tools.fc_config.set_lib_pat",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"propagate_uselib_vars" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.propagate_uselib_vars",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"init_pyembed" [style="setlinewidth(0.5)",URL="tools/python.html#waflib.Tools.python.init_pyembed",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_cs" [style="setlinewidth(0.5)",URL="tools/cs.html#waflib.Tools.cs.apply_cs",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_bundle" [style="setlinewidth(0.5)",URL="tools/c_osx.html#waflib.Tools.c_osx.apply_bundle",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"use_cs" -> "apply_cs" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "apply_bundle" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "process_use" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "set_lib_pat" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "init_pyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "init_pyembed" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "init_perlext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"debug_cs" -> "apply_cs" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"debug_cs" -> "use_cs" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}



Feature cshlib
==============

.. graphviz::

	digraph feature_cshlib {
	size="8.0, 12.0";
		"apply_implib" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_implib",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_bundle_remove_dynamiclib" [style="setlinewidth(0.5)",URL="tools/c_osx.html#waflib.Tools.c_osx.apply_bundle_remove_dynamiclib",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_vnum" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_vnum",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_manifest" [style="setlinewidth(0.5)",URL="tools/msvc.html#waflib.Tools.msvc.apply_manifest",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_link" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_link",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_implib" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_bundle_remove_dynamiclib" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_vnum" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_manifest" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}



Feature cxx
===========

.. graphviz::

	digraph feature_cxx {
	size="8.0, 12.0";
		"process_use" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.process_use",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"process_source" [style="setlinewidth(0.5)",URL="TaskGen.html#waflib.TaskGen.process_source",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_incpaths" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_incpaths",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"set_lib_pat" [style="setlinewidth(0.5)",URL="tools/fc_config.html#waflib.Tools.fc_config.set_lib_pat",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_bundle" [style="setlinewidth(0.5)",URL="tools/c_osx.html#waflib.Tools.c_osx.apply_bundle",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"set_macosx_deployment_target" [style="setlinewidth(0.5)",URL="tools/c_osx.html#waflib.Tools.c_osx.set_macosx_deployment_target",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"init_perlext" [style="setlinewidth(0.5)",URL="tools/perl.html#waflib.Tools.perl.init_perlext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_ruby_so_name" [style="setlinewidth(0.5)",URL="tools/ruby.html#waflib.Tools.ruby.apply_ruby_so_name",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_link" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_link",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"init_pyext" [style="setlinewidth(0.5)",URL="tools/python.html#waflib.Tools.python.init_pyext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"init_rubyext" [style="setlinewidth(0.5)",URL="tools/ruby.html#waflib.Tools.ruby.init_rubyext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_flags_msvc" [style="setlinewidth(0.5)",URL="tools/msvc.html#waflib.Tools.msvc.apply_flags_msvc",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"propagate_uselib_vars" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.propagate_uselib_vars",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"init_pyembed" [style="setlinewidth(0.5)",URL="tools/python.html#waflib.Tools.python.init_pyembed",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"process_use" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"process_use" -> "process_source" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "propagate_uselib_vars" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "process_source" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "process_use" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "init_rubyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "init_perlext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "apply_bundle" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "process_source" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "set_lib_pat" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "init_rubyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "apply_ruby_so_name" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "init_pyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "init_perlext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_flags_msvc" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "apply_bundle" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "process_use" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "set_lib_pat" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "init_pyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "init_pyembed" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "init_perlext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_bundle" -> "init_rubyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}



Feature cxxprogram
==================

.. graphviz::

	digraph feature_cxxprogram {
	size="8.0, 12.0";
		"create_task_macapp" [style="setlinewidth(0.5)",URL="tools/c_osx.html#waflib.Tools.c_osx.create_task_macapp",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"create_task_macplist" [style="setlinewidth(0.5)",URL="tools/c_osx.html#waflib.Tools.c_osx.create_task_macplist",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_link" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_link",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_manifest" [style="setlinewidth(0.5)",URL="tools/msvc.html#waflib.Tools.msvc.apply_manifest",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"create_task_macapp" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"create_task_macplist" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_manifest" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}



Feature cxxshlib
================

.. graphviz::

	digraph feature_cxxshlib {
	size="8.0, 12.0";
		"apply_implib" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_implib",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_bundle_remove_dynamiclib" [style="setlinewidth(0.5)",URL="tools/c_osx.html#waflib.Tools.c_osx.apply_bundle_remove_dynamiclib",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_vnum" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_vnum",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_manifest" [style="setlinewidth(0.5)",URL="tools/msvc.html#waflib.Tools.msvc.apply_manifest",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_link" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_link",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_implib" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_bundle_remove_dynamiclib" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_vnum" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_manifest" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}



Feature d
=========

.. graphviz::

	digraph feature_d {
	size="8.0, 12.0";
		"process_use" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.process_use",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"process_header" [style="setlinewidth(0.5)",URL="tools/d.html#waflib.Tools.d.process_header",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_ruby_so_name" [style="setlinewidth(0.5)",URL="tools/ruby.html#waflib.Tools.ruby.apply_ruby_so_name",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"process_source" [style="setlinewidth(0.5)",URL="TaskGen.html#waflib.TaskGen.process_source",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_incpaths" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_incpaths",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_link" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_link",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"init_pyext" [style="setlinewidth(0.5)",URL="tools/python.html#waflib.Tools.python.init_pyext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"init_rubyext" [style="setlinewidth(0.5)",URL="tools/ruby.html#waflib.Tools.ruby.init_rubyext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"init_perlext" [style="setlinewidth(0.5)",URL="tools/perl.html#waflib.Tools.perl.init_perlext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"set_lib_pat" [style="setlinewidth(0.5)",URL="tools/fc_config.html#waflib.Tools.fc_config.set_lib_pat",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"propagate_uselib_vars" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.propagate_uselib_vars",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"init_pyembed" [style="setlinewidth(0.5)",URL="tools/python.html#waflib.Tools.python.init_pyembed",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_bundle" [style="setlinewidth(0.5)",URL="tools/c_osx.html#waflib.Tools.c_osx.apply_bundle",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"process_use" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"process_use" -> "process_source" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "propagate_uselib_vars" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "process_source" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "process_use" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "init_rubyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "init_perlext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "apply_bundle" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "process_use" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "set_lib_pat" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "init_pyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "init_pyembed" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "init_perlext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "apply_bundle" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "process_source" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "set_lib_pat" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "init_rubyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "apply_ruby_so_name" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "init_pyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "init_perlext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}



Feature dshlib
==============

.. graphviz::

	digraph feature_dshlib {
	size="8.0, 12.0";
		"apply_vnum" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_vnum",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_link" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_link",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_vnum" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}



Feature fake_lib
================

.. graphviz::

	digraph feature_fake_lib {
	size="8.0, 12.0";
		"process_lib" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.process_lib",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	}



Feature fc
==========

.. graphviz::

	digraph feature_fc {
	size="8.0, 12.0";
		"process_use" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.process_use",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"init_perlext" [style="setlinewidth(0.5)",URL="tools/perl.html#waflib.Tools.perl.init_perlext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_ruby_so_name" [style="setlinewidth(0.5)",URL="tools/ruby.html#waflib.Tools.ruby.apply_ruby_so_name",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"process_source" [style="setlinewidth(0.5)",URL="TaskGen.html#waflib.TaskGen.process_source",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_incpaths" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_incpaths",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_link" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_link",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"init_pyext" [style="setlinewidth(0.5)",URL="tools/python.html#waflib.Tools.python.init_pyext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"init_rubyext" [style="setlinewidth(0.5)",URL="tools/ruby.html#waflib.Tools.ruby.init_rubyext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"set_lib_pat" [style="setlinewidth(0.5)",URL="tools/fc_config.html#waflib.Tools.fc_config.set_lib_pat",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"propagate_uselib_vars" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.propagate_uselib_vars",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"init_pyembed" [style="setlinewidth(0.5)",URL="tools/python.html#waflib.Tools.python.init_pyembed",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_bundle" [style="setlinewidth(0.5)",URL="tools/c_osx.html#waflib.Tools.c_osx.apply_bundle",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"process_use" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"process_use" -> "process_source" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "propagate_uselib_vars" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "process_source" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "process_use" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "init_rubyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "init_perlext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "apply_bundle" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "process_use" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "set_lib_pat" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "init_pyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "init_pyembed" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "init_perlext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "apply_bundle" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "process_source" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "set_lib_pat" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "init_rubyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "apply_ruby_so_name" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "init_pyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "init_perlext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}



Feature fcprogram
=================

.. graphviz::

	digraph feature_fcprogram {
	size="8.0, 12.0";
		"dummy" [style="setlinewidth(0.5)",URL="tools/fc.html#waflib.Tools.fc.dummy",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	}



Feature fcprogram_test
======================

.. graphviz::

	digraph feature_fcprogram_test {
	size="8.0, 12.0";
		"dummy" [style="setlinewidth(0.5)",URL="tools/fc.html#waflib.Tools.fc.dummy",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	}



Feature fcshlib
===============

.. graphviz::

	digraph feature_fcshlib {
	size="8.0, 12.0";
		"dummy" [style="setlinewidth(0.5)",URL="tools/fc.html#waflib.Tools.fc.dummy",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_vnum" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_vnum",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_link" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_link",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_vnum" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}



Feature fcstlib
===============

.. graphviz::

	digraph feature_fcstlib {
	size="8.0, 12.0";
		"dummy" [style="setlinewidth(0.5)",URL="tools/fc.html#waflib.Tools.fc.dummy",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	}



Feature glib2
=============

.. graphviz::

	digraph feature_glib2 {
	size="8.0, 12.0";
		"process_settings" [style="setlinewidth(0.5)",URL="tools/glib2.html#waflib.Tools.glib2.process_settings",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	}



Feature go
==========

.. graphviz::

	digraph feature_go {
	size="8.0, 12.0";
		"process_use" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.process_use",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"init_perlext" [style="setlinewidth(0.5)",URL="tools/perl.html#waflib.Tools.perl.init_perlext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_ruby_so_name" [style="setlinewidth(0.5)",URL="tools/ruby.html#waflib.Tools.ruby.apply_ruby_so_name",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"process_source" [style="setlinewidth(0.5)",URL="TaskGen.html#waflib.TaskGen.process_source",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_incpaths" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_incpaths",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_link" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_link",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"init_pyext" [style="setlinewidth(0.5)",URL="tools/python.html#waflib.Tools.python.init_pyext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"init_rubyext" [style="setlinewidth(0.5)",URL="tools/ruby.html#waflib.Tools.ruby.init_rubyext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"set_lib_pat" [style="setlinewidth(0.5)",URL="tools/fc_config.html#waflib.Tools.fc_config.set_lib_pat",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"propagate_uselib_vars" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.propagate_uselib_vars",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_bundle" [style="setlinewidth(0.5)",URL="tools/c_osx.html#waflib.Tools.c_osx.apply_bundle",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_incpaths" -> "propagate_uselib_vars" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "process_source" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "process_use" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "init_rubyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "init_perlext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "apply_bundle" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "process_source" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "set_lib_pat" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "init_rubyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "apply_ruby_so_name" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "init_pyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_link" -> "init_perlext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}



Feature includes
================

.. graphviz::

	digraph feature_includes {
	size="8.0, 12.0";
		"process_use" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.process_use",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"init_perlext" [style="setlinewidth(0.5)",URL="tools/perl.html#waflib.Tools.perl.init_perlext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"process_source" [style="setlinewidth(0.5)",URL="TaskGen.html#waflib.TaskGen.process_source",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_incpaths" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_incpaths",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"init_rubyext" [style="setlinewidth(0.5)",URL="tools/ruby.html#waflib.Tools.ruby.init_rubyext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"propagate_uselib_vars" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.propagate_uselib_vars",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_incpaths" -> "propagate_uselib_vars" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "process_source" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "process_use" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "init_rubyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"apply_incpaths" -> "init_perlext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}



Feature intltool_in
===================

.. graphviz::

	digraph feature_intltool_in {
	size="8.0, 12.0";
		"apply_intltool_in_f" [style="setlinewidth(0.5)",URL="tools/intltool.html#waflib.Tools.intltool.apply_intltool_in_f",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	}



Feature intltool_po
===================

.. graphviz::

	digraph feature_intltool_po {
	size="8.0, 12.0";
		"apply_intltool_po" [style="setlinewidth(0.5)",URL="tools/intltool.html#waflib.Tools.intltool.apply_intltool_po",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	}



Feature jar
===========

.. graphviz::

	digraph feature_jar {
	size="8.0, 12.0";
		"apply_java" [style="setlinewidth(0.5)",URL="tools/javaw.html#waflib.Tools.javaw.apply_java",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"jar_files" [style="setlinewidth(0.5)",URL="tools/javaw.html#waflib.Tools.javaw.jar_files",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"use_javac_files" [style="setlinewidth(0.5)",URL="tools/javaw.html#waflib.Tools.javaw.use_javac_files",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"use_jar_files" [style="setlinewidth(0.5)",URL="tools/javaw.html#waflib.Tools.javaw.use_jar_files",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"jar_files" -> "apply_java" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"jar_files" -> "use_javac_files" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"use_jar_files" -> "jar_files" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}



Feature javac
=============

.. graphviz::

	digraph feature_javac {
	size="8.0, 12.0";
		"process_use" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.process_use",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"init_perlext" [style="setlinewidth(0.5)",URL="tools/perl.html#waflib.Tools.perl.init_perlext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_java" [style="setlinewidth(0.5)",URL="tools/javaw.html#waflib.Tools.javaw.apply_java",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"init_pyext" [style="setlinewidth(0.5)",URL="tools/python.html#waflib.Tools.python.init_pyext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"set_lib_pat" [style="setlinewidth(0.5)",URL="tools/fc_config.html#waflib.Tools.fc_config.set_lib_pat",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"propagate_uselib_vars" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.propagate_uselib_vars",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"init_pyembed" [style="setlinewidth(0.5)",URL="tools/python.html#waflib.Tools.python.init_pyembed",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"use_javac_files" [style="setlinewidth(0.5)",URL="tools/javaw.html#waflib.Tools.javaw.use_javac_files",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"set_classpath" [style="setlinewidth(0.5)",URL="tools/javaw.html#waflib.Tools.javaw.set_classpath",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_bundle" [style="setlinewidth(0.5)",URL="tools/c_osx.html#waflib.Tools.c_osx.apply_bundle",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"propagate_uselib_vars" -> "apply_bundle" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "process_use" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "set_lib_pat" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "init_pyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "init_pyembed" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "init_perlext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"use_javac_files" -> "apply_java" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"set_classpath" -> "apply_java" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"set_classpath" -> "propagate_uselib_vars" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"set_classpath" -> "use_javac_files" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}



Feature link_lib_test
=====================

.. graphviz::

	digraph feature_link_lib_test {
	size="8.0, 12.0";
		"link_lib_test_fun" [style="setlinewidth(0.5)",URL="tools/c_tests.html#waflib.Tools.c_tests.link_lib_test_fun",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	}



Feature link_main_routines_func
===============================

.. graphviz::

	digraph feature_link_main_routines_func {
	size="8.0, 12.0";
		"link_main_routines_tg_method" [style="setlinewidth(0.5)",URL="tools/fc_config.html#waflib.Tools.fc_config.link_main_routines_tg_method",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	}



Feature msgfmt
==============

.. graphviz::

	digraph feature_msgfmt {
	size="8.0, 12.0";
		"apply_msgfmt" [style="setlinewidth(0.5)",URL="tools/kde4.html#waflib.Tools.kde4.apply_msgfmt",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	}



Feature perlext
===============

.. graphviz::

	digraph feature_perlext {
	size="8.0, 12.0";
		"init_perlext" [style="setlinewidth(0.5)",URL="tools/perl.html#waflib.Tools.perl.init_perlext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	}



Feature py
==========

.. graphviz::

	digraph feature_py {
	size="8.0, 12.0";
		"feature_py" [style="setlinewidth(0.5)",URL="tools/python.html#waflib.Tools.python.feature_py",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	}



Feature pyembed
===============

.. graphviz::

	digraph feature_pyembed {
	size="8.0, 12.0";
		"init_pyembed" [style="setlinewidth(0.5)",URL="tools/python.html#waflib.Tools.python.init_pyembed",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	}



Feature pyext
=============

.. graphviz::

	digraph feature_pyext {
	size="8.0, 12.0";
		"set_lib_pat" [style="setlinewidth(0.5)",URL="tools/fc_config.html#waflib.Tools.fc_config.set_lib_pat",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"init_pyext" [style="setlinewidth(0.5)",URL="tools/python.html#waflib.Tools.python.init_pyext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	}



Feature qt4
===========

.. graphviz::

	digraph feature_qt4 {
	size="8.0, 12.0";
		"apply_qt4" [style="setlinewidth(0.5)",URL="tools/qt4.html#waflib.Tools.qt4.apply_qt4",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_link" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_link",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_qt4" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}



Feature rubyext
===============

.. graphviz::

	digraph feature_rubyext {
	size="8.0, 12.0";
		"init_rubyext" [style="setlinewidth(0.5)",URL="tools/ruby.html#waflib.Tools.ruby.init_rubyext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_ruby_so_name" [style="setlinewidth(0.5)",URL="tools/ruby.html#waflib.Tools.ruby.apply_ruby_so_name",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	}



Feature seq
===========

.. graphviz::

	digraph feature_seq {
	size="8.0, 12.0";
		"sequence_order" [style="setlinewidth(0.5)",URL="TaskGen.html#waflib.TaskGen.sequence_order",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	}



Feature subst
=============

.. graphviz::

	digraph feature_subst {
	size="8.0, 12.0";
		"process_subst" [style="setlinewidth(0.5)",URL="TaskGen.html#waflib.TaskGen.process_subst",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	}



Feature test
============

.. graphviz::

	digraph feature_test {
	size="8.0, 12.0";
		"make_test" [style="setlinewidth(0.5)",URL="tools/waf_unit_test.html#waflib.Tools.waf_unit_test.make_test",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_link" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_link",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"make_test" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}



Feature test_exec
=================

.. graphviz::

	digraph feature_test_exec {
	size="8.0, 12.0";
		"apply_link" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_link",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"test_exec_fun" [style="setlinewidth(0.5)",URL="tools/c_config.html#waflib.Tools.c_config.test_exec_fun",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"test_exec_fun" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}



Feature tex
===========

.. graphviz::

	digraph feature_tex {
	size="8.0, 12.0";
		"apply_tex" [style="setlinewidth(0.5)",URL="tools/tex.html#waflib.Tools.tex.apply_tex",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	}



Feature use
===========

.. graphviz::

	digraph feature_use {
	size="8.0, 12.0";
		"process_use" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.process_use",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_link" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_link",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"process_source" [style="setlinewidth(0.5)",URL="TaskGen.html#waflib.TaskGen.process_source",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"process_use" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"process_use" -> "process_source" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}



Feature uselib
==============

.. graphviz::

	digraph feature_uselib {
	size="8.0, 12.0";
		"process_use" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.process_use",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"init_perlext" [style="setlinewidth(0.5)",URL="tools/perl.html#waflib.Tools.perl.init_perlext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"init_pyext" [style="setlinewidth(0.5)",URL="tools/python.html#waflib.Tools.python.init_pyext",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"set_lib_pat" [style="setlinewidth(0.5)",URL="tools/fc_config.html#waflib.Tools.fc_config.set_lib_pat",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"propagate_uselib_vars" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.propagate_uselib_vars",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_bundle" [style="setlinewidth(0.5)",URL="tools/c_osx.html#waflib.Tools.c_osx.apply_bundle",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"init_pyembed" [style="setlinewidth(0.5)",URL="tools/python.html#waflib.Tools.python.init_pyembed",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"propagate_uselib_vars" -> "apply_bundle" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "process_use" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "set_lib_pat" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "init_pyext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "init_pyembed" [arrowsize=0.5,style="setlinewidth(0.5)"];
	"propagate_uselib_vars" -> "init_perlext" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}



Feature vnum
============

.. graphviz::

	digraph feature_vnum {
	size="8.0, 12.0";
		"apply_vnum" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_vnum",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10,fillcolor="#fffea6",style=filled];
	"apply_link" [style="setlinewidth(0.5)",URL="tools/ccroot.html#waflib.Tools.ccroot.apply_link",fontname=Vera Sans, DejaVu Sans, Liberation Sans, Arial, Helvetica, sans,height=0.25,shape=box,fontsize=10];
	"apply_vnum" -> "apply_link" [arrowsize=0.5,style="setlinewidth(0.5)"];
	}


