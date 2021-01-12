#
# Makefile to use with emscripten
# See https://emscripten.org/docs/getting_started/downloads.html
# for installation instructions.
#
# This Makefile assumes you have loaded emscripten's environment.
# (On Windows, you may need to execute emsdk_env.bat or encmdprompt.bat ahead)
#
# Running `make` will produce three files:
#  - libigl-example.html
#  - libigl-example.js
#  - libigl-example.wasm
#
# All three are needed to run the demo.

USE_BARYCENTRIC = 0
USE_EMSCRIPTEN = 1
ifeq ($(USE_EMSCRIPTEN), 1)
CC = emcc
CXX = em++
EXE = libigl-example.html
else
CC = clang-12
CXX = clang++-12
EXE = libigl-example
endif

LIBIGL-DIR=../libigl
IMGUI-DIR=$(LIBIGL-DIR)/external/imgui
IMGUI-EXAMPLES-DIR=$(IMGUI-DIR)/examples
SOURCES = eh.cpp
#SOURCES += 
SOURCES += $(IMGUI-EXAMPLES-DIR)/imgui_impl_sdl.cpp $(IMGUI-EXAMPLES-DIR)/imgui_impl_glfw.cpp $(IMGUI-EXAMPLES-DIR)/imgui_impl_opengl3.cpp $(IMGUI-EXAMPLES-DIR)/imgui.cpp
SOURCES += $(IMGUI-DIR)/imgui.cpp $(IMGUI-DIR)/imgui_demo.cpp $(IMGUI-DIR)/imgui_draw.cpp $(IMGUI-DIR)/imgui_widgets.cpp

GLFW-SOURCES =
#init.c window.c monitor.c context.c input.c posix_thread.c x11_init.c posix_time.c null_monitor.c
GLAD-SOURCES = glad.c

SOURCES += $(addprefix $(LIBIGL-DIR)/external/glfw/src/, $(GLFW-SOURCES))
SOURCES += $(addprefix $(LIBIGL-DIR)/external/glad/src/, $(GLAD-SOURCES))

OBJS = $(addsuffix .o, $(basename $(notdir $(SOURCES))))
UNAME_S := $(shell uname -s)

##---------------------------------------------------------------------
## EMSCRIPTEN OPTIONS
##---------------------------------------------------------------------

EMS += -s USE_SDL=2 -s WASM=1
EMS += -s ALLOW_MEMORY_GROWTH=1
EMS += -s DISABLE_EXCEPTION_CATCHING=2 -s NO_EXIT_RUNTIME=0
EMS += -s ASSERTIONS=1
EMS += -s USE_GLFW=3 -s USE_WEBGL2=1

# Uncomment next line to fix possible rendering bugs with Emscripten version older then 1.39.0 (https://github.com/ocornut/imgui/issues/2877)
#EMS += -s BINARYEN_TRAP_MODE=clamp
#EMS += -s SAFE_HEAP=1    ## Adds overhead

# Emscripten allows preloading a file or folder to be accessible at runtime.
# The Makefile for this example project suggests embedding the misc/fonts/ folder into our application, it will then be accessible as "/fonts"
# See documentation for more details: https://emscripten.org/docs/porting/files/packaging_files.html
# (Default value is 0. Set to 1 to enable file-system and include the misc/fonts/ folder as part of the build.)
USE_FILE_SYSTEM = 1
ifeq ($(USE_FILE_SYSTEM), 0)
EMS += -s NO_FILESYSTEM=1 -DIMGUI_DISABLE_FILE_FUNCTIONS
endif

ifeq ($(USE_EMSCRIPTEN), 1)
ifeq ($(USE_FILE_SYSTEM), 1)
LDFLAGS += --no-heap-copy --preload-file $(IMGUI-DIR)/misc/fonts@/fonts --preload-file $(LIBIGL-DIR)/tutorial/data/bunny.off@/bunny.off --emrun
endif
endif

##---------------------------------------------------------------------
## FINAL BUILD FLAGS
##---------------------------------------------------------------------
# -D __glad_h_
#CPPFLAGS += -I../ -I../../ -I$(LIBIGL-DIR)/include
CPPFLAGS += -I$(LIBIGL-DIR)/include \
-D FULL_ES3=1 -D MIN_WEBGL_VERSION=2 -D MAX_WEBGL_VERSION=2 \
-D GLFW_INCLUDE_ES32 \
-D IMGUI_IMPL_OPENGL_ES3 \
-D USE_BARYCENTRIC=$(USE_BARYCENTRIC) \
-isystem$(LIBIGL-DIR)/external/eigen \
-isystem$(LIBIGL-DIR)/external/glfw/include \
-isystem$(LIBIGL-DIR)/external \
-isystem$(LIBIGL-DIR)/external/imgui/examples \
-isystem$(LIBIGL-DIR)/external/imgui \
-isystem$(LIBIGL-DIR)/external/libigl-imgui \
-isystem$(LIBIGL-DIR)/external/glad/include \
-I $(LIBIGL-DIR)/include/igl/opengl \
-I $(EMSDK)/upstream/emscripten/system/include/emscripten

CPPFLAGS_UNUSED = \
-isystem$(LIBIGL-DIR)/external/glad/include \
-isystem$(LIBIGL-DIR)/external/glfw/include \
-isystem$(EMSDK)/fastcomp/emscripten/system/include \
-isystem$(EMSDK)/fastcomp/emscripten/system/include/libc \
-isystem/usr/include \
-isystem/usr/include/x86_64-linux-gnu \
-I $(LIBIGL-DIR)/include/igl/opengl/glfw \
-I $(LIBIGL-DIR)/include/igl/opengl/glfw/imgui \
-D GLFW_INCLUDE_GLCOREARB

#CPPFLAGS += -g
#CPPFLAGS += -D __EMSCRIPTEN__
CPPFLAGS += -Wall -Wformat -g -O0 -D _GLFW_X11
# -s WEBGL2_BACKWARDS_COMPATIBILITY_EMULATION=1
ifeq ($(USE_EMSCRIPTEN), 1)
CPPFLAGS += -I $(EMSDK)/upstream/emscripten/system/include $(EMS)
LIBS += $(EMS)
LDFLAGS += --shell-file shell_minimal.html -s LLD_REPORT_UNDEFINED -g
else
CPPFLAGS := -I /usr/include $(CPPFLAGS) -pthread -ggdb
LDFLAGS += -lSDL2 -lpthread -L$(LIBIGL-DIR)/build -ligl_opengl_glfw -ligl_opengl_glfw_imgui -lglfw -lGL -ldl `sdl2-config --libs` -ggdb
endif

##---------------------------------------------------------------------
## BUILD RULES
##---------------------------------------------------------------------

%.o:%.cpp
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<

%.o:$(IMGUI-DIR)/%.cpp
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<

%.o:$(IMGUI-EXAMPLES-DIR)/%.cpp
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<

%.o:$(LIBIGL-DIR)/external/glfw/src/%.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

%.o:$(LIBIGL-DIR)/external/glad/src/%.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

all: $(EXE)
	@echo Build complete for $(EXE)

$(EXE): $(OBJS)
	$(CXX) -o $@ $^ $(LIBS) $(LDFLAGS)

clean:
	rm -f $(EXE) $(OBJS) *.js *.wasm *.wasm.pre
