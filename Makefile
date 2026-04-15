VEROVIO_DIR = verovio
DOCKER_IMAGE = scoryst-builder
OUT = pkg/scoryst.wasm
BUILD_DIR = pkg/obj

# Optimization: override with `make OPT=-O0` for fast dev builds
OPT = -Os

CXXFLAGS = $(OPT) -DNDEBUG -std=c++20 -DPUGIXML_NO_EXCEPTIONS \
           -DNO_PAE_SUPPORT -DNO_RUNTIME

# All source files
PLUGIN_SRC = src/scoryst_plugin.cpp
INIT_SRC = src/scoryst_init.cpp
# Exclude unused source files: editor toolkits, CMME parser, feature extractor
VEROVIO_EXCLUDE = editortoolkit.cpp editortoolkit_cmn.cpp editortoolkit_neume.cpp \
                  editfunctor.cpp featureextractor.cpp
VEROVIO_SRC = $(filter-out $(addprefix $(VEROVIO_DIR)/src/,$(VEROVIO_EXCLUDE)), \
                $(wildcard $(VEROVIO_DIR)/src/*.cpp)) \
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
          $(BUILD_DIR)/src/font_data.o

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
             -s INITIAL_MEMORY=536870912 \
             -s ALLOW_MEMORY_GROWTH=1 \
             -s STACK_SIZE=134217728 \
             -s ERROR_ON_UNDEFINED_SYMBOLS=0 \
             -s EXPORTED_FUNCTIONS='["_render","_render_page","_page_count","_malloc","_free"]' \
             -s FILESYSTEM=0 \
             -s DISABLE_EXCEPTION_CATCHING=1 \
             -s ASSERTIONS=0

WASM_OPT_FLAGS = -O3 --enable-simd --enable-bulk-memory --enable-sign-ext \
                 --enable-nontrapping-float-to-int --enable-mutable-globals --enable-multivalue \
                 --traps-never-happen --fast-math --closed-world --directize \
                 --inline-functions-with-loops --converge

# Version is the single source of truth in pkg/typst.toml; derive it here
# so install and bump stay consistent.
VERSION := $(shell sed -n 's/^version = "\(.*\)"/\1/p' pkg/typst.toml)

.PHONY: all clean submodule docker build wasm dev install bump

all: wasm

# Compile .cpp -> .o (incremental)
$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(dir $@)
	emcc $(CXXFLAGS) $(VEROVIO_INCLUDES) -c $< -o $@

$(BUILD_DIR)/%.o: %.cc
	@mkdir -p $(dir $@)
	emcc $(CXXFLAGS) $(VEROVIO_INCLUDES) -c $< -o $@

$(BUILD_DIR)/src/font_data.o: src/font_data.S src/fonts
	@mkdir -p $(dir $@)
	emcc $(CXXFLAGS) $(VEROVIO_INCLUDES) -c $< -o $@

# Link and stub WASI imports
$(OUT): $(ALL_OBJ)
	emcc $(CXXFLAGS) $(LINK_FLAGS) $(VEROVIO_INCLUDES) -o $(OUT) $(ALL_OBJ)
	wasi-stub $(OUT) -o $(OUT) --stub-module env,wasi_snapshot_preview1 -r 0

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
	mkdir -p ~/.local/share/typst/packages/local/scoryst/$(VERSION)
	cp pkg/scoryst.wasm pkg/scoryst.typ pkg/typst.toml \
		~/.local/share/typst/packages/local/scoryst/$(VERSION)/

# Bump the version everywhere (pkg/typst.toml, README.md). Usage: make bump V=0.1.2
bump:
	@[ -n "$(V)" ] || (echo "usage: make bump V=X.Y.Z"; exit 1)
	@OLD=$$(sed -n 's/^version = "\(.*\)"/\1/p' pkg/typst.toml); \
	  sed -i "s/^version = \"$$OLD\"/version = \"$(V)\"/" pkg/typst.toml; \
	  sed -i "s|scoryst:$$OLD|scoryst:$(V)|g" README.md; \
	  echo "bumped $$OLD -> $(V) in pkg/typst.toml and README.md"

clean:
	rm -rf $(OUT) $(OUT).opt $(BUILD_DIR)
