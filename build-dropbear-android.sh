#!/bin/bash

set -e

# Select the Android API Version to compile dropbear for, can either be 16 for Android 4.1 - 4.4, or 21 for Android 5.0+
ANDROID_API=21

# Specify the version of dropbear to build
DROPBEAR_VERSION=2018.76

# Specify binaries to build. Options: dropbear dropbearkey dropbearconvert scp dbclient
export PROGRAMS="dropbear dropbearkey dropbearconvert"

################################################################################

### Setup the NDK and Toolchain
if [ $ANDROID_API -eq 16 ]; then
	NDK_REVISION=r10e
elif [ $ANDROID_API -eq 21 ]; then
	NDK_REVISION=r19c
else
	echo "Invalid Android API"
	exit 1
fi

ANDROID_NDK=android-ndk-$NDK_REVISION
if [ ! -f $ANDROID_NDK.zip ]; then
	wget -O $ANDROID_NDK.zip https://dl.google.com/android/repository/$ANDROID_NDK-linux-x86_64.zip
fi

if [ ! -d $ANDROID_NDK ]; then
	unzip $ANDROID_NDK.zip
fi

if [ $ANDROID_API -eq 16 ]; then
	bash $ANDROID_NDK/build/tools/make-standalone-toolchain.sh --arch=arm --platform=android-16 --install-dir=toolchain > /dev/null 2>&1
	export TOOLCHAIN=$PWD/toolchain
else
	export TOOLCHAIN=$PWD/$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64
fi

################################################################################

### Setup dropbear
# Setup the environment
export TARGET=../target

# Download the latest version of dropbear SSH
DROPBEAR_NAME=dropbear-$DROPBEAR_VERSION
DROPBEAR_ARCHIVE=$DROPBEAR_NAME.tar.bz2 
if [ ! -f $DROPBEAR_ARCHIVE ]; then
	wget -O $DROPBEAR_ARCHIVE https://matt.ucc.asn.au/dropbear/releases/$DROPBEAR_ARCHIVE
fi

# Start each build with a fresh source copy
rm -rf $DROPBEAR_NAME
tar xjf $DROPBEAR_ARCHIVE

# Change to dropbear directory
cd $DROPBEAR_NAME

################################################################################

### Setup environment
HOST=arm-linux-androideabi
if [ $ANDROID_API -eq 16 ]; then
	COMPILER=${TOOLCHAIN}/bin/arm-linux-androideabi-gcc
else
	COMPILER=${TOOLCHAIN}/bin/armv7a-linux-androideabi21-clang
fi
STRIP=${TOOLCHAIN}/bin/arm-linux-androideabi-strip
SYSROOT=${TOOLCHAIN}/sysroot

export CC="$COMPILER --sysroot=$SYSROOT"
export CFLAGS="-g -O2 -pie -fPIE -D__ANDROID_API__=$ANDROID_API" # We only support PIE compilation, and thus Android 4.1+

unset GOOGLE_PLATFORM # Use the default platform target for pie binaries

### Start compiling -- configure without modifications first to generate files
echo "Generating required files..."

# Apply the new config.guess and config.sub now so they're not patched
cp ../config.guess ../config.sub .

./configure --host=$HOST --disable-utmp --disable-wtmp --disable-utmpx --disable-zlib --disable-syslog > /dev/null 2>&1

echo "Done generating files"
sleep 2
echo
echo

# Begin applying changes to make Android compatible
# Apply the compatibility patch
patch -p1 < ../android-compat.patch
patch -p1 < ../cli-auth.c.patch
patch -p1 < ../svr-auth.c.patch
patch -p1 < ../sshpty.c.patch
cd -

echo "Compiling for ARM"  

cd $DROPBEAR_NAME

./configure --host=$HOST --disable-utmp --disable-wtmp --disable-utmpx --disable-zlib --disable-syslog

make PROGRAMS="$PROGRAMS" -j $(nproc)
MAKE_SUCCESS=$?
if [ $MAKE_SUCCESS -eq 0 ]; then
	clear
	sleep 1
	# Create the output directory
	mkdir -p $TARGET/arm;
	for PROGRAM in $PROGRAMS; do

		if [ ! -f $PROGRAM ]; then
			echo "${PROGRAM} not found!"
		fi

		$STRIP "./${PROGRAM}"
	done

	cp $PROGRAMS $TARGET/arm
	echo "Compilation successful. Output files are located in: ${TARGET}/arm"
else
	echo "Compilation failed."
fi

