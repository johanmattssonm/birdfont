all:
	./configure
	./build.py

install:
	./install.py -d $(DESTDIR)
