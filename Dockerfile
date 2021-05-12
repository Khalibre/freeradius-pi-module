ARG from=ubuntu:20.04
FROM ${from} as build

ARG DEBIAN_FRONTEND=noninteractive

#
#  Install build tools
#
RUN apt-get update; apt-get upgrade; \
  apt-get install -y devscripts equivs git quilt gcc

#
#  Create build directory
#
RUN mkdir -p /usr/local/src/repositories

WORKDIR /usr/local/src/repositories

#
#  Shallow clone the FreeRADIUS source
#
ARG source=https://github.com/FreeRADIUS/freeradius-server.git
ARG release=v3.0.x

RUN git clone --depth 1 --single-branch --branch ${release} ${source}
WORKDIR freeradius-server

#
#  Install build dependencies
#
RUN git checkout ${release}; \
  if [ -e ./debian/control.in ]; then \
  debian/rules debian/control; \
  fi; \
  echo 'y' | mk-build-deps -irt'apt-get -yV' debian/control

#
#  Build the server
#
RUN make -j2 deb

#
#  Clean environment and run the server
#
FROM ${from}
COPY --from=build /usr/local/src/repositories/*.deb /tmp/

RUN apt-get update; \
  apt-get -qq install tree rsync libconfig-inifiles-perl libdata-dump-perl libtry-tiny-perl libjson-perl liblwp-protocol-https-perl

RUN mkdir -p /usr/share/privacyidea/freeradius; \
  mkdir -p /data

RUN apt-get update \
  && apt-get install -y /tmp/*.deb \
  && apt-get clean \
  && rm -r /var/lib/apt/lists/* /tmp/*.deb \
  && ln -s /etc/freeradius /etc/raddb

#
# Add PI modules
#
ADD https://raw.githubusercontent.com/privacyidea/FreeRADIUS/v3.4/privacyidea_radius.pm /usr/share/privacyidea/freeradius
RUN chmod 644 /usr/share/privacyidea/freeradius/privacyidea_radius.pm; \
  rm -rf /etc/raddb/sites-enabled/default
  # ADD configs/raddb/mods-available/perl /etc/raddb/mods-available/perl
# RUN ln -s /etc/raddb/mods-available/perl /etc/raddb/mods-enabled/perl

COPY configs/raddb/ /etc/freeradius/
COPY configs/prestart.sh /
COPY configs/docker-entrypoint.sh /

EXPOSE 1812/udp 1813/udp
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["freeradius"]
