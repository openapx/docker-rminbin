#! /bin/bash

# -- set up working directories
mkdir -p /sources/R /builds /logs/R/rminbin/builds

# -- R source repository
REPO=https://cran.r-project.org/src/base/R-4


# -- identify R verison to build
echo "-- identify R version"

XSOURCE=$( wget -q -O - ${REPO}/ | \
           grep -io '<a href=['"'"'"][^"'"'"']*['"'"'"]' | \
           sed -e 's/^<a href=["'"'"']//i' -e 's/["'"'"']$//i' | \
           grep "^R-.*.tar.gz$" | \
           sort -r | \
           head -n1 )

BUILD_VER=$(echo ${XSOURCE} | sed -n 's/^R-\(.*\).tar.gz$/\1/p')

echo "   R version ${BUILD_VER}"



# -- download 

URL=${REPO}/${XSOURCE}
echo "-- downloading ${URL}"
wget --no-check-certificate --quiet --directory-prefix=/sources/R ${URL}

_MD5=($(md5sum /sources/R/${XSOURCE}))
_SHA256=($(sha256sum /sources/R/${XSOURCE}))

echo "   ${XSOURCE} (MD5 ${_MD5} / SHA-256 ${_SHA256})"

unset _MD5
unset _SHA256



# -- build R version

echo "-- build R version ${BUILD_VER}"


# - set up build area
echo "   set up build scaffolding"
mkdir -p /builds/R-${BUILD_VER} /builds/sources

# -- unpack tar
echo "   unpack sources"

cd /builds/sources
tar -xf /sources/R/${XSOURCE}

find /builds/sources/R-${BUILD_VER}/ -type f -exec md5sum {} + > /logs/R/rminbin/builds/R-${BUILD_VER}-sources.md5
gzip -9 /logs/R/rminbin/builds/R-${BUILD_VER}-sources.md5

find /builds/sources/R-${BUILD_VER}/ -type f -exec sha256sum {} + > /logs/R/rminbin/builds/R-${BUILD_VER}-sources.sha256
gzip -9 /logs/R/rminbin/builds/R-${BUILD_VER}-sources.sha256


# -- configure
echo "   configure"

cd /builds/R-${BUILD_VER}

../sources/R-${BUILD_VER}/configure --prefix=/opt/R/${BUILD_VER} \
                                    --enable-R-shlib \
                                    --with-blas \
                                    --with-lapack \
                                    --with-recommended-packages=no > /logs/R/rminbin/builds/R-${BUILD_VER}-config.log 2>&1

gzip -9 /logs/R/rminbin/builds/R-${BUILD_VER}-config.log


# -- build 
echo "   build"

make > /logs/R/rminbin/builds/R-${BUILD_VER}-make.log 2>&1
gzip -9 /logs/R/rminbin/builds/R-${BUILD_VER}-make.log


# -- check build
echo "   check build"

make check-all > /logs/R/rminbin/builds/R-${BUILD_VER}-check.log 2>&1
gzip -9 /logs/R/rminbin/builds/R-${BUILD_VER}-check.log


# -- install build 

echo "-- installing R version ${BUILD_VER}"

make install > /logs/R/rminbin/builds/R-${BUILD_VER}-install.log 2>&1
gzip -9 /logs/R/rminbin/builds/R-${BUILD_VER}-install.log


find /opt/R/${BUILD_VER} -type f -exec md5sum {} + > /logs/R/rminbin/builds/R-${BUILD_VER}-install.md5
gzip -9 /logs/R/rminbin/builds/R-${BUILD_VER}-install.md5

find /opt/R/${BUILD_VER} -type f -exec sha256sum {} + > /logs/R/rminbin/builds/R-${BUILD_VER}-install.sha256
gzip -9 /logs/R/rminbin/builds/R-${BUILD_VER}-install.sha256


# -- initiate site library
echo "-- initiate site library"
mkdir -p /opt/R/${BUILD_VER}/lib/R/site-library


# -- secure the install location
echo "-- secure install"
find /opt/R/${BUILD_VER} -type f -exec chmod u+r-wx,g+r-wx,o+r-wx {} \;
find /opt/R/${BUILD_VER} -type d -exec chmod u+rx-w,g+rx-w,o+rx-w {} \;

# -- open up site-library for writing
echo "-- write enable site library"
chmod u+rwx,g+rwx,o+rx-w /opt/R/${BUILD_VER}/lib/R/site-library

# -- make R executable again 
echo "-- enable R executables"
find /opt/R/${BUILD_VER}/lib/R/bin -type f -exec chmod u+rx-w,g+rx-w,o+rx-w {} \;
chmod u+rx-w,g+rx-w,o+rx-w /opt/R/${BUILD_VER}/bin/*


# -- add symbolic links
echo "-- add symbolic links from /usr/bin"

ln -s /opt/R/${BUILD_VER}/bin/R /usr/bin/R
ln -s /opt/R/${BUILD_VER}/bin/Rscript /usr/bin/Rscript


# -- clean up after build
echo "-- clean up"
rm -Rf /sources /builds

