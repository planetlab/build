### # don't bother to upgrade
### linux-2.6-BRANCH		:= f12
### linux-2.6-GITPATH		:= git://git.onelab.eu/linux-2.6.git@linux-2.6.32-f12
### kernel-STOCK-DEVEL-RPMS		+= elfutils-libelf-devel 
### kernel-STOCK-DEVEL-RPMS		+= e2fsprogs 
### kernel-STOCK-DEVEL-RPMS		+= xmlto 
### kernel-STOCK-DEVEL-RPMS		+= asciidoc
#util-vserver-BRANCH		:= f12
#util-vserver-GITPATH		:= git://git.onelab.eu/util-vserver.git@f12-bbox-f14
util-vserver-GITPATH		:= git://git.onelab.eu/util-vserver.git@util-vserver-0.30.216-17
util-vserver-STOCK-DEVEL-RPMS		+= nss nss-devel
util-vserver-STOCK-DEVEL-RPMS		+= dietlibc
# but use latest stuff for f12 that has 3.2.28
yum-BRANCH			:= f12
yum-GITPATH			:= git://git.onelab.eu/yum.git@3.2.28-99-f1x
yum-STOCK-DEVEL-RPMS			+= gettext
yum-STOCK-DEVEL-RPMS			+= intltool
