# we're facing an issue for building on f17 an onwards
# see
# https://fedoraproject.org/wiki/Upgrading_Fedora_using_yum#Fedora_16_-.3E_Fedora_17
# 
# in a nutshell, building a f17 image from an earlier version is challenging
# this means on the long run we're going to have to have build boxes run f17 or higher
# 
# several options could be considered
# (*) tweak the build to use lxc-based host instead of vs; 
#     this also requires better user tools for lxc than the stock lxctools
#     that we've been using so far for vtest-init-lxc.sh
# (*) assemble a f17-vs build box (not preferred at all)
# 
