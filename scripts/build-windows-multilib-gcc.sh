#!/usr/bin/env bash
set -euo pipefail

src_dir="${1:?x265 source directory is required}"
out_dir="${2:?output directory is required}"
cd "$src_dir"
export PATH="/mingw64/bin:/usr/bin:$PATH"

# MinGW windres cannot parse the upstream Visual Studio resource template.
printf '%s\n' '1 VERSIONINFO BEGIN END' > source/x265.rc.in

common=(-G Ninja -DENABLE_ASSEMBLY=ON
  -DCMAKE_CXX_FLAGS="-static-libstdc++ -static-libgcc"
  -DCMAKE_EXE_LINKER_FLAGS="-static -static-libgcc -static-libstdc++ -Wl,-Bstatic -lwinpthread"
  '-DCMAKE_CXX_STANDARD_LIBRARIES=-Wl,-Bstatic -lstdc++ -lwinpthread -Wl,-Bdynamic')
mkdir -p "$out_dir"/{12bit,10bit,8bit}

cmake -S source -B "$out_dir/12bit" "${common[@]}" -DHIGH_BIT_DEPTH=ON -DMAIN12=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF
cmake --build "$out_dir/12bit" --parallel
cp "$out_dir/12bit/libx265.a" "$out_dir/8bit/libx265_main12.a"

cmake -S source -B "$out_dir/10bit" "${common[@]}" -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF -DENABLE_SHARED=OFF -DENABLE_CLI=OFF
cmake --build "$out_dir/10bit" --parallel
cp "$out_dir/10bit/libx265.a" "$out_dir/8bit/libx265_main10.a"

cmake -S source -B "$out_dir/8bit" "${common[@]}" -DLINKED_10BIT=ON -DLINKED_12BIT=ON -DEXTRA_LIB="x265_main10.a;x265_main12.a" -DEXTRA_LINK_FLAGS=-L. -DENABLE_SHARED=OFF -DENABLE_CLI=ON
cmake --build "$out_dir/8bit" --parallel
exe="$out_dir/8bit/x265.exe"
"$exe" --version
runtime_deps="$(objdump -p "$exe" | sed -n 's/.*DLL Name: \(libstdc++[^ ]*\|libgcc[^ ]*\|libwinpthread[^ ]*\).*/\1/p')"
if [[ -n "$runtime_deps" ]]; then
  echo "Unexpected MinGW runtime dependencies:"; echo "$runtime_deps"; exit 1
fi

package_dir="$out_dir/package"
mkdir -p "$package_dir"
cp "$exe" "$package_dir/x265.exe"
zip_name="x265-windows-x86_64-gcc-multilib.zip"
rm -f "$src_dir/$zip_name"
(
  cd "$package_dir"
  zip -q "$src_dir/$zip_name" x265.exe
)
echo "PACKAGE=$src_dir/$zip_name"
