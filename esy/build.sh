#! /bin/bash

OS=$1
ESY_LIBJPEG_TURBO_PREFIX=$2

if [[ "$(python -V 2>&1)" =~ "Python 2" ]]
then
    PYTHON_BINARY="python"
elif [[ "$(python2 -V 2>&1)" =~ "Python 2" ]]
then
    PYTHON_BINARY="python2"
else
    echo "esy-skia requires Python 2 to be available either as python or as python2 to be built. Please install Python 2 and make it available in your PATH."
    exit -1
fi

$PYTHON_BINARY tools/git-sync-deps
ln -s third_party/externals/gyp tools/gyp
if [[ $OS == "windows" ]]
then
    WINDOWS_PYTHON_PATH="$(cygpath -w $(which $PYTHON_BINARY))"
    bin/gn gen $cur__target_dir/out/Shared --script-executable="$WINDOWS_PYTHON_PATH" --args='is_debug=false is_component_build=true' || exit -1
    ninja.exe -C $cur__target_dir/out/Shared
    mv $cur__target_dir/out/Shared/libskia.dll $cur__target_dir/out/Shared/skia.dll # TODO this might not be required once we merge upstream
    esy/gendef.exe - $cur__target_dir/out/Shared/skia.dll > $cur__target_dir/out/Shared/skia.def
    x86_64-W64-mingw32-dlltool.exe -D $cur__target_dir/out/Shared/skia.dll -d $cur__target_dir/out/Shared/skia.def -A -l $cur__target_dir/out/Shared/libskia.a
else
    bin/gn gen $cur__target_dir/out/Static --script-executable="$PYTHON_BINARY" "--args=cc=\"clang\" cxx=\"clang++\" skia_use_system_libjpeg_turbo=true is_debug=false extra_cflags=[\"-I${ESY_LIBJPEG_TURBO_PREFIX}/include\"] extra_ldflags=[\"-L${ESY_LIBJPEG_TURBO_PREFIX}/lib\", \"-ljpeg\" ]" || exit -1
    ninja.exe -C $cur__target_dir/out/Static
fi
