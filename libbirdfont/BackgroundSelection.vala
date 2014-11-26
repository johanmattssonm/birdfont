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

public class BackgroundSelection : GLib.Object {
	
	public string? assigned_glyph;
	public BackgroundImage? image;
	public BackgroundImage parent_image;
	
	public double x {
		get {
			return x_img * parent_image.img_scale_x + parent_image.img_middle_x;
		}
		
		set {
			x_img = value / parent_image.img_scale_x - parent_image.img_middle_x;
		}
	}
	
	public double y {
		get {
			return y_img * parent_image.img_scale_y + parent_image.img_middle_y;
		}
		
		set {
			y_img = (value - parent_image.img_middle_y) / parent_image.img_scale_y;
		}
	}
	
	public double w {
		get {
			return width * parent_image.img_scale_x;
		}
		
		set {
			width = value / parent_image.img_scale_x;
		}
	}
	
	public double h {
		get {
			return height * parent_image.img_scale_y;
		}
		
		set {
			height = value / parent_image.img_scale_y;
		}
	}
	
	private double height;
	private double width;
	private double x_img;
	private double y_img;
	
	public BackgroundSelection (BackgroundImage? img, BackgroundImage parent_img,
		double x, double y, double w, double h) {
			
		assigned_glyph = null;
		parent_image = parent_img;
		image = img;
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
	}
}

}
