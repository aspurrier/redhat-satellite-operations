# redhat-satellite-operations
Scripts to automate common Satellite tasks.

# Files

## export_satellite_build_and_maintenance_content.sh

Export the content need to build a disconnected satellite.


## repos_enable_and_sync.sh

Sync Red Hat Repositories and set the download policy to "immediate".
Immediately after building Satellite and whenever additional repositories need
to be enabled + synchronised, run this script.
It can be safely run repeatedly.
The script does not remove any repositories.


## setup.rc

Sourced by the shell scripts.
Configuration variables used by the various scripts.
Create a new (release) branch for each environment / satellite build to manage
multiple versions of this configuration file.

