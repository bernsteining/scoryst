VEROVIO_DIR = verovio
DOCKER_IMAGE = verovio-builder
OUT = pkg/verovio.wasm
BUILD_DIR = pkg/obj

# Optimization: -Os balances size and speed; override with `make OPT=-O0` for fast dev builds
OPT = -Os

CXXFLAGS = $(OPT) -DNDEBUG -std=c++20 -DPUGIXML_NO_EXCEPTIONS

# All source files
PLUGIN_SRC = src/verovio_plugin.cpp
INIT_SRC = src/verovio_init.cpp
VEROVIO_SRC = $(wildcard $(VEROVIO_DIR)/src/*.cpp) \
              $(wildcard $(VEROVIO_DIR)/src/hum/*.cpp) \
              $(VEROVIO_DIR)/src/pugi/pugixml.cpp \
              $(VEROVIO_DIR)/src/json/jsonxx.cc \
              $(VEROVIO_DIR)/src/crc/crc.cpp \
              $(wildcard $(VEROVIO_DIR)/libmei/dist/*.cpp) \
              $(VEROVIO_DIR)/libmei/addons/att.cpp \
              $(VEROVIO_DIR)/tools/c_wrapper.cpp
ALL_SRC = $(PLUGIN_SRC) $(INIT_SRC) $(VEROVIO_SRC)

# Object files mirroring source tree under BUILD_DIR
ALL_OBJ = $(patsubst %.cpp,$(BUILD_DIR)/%.o,$(patsubst %.cc,$(BUILD_DIR)/%.o,$(ALL_SRC))) \
          $(BUILD_DIR)/src/verovio_data.o

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
             -s EXPORTED_FUNCTIONS='["_render","_render_page","_page_count","_malloc","_free"]'

WASM_OPT_FLAGS = -O3 --enable-simd --enable-bulk-memory --enable-sign-ext \
                 --enable-nontrapping-float-to-int --enable-mutable-globals --enable-multivalue \
                 --traps-never-happen --fast-math --closed-world --directize \
                 --inline-functions-with-loops --converge

.PHONY: all clean submodule docker build wasm dev install

all: wasm

# Compile .cpp -> .o (incremental)
$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(dir $@)
	emcc $(CXXFLAGS) $(VEROVIO_INCLUDES) -c $< -o $@

$(BUILD_DIR)/%.o: %.cc
	@mkdir -p $(dir $@)
	emcc $(CXXFLAGS) $(VEROVIO_INCLUDES) -c $< -o $@

$(BUILD_DIR)/src/verovio_data.o: src/verovio_data.S
	@mkdir -p $(dir $@)
	emcc $(CXXFLAGS) $(VEROVIO_INCLUDES) -c $< -o $@

# Link all objects into wasm, stub WASI imports, optimize
$(OUT): $(ALL_OBJ)
	emcc $(CXXFLAGS) $(LINK_FLAGS) $(VEROVIO_INCLUDES) -o $(OUT) $(ALL_OBJ)
	wasi-stub $(OUT) -o $(OUT) --stub-module env,wasi_snapshot_preview1 -r 0
	wasm-opt $(WASM_OPT_FLAGS) $(OUT) -o $(OUT).opt && mv $(OUT).opt $(OUT)

wasm: $(OUT)

# Fast dev build (no optimization)
dev: OPT = -O0
dev: wasm

submodule:
	@git submodule update --init --depth 1 $(VEROVIO_DIR)
	@cd $(VEROVIO_DIR) && git sparse-checkout init --cone && git sparse-checkout set src include libmei tools data
	@cd $(VEROVIO_DIR) && git apply ../scripts/verovio-typst.patch

docker:
	docker build -t $(DOCKER_IMAGE) .

build: submodule docker
	docker run --rm -v $(CURDIR):/src $(DOCKER_IMAGE) make -j$$(nproc) wasm

install: wasm
	mkdir -p ~/.local/share/typst/packages/local/verovio/0.1.0
	cp pkg/verovio.wasm pkg/verovio.typ pkg/typst.toml \
		~/.local/share/typst/packages/local/verovio/0.1.0/

clean:
	rm -rf $(OUT) $(OUT).opt $(BUILD_DIR)
