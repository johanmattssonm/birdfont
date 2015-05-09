namespace Gems {

[CCode (cname = "fit_bezier_curve_to_line")]
public extern static int fit_bezier_curve_to_line (double[] lines, double error, out double[] bezier_curve);

}
