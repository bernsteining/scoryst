#!/bin/bash
# Iteratively find the minimal set of .o files needed to link.
# Uses wasm-nm to find which .o defines each missing symbol.
cd /home/lisbeth/documents/prog/perso/typst/verovio

FLAGS="-O3 -DNDEBUG -std=c++20"
INCLUDES="-Isrc -Iverovio/include -Iverovio/include/vrv -Iverovio/include/hum -Iverovio/include/json -Iverovio/include/midi -Iverovio/include/pugi -Iverovio/include/zip -Iverovio/include/crc -Iverovio/include/tuning-library -Iverovio/libmei/dist -Iverovio/libmei/addons -Iverovio/tools"
LINK="--no-entry -s WASM=1 -s INITIAL_MEMORY=268435456 -s ALLOW_MEMORY_GROWTH=1 -s STACK_SIZE=134217728 -s ERROR_ON_UNDEFINED_SYMBOLS=1 -s EXPORTED_FUNCTIONS=[_render,_render_page,_page_count,_malloc,_free]"

OBJS="pkg/obj/src/verovio_plugin.o pkg/obj/src/verovio_init.o pkg/obj/src/verovio_data.o"
ALL_O=($(find pkg/obj/verovio -name '*.o' | sort))

# Build a symbol -> file index using wasm-nm (or llvm-nm)
NM="llvm-nm-18"
if ! command -v $NM &>/dev/null; then NM="llvm-nm"; fi
if ! command -v $NM &>/dev/null; then NM="wasm-nm"; fi
if ! command -v $NM &>/dev/null; then
    # Fall back to nm from emsdk
    NM=$(find $EMSDK -name "llvm-nm" 2>/dev/null | head -1)
fi

echo "Using nm: $NM"
echo "Building symbol index..."

declare -A SYM_INDEX
for o in "${ALL_O[@]}"; do
    # Get defined (non-undefined) symbols
    DEFS=$($NM --defined-only "$o" 2>/dev/null | awk '{print $NF}')
    for d in $DEFS; do
        SYM_INDEX["$d"]="$o"
    done
done
echo "Index built: ${#SYM_INDEX[@]} symbols from ${#ALL_O[@]} files"

for i in $(seq 1 300); do
    ERRORS=$(emcc $FLAGS $LINK $INCLUDES -o /tmp/test.wasm $OBJS 2>&1)

    if [ $? -eq 0 ]; then
        N=$(echo $OBJS | wc -w)
        echo "=== SUCCESS with $N object files after $i iterations ==="
        echo "$OBJS" | tr ' ' '\n' | grep verovio | sed 's|pkg/obj/verovio/||' | sort
        exit 0
    fi

    # Get mangled undefined symbols from linker output
    # wasm-ld shows demangled names, but we need mangled. Let's extract from .o files instead.
    # Actually, let's get the undefined symbol names from linker errors and search the index.
    UNDEF_DEMANGLED=$(echo "$ERRORS" | grep "undefined symbol:" | sed 's/.*undefined symbol: //' | sort -u)

    if [ -z "$UNDEF_DEMANGLED" ]; then
        echo "NON-SYMBOL ERROR at iteration $i:"
        echo "$ERRORS" | grep "error:" | head -5
        exit 1
    fi

    # For each .o that reports undefined symbols, find what it needs
    NEED_FILES=$(echo "$ERRORS" | grep "undefined symbol:" | sed 's/: undefined symbol:.*//' | sed 's/.*error: //' | sort -u)

    ADDED_THIS=""
    for need_o in $NEED_FILES; do
        # Get mangled undefined symbols from this .o
        MANGLED_UNDEF=$($NM --undefined-only "$need_o" 2>/dev/null | awk '{print $NF}')
        for msym in $MANGLED_UNDEF; do
            PROVIDER="${SYM_INDEX[$msym]}"
            if [ -n "$PROVIDER" ] && ! echo "$OBJS $ADDED_THIS" | grep -q "$PROVIDER"; then
                ADDED_THIS="$ADDED_THIS $PROVIDER"
            fi
        done
    done

    if [ -z "$ADDED_THIS" ]; then
        echo "STUCK at iteration $i. Unresolved (demangled):"
        echo "$UNDEF_DEMANGLED" | head -15
        echo "Current files: $(echo $OBJS | wc -w)"
        exit 1
    fi

    # Deduplicate
    ADDED_THIS=$(echo "$ADDED_THIS" | tr ' ' '\n' | sort -u | tr '\n' ' ')

    for o in $ADDED_THIS; do
        echo "[$i] + $(echo $o | sed 's|pkg/obj/verovio/||')"
    done
    OBJS="$OBJS $ADDED_THIS"
done
