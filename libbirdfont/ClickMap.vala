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

// This is a refcounted container in order to avoid double free 
// corruption in lambda functions.
public class ClickMap : GLib.Object {
	char* map;
	int width;
	int margin;
	int map_size;

	public ClickMap (int width) {
		this.width = width;
		margin = 10;
		map_size = width + margin;
		map = malloc (map_size * map_size);
	}
	
	~ClickMap () {
		delete map;
	}
	
	public char get_value (int x, int y) {
		
		if (unlikely (!(0 <= x < map_size && 0 <= y < map_size))) {
			warning ("Array index out of bounds.");
			return '\0';
		}
		
		return map[y * width + x];
	}
	
	public void set_value (int x, int y, char val) {
		if (unlikely (!(0 <= x < map_size && 0 <= y < map_size))) {
			warning ("Array index out of bounds.");
			return;
		}
		
		map[y * width + x] = val;
	}

	private void map_outline (Path path) {
		path.all_of_path ((cx, cy, ct) => {
			int px = (int) (width * ((cx - path.xmin) / (path.xmax - path.xmin)));
			int py = (int) (width * ((cy - path.ymin) / (path.ymax - path.ymin)));
			
			set_value (px, py, '#');
			
			return true;
		}, 2 * width);
	}

	private void close_outline (Path path) {
		// first to last point in case the path is open
		Path.all_of (path.get_last_point (), path.get_first_point (), (cx, cy, ct) => {
			int px = (int) (width * ((cx - path.xmin) / (path.xmax - path.xmin)));
			int py = (int) (width * ((cy - path.ymin) / (path.ymax - path.ymin)));
			
			set_value (px, py, '#');
			
			return true;
		}, 2 * width);
	}
	
	public void create_click_map (Path path) {
		// Clear the map
		for (int i = 0; i < map_size; i++) {
			for (int j = 0; j < map_size; j++) {
				set_value (i, j, '\0');
			}
		}
		
		// Create outline
		map_outline (path);
		close_outline (path);
		
		// Fill the map
		for (int j = 0; j < width; j++) {
			for (int k = 0; k < width; k++) {
				if (get_value (k, j) == '#') {
					
					k++;
					while (k < width && get_value (k, j) == '#') {
						k++;
					}

					while (k < width && get_value (k, j) == '\0') {
						set_value (k, j, 'o');
						k++;
					}

					k++;
					while (k < width && get_value (k, j) == '#') {
						k++;
					}
				}
			}
		}

		// Remove fill from the out side
		for (int k = 0; k < width; k++) {
			
			if (get_value (k, 0) == 'o') {
				set_value (k, 0, '\0'); 
			}
			
			for (int l = width - 1; l >= 0; l--) {
				if (get_value (k, l) != '#') {
					if (get_value (k, l + 1) == '\0') {
						set_value (k, l, '\0');
					}
					
					if (get_value (k, l + 1) == 'o') {
						set_value (k, l, 'o');
					}
				}
			}
		} 

		for (int k = 0; k < width; k++) {
			if (get_value (0, k) == 'o') {
				set_value (0, k,'\0'); 
			}
			
			for (int l = width - 1; l >= 0; l--) {
				if (get_value (l, k) != '#') {
					if (get_value (l + 1, k) == '\0') {
						set_value (l, k, '\0');
					}
					
					if (get_value (l + 1, k) == 'o') {
						set_value (l, k, 'o');
					}
				}
			}
		}

		for (int k = width - 1; k > 0; k--) {
			if (get_value (k, 0) == 'o') {
				set_value (k, 0,'\0'); 
			}
			
			for (int l = width - 1; l >= 0; l--) {
				if (get_value (k, l) != '#') {				
					if (get_value (k, l + 1) == 'o') {
						set_value (k, l, 'o');
					}
				}
			}
		}
	}
	
	public void print () {
		char c;
		for (int i = width - 1; i >= 0; i--) {
			for (int j = 0; j < width; j++) {
				c = get_value (j, i);
				if (c == '\0') {
					stdout.printf (" ");
				} else if (c == '#') {
					stdout.printf ("#");
				} else if (c == 'o') {
					stdout.printf ("o");
				} else if (c == 'X') {
					stdout.printf ("X");
				} else {
					stdout.printf ("?");
				}
			}
			
			stdout.printf ("\n");
		}
	}
}

}
