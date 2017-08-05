/*
	Copyright (C) 2012, 2013 Johan Mattsson

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

/** Reader for otf data types. */
public class OtfInputStream : Object  {
	
	public FileInputStream fin;
	public DataInputStream din;
	
	public OtfInputStream (FileInputStream i) throws Error {
		din = new DataInputStream (i);
		fin = i;
	}
	
	public void seek (int64 pos) throws Error
		requires (fin.can_seek ()) {
		int64 p = fin.tell ();		
		fin.seek (pos - p, SeekType.CUR);
	}

	public uint8 read_byte () throws Error {
		return din.read_byte ();
	}
	
	public void close () {
		try {
			fin.close ();
			din.close ();
		} catch (GLib.IOError e) {
			warning (e.message);
		}
	}
}

}
