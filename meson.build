project(
  'birdfont',
  'c', 'vala',
   version: '2.30.0',
   license: ['GPLv3', 'LGPL3']
)
PROJECT_VERSION = meson.project_version ()
add_project_arguments('-DGETTEXT_PACKAGE="birdfont"', language:'c')

vapi_dir = meson.current_source_dir() 
add_project_arguments(['--vapidir', vapi_dir], language: 'vala')




dependencies = [
    meson.get_compiler('c').find_library('m', required: false),
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
]

deps1 = [
    dependency('cairo'),
    dependency('gio-2.0'),
    dependency('gee-0.8'),
    dependency('xmlbird'),
]
deps2 = [
    dependency('webkit2gtk-4.0'),
    dependency('libnotify'),
    dependency('sqlite3'),
    dependency('fontconfig'),
]

inc_rooth = include_directories ('.')
inc_rooth_dep = declare_dependency (include_directories : inc_rooth)

subdir('po')
subdir('libbirdgems')
subdir('libbirdfont')
subdir('birdfont')
subdir('birdfont-export')
subdir('birdfont-import')
subdir('birdfont-autotrace')
subdir('birdfont-test')
subdir('resources')
