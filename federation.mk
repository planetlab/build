########## 
#
# sfa - Slice Facility Architecture
#
sfa-MODULES := sfa
sfa-SPEC := sfa.spec
ALL += sfa

manifold-MODULES := manifold
manifold-SPEC := manifold.spec
ALL += manifold

myslice-MODULES := myslice
myslice-SPEC := myslice.spec
myslice-STOCK-DEVEL-RPMS := python-django
myslice-STOCK-DEVEL-DEBS := python-django python-django-south
# the -LOCAL-DEVEL-DEBS mechanism should work per se
# however manifold itself depends on sfa so it was starting to be a lot to swallow
# instead we have trimmed tweaked settings.py so it can be loaded in a build env.
#myslice-LOCAL-DEVEL-DEBS := manifold
ALL += myslice

