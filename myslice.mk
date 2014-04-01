########## 
manifold-MODULES := manifold
manifold-SPEC := manifold.spec
ALL += manifold

myslice-MODULES := myslice
myslice-SPEC := myslice.spec
myslice-STOCK-DEVEL-RPMS := python-django
myslice-STOCK-DEVEL-DEBS := python-django python-django-south
myslice-LOCAL-DEVEL-RPMS := manifold
ALL += myslice

