source = files (
  'birdgems.vala',
  'fit_cubic.c',
  'GGVecLib.c',
  'GraphicsGems.h'
  )

libgems = shared_library('gems', 
  sources : source,
  vala_header: vapi_dir/'birdgems.h',
  vala_vapi: vapi_dir/'gems.vapi',
  dependencies: dependencies,
  install : true,
)

