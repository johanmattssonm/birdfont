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
	
/** A faster implementation of the Path and EditPoint classes. */
public class FastPath : GLib.Object {
	
	/** Control points and control point handles.
	 * 
	 * Each point is stored with left handle at index - 2,
	 * the point at index, and right handle at index + 2. Both x and y
	 * coordinates is stores in this array.
	 */
	double* points;
	
	/** Point types. */
	uint* types;
	
	/** The number of points that can be stored in the point array. */
	int capacity;
		
	public static const uint NUMBERS_PER_POINT = 6;

	public static const uint LEFT_HANDLE_POS_X = 0;
	public static const uint LEFT_HANDLE_POS_Y = 1;
	public static const uint POS_X = 2;
	public static const uint POS_Y = 3;
	public static const uint RIGHT_HANDLE_POS_X = 4;
	public static const uint RIGHT_HANDLE_POS_Y = 5;

	/** Various boolean properties */
	uint* flags;

	public static uint ACTIVE = 1 << 0;
	public static uint SELECTED = 1 << 1;
	public static uint DELETED = 1 << 2;
	
	public static uint TIE_HANDLES = 1 << 3;
	public static uint REFLECTIVE_HANDLES = 1 << 4;
	
	/** Number of control points in this path. */
	int number_of_points = 0;
	
	public FastPath () {
		capacity = 1024;
		points = new double[capacity * NUMBERS_PER_POINT];
		types = new uint[capacity];
	}

	~FastPath () {
		delete points;
		delete types;
	}
					
	/** @return number of control points in this path. */
	public int get_length () {
		return number_of_points;
	}
	
	/** Get a slow representation for an edipoint. */
	public EditPoint get_editpoint (int index) {
		EditPoint ep = new EditPoint (get_x (index), get_y (index), get_point_type (index));
		ep.get_left_handle ().move_to_coordinate (get_left_handle_x (index), get_left_handle_y (index));
		ep.get_right_handle ().move_to_coordinate (get_right_handle_x (index), get_right_handle_y (index));		
		return ep;
	}

	public void set_editpoint (int index, EditPoint ep) {
		points[NUMBERS_PER_POINT * index + POS_X] = ep.x;
		points[NUMBERS_PER_POINT * index + POS_Y] = ep.y;
		points[NUMBERS_PER_POINT * index + LEFT_HANDLE_POS_X] = ep.get_left_handle ().x ();
		points[NUMBERS_PER_POINT * index + LEFT_HANDLE_POS_Y] = ep.get_left_handle ().y ();
		points[NUMBERS_PER_POINT * index + RIGHT_HANDLE_POS_X] = ep.get_right_handle ().x ();
		points[NUMBERS_PER_POINT * index + RIGHT_HANDLE_POS_Y] = ep.get_right_handle ().y ();
	}

	public double get_x (int index) {
		return points[NUMBERS_PER_POINT * index + POS_X];
	}
	
	public double get_y (int  index) {
		return points[NUMBERS_PER_POINT * index + POS_Y];
	}

	public double get_left_handle_x (int index) {
		return points[NUMBERS_PER_POINT * index + LEFT_HANDLE_POS_X];
	}
	
	public double get_left_handle_y (int  index) {
		return points[NUMBERS_PER_POINT * index + LEFT_HANDLE_POS_Y];
	}

	public double get_right_handle_x (int index) {
		return points[NUMBERS_PER_POINT * index + RIGHT_HANDLE_POS_X];
	}
	
	public double get_right_handle_y (int  index) {
		return points[NUMBERS_PER_POINT * index + RIGHT_HANDLE_POS_Y];
	}
			
	public PointType get_point_type (int index) {
		return (PointType) types[index];
	}

	public bool is_active (int index) {
		return (flags[index] & ACTIVE) > 0;
	}

	public bool is_selected (int index) {
		return (flags[index] & SELECTED) > 0;
	}

	public bool is_deleted (int index) {
		return (flags[index] & DELETED) > 0;
	}

	public bool has_tied_handles (int index) {
		return (flags[index] & TIE_HANDLES) > 0;
	}

	public bool has_reflective_handles (int index) {
		return (flags[index] & REFLECTIVE_HANDLES) > 0;
	}
}

}
