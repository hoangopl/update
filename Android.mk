LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE := main
LOCAL_SRC_FILES := wrapper.cpp
LOCAL_LDLIBS := -llog
include $(BUILD_SHARED_LIBRARY)
