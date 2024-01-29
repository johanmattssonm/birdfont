shared = files(
  'linux/birdfont_window_icon.png',
  'bright.theme',
  'codepages.sqlite',
  'dark.theme',
  'high_contrast.theme',
  'icons.birdfont',
  'key_bindings.xml','Roboto-Regular.ttf','ucd.sqlite')

manpages = files(
  'linux/birdfont.1',
  'linux/birdfont-autotrace.1',
  'linux/birdfont-export.1',
  'linux/birdfont-import.1'
)
install_data(shared, install_dir : 'share/birdfont')
install_man(manpages)
