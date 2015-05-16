LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE    := birdfont

LOCAL_CFLAGS    := -D 'GETTEXT_PACKAGE="birdfont"'
LOCAL_CFLAGS    += -Wno-missing-field-initializers 
LOCAL_CFLAGS    += -I $(LOCAL_PATH)
LOCAL_CFLAGS    += -I ../../libbirdxml
LOCAL_CFLAGS    += -I ../../libbirdgems
LOCAL_CFLAGS    += -I /opt/android/include 
LOCAL_CFLAGS    += -I /opt/android/include/glib-2.0
LOCAL_CFLAGS    += -I /opt/android/lib/glib-2.0/include
LOCAL_CFLAGS    += -I /opt/android/include/gee-1.0
LOCAL_CFLAGS    += -I /opt/android/include/freetype
LOCAL_CFLAGS    += -I /opt/android/include/cairo


#FIXME: $(TARGET_ARCH_ABI)

LOCAL_LDLIBS	+= -L/opt/android/lib
LOCAL_LDLIBS    += -lsqliteX
LOCAL_LDLIBS    += -ljava-bitmap 
LOCAL_LDLIBS    += -lgee
LOCAL_LDLIBS    += -lft2
LOCAL_LDLIBS    += -lglib-2.0
LOCAL_LDLIBS    += -lgio-2.0
LOCAL_LDLIBS    += -lintl
LOCAL_LDLIBS    += -liconv
LOCAL_LDLIBS    += -lgobject-2.0

LOCAL_LDLIBS    += -lm
LOCAL_LDLIBS    += -lc
LOCAL_LDLIBS    += -lz
LOCAL_LDLIBS    += -llog

LOCAL_LDLIBS	+= -L $(LOCAL_PATH)/../../
LOCAL_LDLIBS    += -lbirdxml
LOCAL_LDLIBS    += -lbirdgems

LOCAL_SRC_FILES := $(wildcard *.c) 

include $(BUILD_SHARED_LIBRARY)

$(call import-module,android/cpufeatures)
