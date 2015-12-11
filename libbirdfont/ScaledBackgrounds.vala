/*
	Copyright (C) 2015 Johan Mattsson

	This library is free software; you can redistribute it and/or modify 
	it under the terms of the GNU Lesser General Public License as 
	published by the Free Software Foundation; either version 3 of the 
	License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful, but 
	WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
	Lesser General Public License for more details.
*/

using Cairo;
using Math;
using Gee;

namespace BirdFont {

public class ScaledBackgrounds : GLib.Object {
	ImageSurface original;
	ArrayList<ScaledBackground> scaled;
	
	public ScaledBackgrounds (ImageSurface original) {
		this.original = original;
		scaled = new ArrayList<ScaledBackground> ();

		ScaledBackground image = scale (0.01);
		scaled.add (image);
					
		for (double scale_factor = 0.1; scale_factor <= 1; scale_factor += 0.1) {
			image = scale (scale_factor);
			scaled.add (image);
		}
	}

	public ScaledBackgrounds.single_size (ImageSurface original, double scale_factor) {
		this.original = original;
		scaled = new ArrayList<ScaledBackground> ();

		ScaledBackground image = scale (scale_factor);
		scaled.add (image);
	}
	
	public ScaledBackground get_image (double scale) {
		foreach (ScaledBackground image in scaled) {
			if (image.get_scale () < scale) {
				continue;
			}
			
			return image;
		}

		return scaled.get (scaled.size - 1);
	}

	private ScaledBackground scale (double scale_factor) {
		ImageSurface scaled_image;
		
		if (scale_factor <= 0) {
			warning ("scale_factor <= 0");
			scale_factor = 1;
		}
		
		int width = (int) (scale_factor * original.get_width ());
		int height = (int) (scale_factor * original.get_height ());
		scaled_image = new ImageSurface (Format.ARGB32, width, height);
		Context context = new Context (scaled_image);
		context.scale (scale_factor, scale_factor);
		context.set_source_surface (original, 0, 0);
		context.paint ();
		
		return new ScaledBackground (scaled_image, scale_factor);
	}
}

}
