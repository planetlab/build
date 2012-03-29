We've tried to isolate the distro-dependent configurations from the code

Most of the .pgks files are optional to define a new distro:
missing files are searched in the planetlab distro

========== build environment
./build/<pldistro>.mk
	that defines the contents of the build -- see Makefile
./build/<pldistro>-tags.mk
	that defines the svn locations of the various modules
./build/<pldistro>-install.mk
	optional make file to define the install target

========== kernel config
./Linux-2.6/configs/kernel-2.6.<n>-<arch>-<pldistro>.config
	(subject to change location in the future)

========== various system images
./build/config.<pldistro>/devel.pkgs
	set of packages required for building
./build/config.<pldistro>/bootcd.pkgs
	contents of the bootcd image
./build/config.<pldistro>/nodeimage.pkgs
	the standard contents of the node software
        this results in a tarball (tar.bz2) 
	also used to generate yumgroups.xml on the plc side
./build/config.<pldistro>/nodeimage-*.pkgs
	each of these files results in an extension tarball
./build/config.<pldistro>/sliceimage.pkgs
	the contents of the standard vserver reference image
./build/config.<pldistro>/sliceimage-*.pkgs
	all *.pkgs files here - produce additional vserver images
./build/config.<pldistro>/vtest.pkgs
	used to create test vservers for myplc-native
./build/config.<pldistro>/yumexclude.pkgs
	describe the set of node packages that are produced by the myplc build
	and thus should be excluded from the stock fedora repos

=== extensions
as of this writing extensions are managed as follows:
- at node installation, the tarball produced from nodeimage.pkgs is
downloaded and untared to produce the node root filesystem
- then we attempt to install an extension corresponding to each of the
extensions that the node has in its 'extensions' tag
- the first method is to try and download a tarball named after the
extension. such tarballs are produced by the build from a .pkgs file,
see above
- if that fails, then the extension install is attempted through a
 yum groupinstall extension<nodegroup>

