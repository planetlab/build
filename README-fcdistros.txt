# we're facing an issue for building on f17 an onwards
# see
# https://fedoraproject.org/wiki/Upgrading_Fedora_using_yum#Fedora_16_-.3E_Fedora_17
# 
# in a nutshell, building a f17 image from an earlier version is challenging
# 
# ========== update january 2013
# we have a first build box that can build for f18
# this still needs to be properly documented and packaged though
# see https://svn.planet-lab.org/wiki/VserverFedora14
#
# #################### debians and ubuntus
#
# the build utilities can now produce a build VM for the most recent
# debians (squeeze, wheezy, jessie) and ubuntus ( oreinic, precise, quantal,
# raring, saucy, trusty )
# 
# of course we're nowhere close to supporting the whole PLC on these
# systems, as packaging for debian requires manual tweaks in every
# single module
# 
# However the SFA module at least is rebuilt on these platforms on a
# regular basis, at least for each tag
# 
# ####################
