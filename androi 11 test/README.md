Android uses runtime "views" to manage storage access permissions.

Android 11 introduced new paths and we need to test those.

This directory contains a test config file for fbind and a standalone script to replicate what fbind does with that config.
Pick one.

The default prefix used by fbind and that script is /mnt/runtime/write.
It works on Android 6.0.1-10.

The standalone script should be placed in `/data/adb/service.d` with read and execute permissions.
For now, a reboot is required after changing the prefix value.
