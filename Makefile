SHELL = /bin/bash
EMSDK_ENV = emsdk/emsdk_env.sh
VEROVIO_DIR = verovio
SRC = src/mozart.cpp
INIT_SRC = src/mozart_init.cpp
OUT = mozart/mozart.wasm

# Verovio source files (core library)
VEROVIO_SRC = $(wildcard $(VEROVIO_DIR)/src/*.cpp) \
              $(wildcard $(VEROVIO_DIR)/src/hum/*.cpp) \
              $(VEROVIO_DIR)/src/pugi/pugixml.cpp \
              $(VEROVIO_DIR)/src/json/jsonxx.cc \
              $(VEROVIO_DIR)/src/crc/crc.cpp \
              $(wildcard $(VEROVIO_DIR)/libmei/dist/*.cpp) \
              $(VEROVIO_DIR)/libmei/addons/att.cpp \
              $(VEROVIO_DIR)/tools/c_wrapper.cpp

VEROVIO_INCLUDES = -Isrc \
                   -I$(VEROVIO_DIR)/include \
                   -I$(VEROVIO_DIR)/include/vrv \
                   -I$(VEROVIO_DIR)/include/hum \
                   -I$(VEROVIO_DIR)/include/json \
                   -I$(VEROVIO_DIR)/include/midi \
                   -I$(VEROVIO_DIR)/include/pugi \
                   -I$(VEROVIO_DIR)/include/zip \
                   -I$(VEROVIO_DIR)/include/crc \
                   -I$(VEROVIO_DIR)/include/tuning-library \
                   -I$(VEROVIO_DIR)/libmei/dist \
                   -I$(VEROVIO_DIR)/libmei/addons \
                   -I$(VEROVIO_DIR)/tools

LINK_FLAGS = --no-entry \
             -s WASM=1 \
             -s INITIAL_MEMORY=268435456 \
             -s ALLOW_MEMORY_GROWTH=1 \
             -s STACK_SIZE=134217728 \
             -s ERROR_ON_UNDEFINED_SYMBOLS=0 \
             -s EXPORTED_FUNCTIONS='["_hello","_render","_render_page","_page_count","_malloc","_free"]'

.PHONY: all clean clone build install

all: build

clone:
	@if [ ! -d "$(VEROVIO_DIR)" ]; then \
		echo "Cloning verovio..."; \
		git clone --depth 1 https://github.com/rism-digital/verovio.git $(VEROVIO_DIR); \
	else \
		echo "Verovio already cloned."; \
	fi

build: clone
	@mkdir -p build
	source $(EMSDK_ENV) 2>/dev/null && \
		emcc -O3 -DNDEBUG -std=c++20 $(VEROVIO_INCLUDES) -c $(SRC) -o build/mozart.o && \
		emcc -O3 -DNDEBUG -std=c++20 $(LINK_FLAGS) $(VEROVIO_INCLUDES) \
			-o $(OUT) build/mozart.o $(INIT_SRC) $(VEROVIO_SRC)
	wasi-stub $(OUT) -o $(OUT) --stub-module env,wasi_snapshot_preview1 -r 0

install: build
	mkdir -p ~/.local/share/typst/packages/local/mozart/0.1.0
	cp mozart/mozart.wasm mozart/mozart.typ mozart/typst.toml \
		~/.local/share/typst/packages/local/mozart/0.1.0/

clean:
	rm -f $(OUT) build/*.o
