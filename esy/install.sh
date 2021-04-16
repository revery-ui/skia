#! /bin/bash

OS=$1

# Copy artifacts into output directories
mkdir -p $cur__install/include
cp -a $cur__root/include/. $cur__install/include/

mkdir -p $cur__install/include/svg/model
cp $cur__root/experimental/svg/model/*.h $cur__install/include/svg/model/

if [[ $OS == 'windows' ]]
then
    cp $cur__target_dir/out/Shared/libskia.a $cur__lib
    cp $cur__target_dir/out/Shared/skia.dll $cur__bin
else
    cp $cur__target_dir/out/Static/libskia.a $cur__lib
fi

# Create pkg-config file skia.pc
if [[ $OS == "darwin" ]]
then
    extraCFlags=""
    platformSpecificFlags="-framework CoreServices -framework CoreGraphics -framework CoreText -framework CoreFoundation"
elif [[ $OS == "windows" ]]
then
    extraCFlags="-std=c++1y"
    platformSpecificFlags="-luser32"
else
    # TODO find out what is needed here
    extraCFlags=""
    platformSpecificFlags=
fi

cat >$cur__lib/skia.pc << EOF
includedir=$cur__install/include

Name: skia
Description: 2D graphics library
Version: $cur__version
Cflags: -I$cur__install -I\${includedir}/android -I\${includedir}/atlastext -I\${includedir}/c -I\${includedir}/codec -I\${includedir}/config -I\${includedir}/core -I\${includedir}/docs -I\${includedir}/effects -I\${includedir}/encode -I\${includedir}/gpu -I\${includedir}/pathops -I\${includedir}/ports -I\${includedir}/private -I\${includedir}/svg -I\${includedir}/third_party -I\${includedir}/utils $extraCFlags
Libs: -L$cur__lib $platformSpecificFlags -lskia -lstdc++
EOF

if [[ $OS != "windows" ]]
then
    echo "Requires: libjpeg" >> $cur__lib/skia.pc
fi
