[CCode (cname = "ANDROID_LOG_WARN", cheader_filename = "android/log.h")]
public extern static const int ANDROID_LOG_WARN;

[CCode (cname = "ANDROID_LOG_INFO", cheader_filename = "android/log.h")]
public extern static const int ANDROID_LOG_INFO;

[CCode (cname = "__android_log_print", cheader_filename = "android/log.h")]
public extern static int __android_log_print (int prio, string tag,  string fmt, ...);
