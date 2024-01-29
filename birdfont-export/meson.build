source = files ('BirdfontExport.vala')

#deps = [dependencies,
#  dependency('cairo'),
#  dependency('gio-2.0'),
#  dependency('gee-0.8'),
#  dependency('xmlbird'),
#]


executable('birdfont-export', 
  sources: source, 
  dependencies: [dependencies, deps1,  inc_rooth_dep], 
  link_with: [libbirdfont],
  install : true,
  )
