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

if [[ $OS == "windows" ]]
then
    # If we are told to build from scratch, do so.
    if [[ -n "$ESY_SKIA_SCRATCH" ]]
    then
        $PYTHON_BINARY tools/git-sync-deps
        ln -s third_party/externals/gyp tools/gyp
        WINDOWS_PYTHON_PATH="$(cygpath -w $(which $PYTHON_BINARY))"
        bin/gn gen $cur__target_dir/out/Shared --script-executable="$WINDOWS_PYTHON_PATH" --args='is_debug=false is_component_build=true esy_skia_enable_svg=true' || exit -1
        ninja.exe -C $cur__target_dir/out/Shared
        mv $cur__target_dir/out/Shared/libskia.dll $cur__target_dir/out/Shared/skia.dll
    else
        mkdir -p $cur__target_dir/out/Shared/ 
        cp prebuilt/windows/skia.dll $cur__target_dir/out/Shared/skia.dll
    fi
    esy/gendef.exe - $cur__target_dir/out/Shared/skia.dll > $cur__target_dir/out/Shared/skia.def
    x86_64-W64-mingw32-dlltool.exe -D $cur__target_dir/out/Shared/skia.dll -d $cur__target_dir/out/Shared/skia.def -A -l $cur__target_dir/out/Shared/libskia.a
else
    $PYTHON_BINARY tools/git-sync-deps
    ln -s third_party/externals/gyp tools/gyp

    CC=clang
    CXX=clang++
    if ! [ -x "$(command -v clang++)" ]; then
        echo "Manually activating llvm toolset 7.0..."
        source /opt/rh/llvm-toolset-7.0/enable
        CC="clang --gcc-toolchain=/usr/lib/gcc/x86_64-redhat-linux/4.8.5 -stdlib=libstdc++"
        CXX="clang++ --gcc-toolchain=/usr/lib/gcc/x86_64-redhat-linux/4.8.5 -I/usr/include/c++/4.8.5 -I/usr/include/c++/4.8.5/x86_64-redhat-linux -std=c++11 -stdlib=libstdc++"
        echo "-- clang version:"
        $CC -v
        echo "-- clang++ version:"
	$CXX -v
    else
        echo "llvm toolset-7.0 does not need to be manually activated"
    fi

    current_arch=$(arch)

    if [[ $OS == "darwin" ]]
    then
        bin/gn gen $cur__target_dir/out/Static --script-executable="$PYTHON_BINARY" "--args=cc=\"$CC\" cxx=\"$CXX\" target_cpu=\"$current_arch\" skia_use_system_libjpeg_turbo=true esy_skia_enable_svg=true is_debug=false extra_cflags=[\"-I${ESY_LIBJPEG_TURBO_PREFIX}/include\"] extra_ldflags=[\"-L${ESY_LIBJPEG_TURBO_PREFIX}/lib\", \"-ljpeg\" ]" || exit -1
    else
        bin/gn gen $cur__target_dir/out/Static --script-executable="$PYTHON_BINARY" "--args=cc=\"$CC\" cxx=\"$CXX\" skia_use_system_libjpeg_turbo=true esy_skia_enable_svg=true is_debug=false extra_cflags=[\"-I${ESY_LIBJPEG_TURBO_PREFIX}/include\"] extra_ldflags=[\"-L${ESY_LIBJPEG_TURBO_PREFIX}/lib\", \"-ljpeg\" ]" || exit -1
    fi
    ninja.exe -C $cur__target_dir/out/Static || exit -1
fi
