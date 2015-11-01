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

namespace BirdFont {

class MergeTask : StrokeTask {
	StrokeTool stroke_tool;
	
	public MergeTask () {
		base.none ();
		stroke_tool = new StrokeTool.with_task (this);
	}
	
	public override void run () {
		stroke_tool.merge_selected_paths ();			
	}
}

}
