/*
 * BirdFont code from SVG Salamander
 * 
 * Copyright (c) 2004, Mark McKay
 * Copyright (c) 2014, Johan Mattsson
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or 
 * without modification, are permitted provided that the following
 * conditions are met:
 *
 *   - Redistributions of source code must retain the above 
 *     copyright notice, this list of conditions and the following
 *     disclaimer.
 *   - Redistributions in binary form must reproduce the above
 *     copyright notice, this list of conditions and the following
 *     disclaimer in the documentation and/or other materials 
 *     provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE. 
 * 
 * Mark McKay can be contacted at mark@kitfox.com.  Salamander and other
 * projects can be found at http://www.kitfox.com
 *
 * Created on January 26, 2004, 8:40 PM
 * Adapded to BirdFont on Juli 2, 2014, 5:01 PM
 */

using Math;

namespace BirdFont {

/** Convert an SVG arc instruction to a Beziér path. */
static void add_arc_points (BezierPoints[] bezier_points, ref int bi, double x0, double y0, double rx, double ry, double angle, bool largeArcFlag, bool sweepFlag, double x, double y) {

	//
	// Elliptical arc implementation based on the SVG specification notes
	//

	double dx2, dy2, cosAngle, sinAngle;
	double x1, y1, Prx, Pry, Px1, Py1, radiiCheck;
	double sign, sq, coef, cx1, cy1;
	double sx2, sy2, cx, cy;
	double ux, uy, vx, vy, p, n;
	double angleStart, angleExtent;
	double s, step, theta;
	
	// Compute the half distance between the current and the final point
	dx2 = (x0 - x) / 2.0;
	dy2 = (y0 - y) / 2.0;
	
	// Convert angle from degrees to radians
	angle = 2 * PI * ((angle % 360.0) / 360.0);
	
	cosAngle = cos (angle);
	sinAngle = sin (angle);

	//
	// Step 1 : Compute (x1, y1)
	//
	x1 = cosAngle * dx2 + sinAngle * dy2;
	y1 = -sinAngle * dx2 + cosAngle * dy2;
	
	// Ensure radii are large enough
	rx = fabs(rx);
	ry = fabs(ry);
	Prx = rx * rx;
	Pry = ry * ry;
	Px1 = x1 * x1;
	Py1 = y1 * y1;

	
	// Check that radii are large enough
	radiiCheck = Px1 / Prx + Py1 / Pry;
	
	if (radiiCheck > 1) {
		rx = sqrt (radiiCheck) * rx;
		ry = sqrt (radiiCheck) * ry;
		Prx = rx * rx;
		Pry = ry * ry;
	}

	//
	// Step 2 : Compute (cx1, cy1)
	//
	sign = (largeArcFlag == sweepFlag) ? -1 : 1;
	sq = ((Prx * Pry) - (Prx * Py1) - (Pry * Px1)) / ((Prx * Py1) + (Pry * Px1));
	sq = (sq < 0) ? 0 : sq;
	coef = (sign * Math.sqrt(sq));
	cx1 = coef * ((rx * y1) / ry);
	cy1 = coef * -((ry * x1) / rx);

	//
	// Step 3 : Compute (cx, cy) from (cx1, cy1)
	//
	
	sx2 = (x0 + x) / 2.0;
	sy2 = (y0 + y) / 2.0;
	cx = sx2 - (cosAngle * cx1 - sinAngle * cy1);
	cy = sy2 - (sinAngle * cx1 + cosAngle * cy1);

	//
	// Step 4 : Compute the angleStart (angle1) and the angleExtent (dangle)
	//
	
	ux = (x1 - cx1) / rx;
	uy = (y1 - cy1) / ry;
	vx = (-x1 - cx1) / rx;
	vy = (-y1 - cy1) / ry;

	// Compute the angle start
	n = sqrt((ux * ux) + (uy * uy));
	p = ux; // (1 * ux) + (0 * uy)
	sign = (uy < 0) ? -1d : 1d;
	angleStart = sign * acos(p / n);

	// Compute the angle extent
	n = Math.sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy));
	p = ux * vx + uy * vy;
	sign = (ux * vy - uy * vx < 0) ? -1d : 1d;
	angleExtent = sign * Math.acos(p / n);
	
	if(!sweepFlag && angleExtent > 0) {
		angleExtent -= 2 *PI;
	} else if (sweepFlag && angleExtent < 0) {
		angleExtent += 2 *PI;
	}
	angleExtent %= 2 * PI;
	angleStart %= 2 * PI;

	angleExtent *= -1;
	angleStart *= -1;
	
	// Approximate the path with Beziér points
	s = (angleExtent > 0) ? 1 : -1;
	step = fabs (angleExtent) / (2 * fabs (angleExtent));

	theta = PI - angleStart - angleExtent;
	
	bezier_points[bi].type = 'L';
	bezier_points[bi].svg_type = 'a';

	bezier_points[bi].x0 = cx + rx * cos (theta);
	bezier_points[bi].y0 = cy + ry * sin (theta);
									
	bi++;
					
	for (double a = 0; a < fabs (angleExtent); a += step) {
		theta = PI - angleStart - angleExtent + s * a;

		return_if_fail (0 <= bi < bezier_points.length);

		bezier_points[bi].type = 'S';
		bezier_points[bi].svg_type = 'a';

		bezier_points[bi].x0 = cx + rx * cos (theta);
		bezier_points[bi].y0 = cy + ry * sin (theta);

		bezier_points[bi].x1 = cx + rx * cos (theta + 1 * step / 4);
		bezier_points[bi].y1 = cy + ry * sin (theta + 1 * step / 4);
		
		bezier_points[bi].x2 = cx + rx * cos (theta + 2 * step / 4);
		bezier_points[bi].y2 = cy + ry * sin (theta + 2 * step / 4);
						
		bi++;
	}
}

}
	
