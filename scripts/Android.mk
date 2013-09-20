LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE    := birdfont

LOCAL_CFLAGS    := -D 'GETTEXT_PACKAGE="birdfont"'
LOCAL_CFLAGS    += -Wno-missing-field-initializers 
LOCAL_CFLAGS    += -I. 
LOCAL_CFLAGS    += -I /opt/android/include 
LOCAL_CFLAGS    += -I /opt/android/include/glib-2.0
LOCAL_CFLAGS    += -I /opt/android/include/libxml2
LOCAL_CFLAGS    += -I /opt/android/include/gee-1.0
LOCAL_CFLAGS    += -I /opt/android/include/freetype

LOCAL_LDLIBS	+= -L/opt/android/lib/$(TARGET_ARCH_ABI) 
LOCAL_LDLIBS    += -lm 
LOCAL_LDLIBS    += -lc 
LOCAL_LDLIBS    += -llog
LOCAL_LDLIBS    += -ljava-bitmap
LOCAL_LDLIBS	+= -lxml2
LOCAL_LDLIBS	+= -lgee
LOCAL_LDLIBS	+= -lft2
LOCAL_LDLIBS	+= -lglib-2.0-tarnyko

LOCAL_SRC_FILES := $(wildcard *.c) 

include $(BUILD_SHARED_LIBRARY)

$(call import-module,android/cpufeatures)
