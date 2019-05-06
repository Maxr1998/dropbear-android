Android Dropbear
=========

A patch set and script to download and cross-compile Dropbear SSH server for use on Android with password authentication.
As the 64-bit binaries don't seem to work reliably, this project is configured to compile 32-biti ARM binaries
using the Android NDK toolchain.

Generated binares will all be PIE (position indepedent executable) binaries as it is required since Android 5 (Lollipop).

If you want to build dropbear for Android 4.1 - 4.4, set the `ANDROID_API` variable at the top to 16.

Building Dropbear for Android
----

The process consists of just four parts:  
1) (Optionally) specify the `ANDROID_API` value as described above, which defaults to 21  
2) (Optionally) specify the version of Dropbear you'd like to download and crosscompile. Open build-android-dropbear.sh and change the value of `DROPBEAR_VERSION` at the top, which defaults to `2018.76`  
3) (Optionally) specify the binaries you want to build with the `PROGRAMS` variable, by default, the server, dropbearkey and dropbearconvert binary will be built  
4) Run the build script:
```
./build-dropbear-android.sh
```

It will then download the appropriate NDK, Dropbear sources, and compile the binaries.
Generated binaries will be outputted to `{dropbear-android repo directory}/target/arm`


Customizations
----

Much of the project is pre-configured with sane defaults, but if you'd like to customize the behavior of Dropbear for Android, here are a few tips.
1) To change/configure most options, look in and modify the following files as appropriate:  
	a) default_options.h  
	b) sysoptions.h  
	c) config.h  

For instance, to change the port Dropbear runs on or to change the default location in which Dropbear tries to generate keys, edit `default_options.h` and modify the respective values.  
  
Basic usage
----
Dropbear for Android adds a few special flags to Dropbear:  
- A: signifies Android mode and allows for password authentication in the absence of the `crypt()` lib
- G: allows us to specify the GID dropbear should run as  
- U: allows us to specify the UID dropbear should run as  
- N: specify the login username for the session  
- T: specify the authentication key for the session  

A typical usecase would be:  
```
./dropbear -d /path/to/dropbear_dss_host_key -r /path/to/dropbear_rsa_hostkey -p 10022 -P /path/to/dropbear.pid -R -A -N user -C password -U u0_aXX -G u0_aXX
```

The above command will run the Dropbear server with password authentication enabled for the user 'user' with password 'password' and will attempt to run as u0_aXX and in that group. More information can be found by issuing:  
  
```
./dropbear --help
````

Credits
----
Big thanks to mkj who has been maintaining Dropbear:  
https://github.com/mkj/dropbear  

Thanks to NHellfire who's work made the process of getting 2018.76 up and running much easier:  
https://github.com/NHellFire/dropbear-android  

Thanks to jmfoy for the `config.sub` and `config.guess` files:  
https://github.com/jfmoy/android-dropbear

Another thank you to the various other repositories out there whose various approches helped lead to this completed project.
