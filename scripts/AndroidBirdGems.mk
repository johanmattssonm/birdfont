LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE    := birdgems

LOCAL_CFLAGS    += -Wno-missing-field-initializers 
LOCAL_CFLAGS    += -I ../
LOCAL_CFLAGS    += -I /opt/android/include 
LOCAL_CFLAGS    += -I /opt/android/include/glib-2.0
LOCAL_CFLAGS    += -I /opt/android/lib/glib-2.0/include

#FIXME: $(TARGET_ARCH_ABI)

LOCAL_LDLIBS	+= -L/opt/android/lib
LOCAL_LDLIBS    += -lglib-2.0
LOCAL_LDLIBS    += -lintl
LOCAL_LDLIBS    += -liconv
LOCAL_LDLIBS    += -lgobject-2.0

LOCAL_LDLIBS    += -lm
LOCAL_LDLIBS    += -lc
LOCAL_LDLIBS    += -llog

LOCAL_SRC_FILES := $(wildcard *.c) 

include $(BUILD_SHARED_LIBRARY)

$(call import-module,android/cpufeatures)
