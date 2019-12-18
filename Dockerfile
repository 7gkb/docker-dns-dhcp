FROM debian:latest

LABEL maintainer "eduard.v@bk.ru"

# Install the necessary packages
RUN apt-get -y -q update && apt-get -y -q install bind9 bind9utils isc-dhcp-server dnsutils wget unzip

ENV SYSLINUX_VERSION 6.03
ENV TEMP_SYSLINUX_PATH /tmp/syslinux-"$SYSLINUX_VERSION"
WORKDIR /tmp
RUN \
  mkdir -p "$TEMP_SYSLINUX_PATH" \
  && wget -q https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-"$SYSLINUX_VERSION".tar.gz \
  && tar -xzf syslinux-"$SYSLINUX_VERSION".tar.gz \
  && mkdir -p /var/lib/tftpboot /var/lib/tftpboot/memtest /var/lib/tftpboot/clonezilla \
  && cp "$TEMP_SYSLINUX_PATH"/bios/core/pxelinux.0 /var/lib/tftpboot/ \
  && cp "$TEMP_SYSLINUX_PATH"/bios/com32/libutil/libutil.c32 /var/lib/tftpboot/ \
  && cp "$TEMP_SYSLINUX_PATH"/bios/com32/elflink/ldlinux/ldlinux.c32 /var/lib/tftpboot/ \
  && cp "$TEMP_SYSLINUX_PATH"/bios/com32/menu/menu.c32 /var/lib/tftpboot/ \
  && rm -rf "$TEMP_SYSLINUX_PATH" \
  && rm /tmp/syslinux-"$SYSLINUX_VERSION".tar.gz

# your ip address
#ENV IP_ADDRESS 10.77.77.1

# Configure PXE and TFTP
COPY srv/tftp/ /srv/tftp/

# Configure DNS & DHCP
COPY etc/ /etc
RUN chown -R bind:bind /etc/bind
RUN dnssec-keygen -a HMAC-MD5 -b 128 -r /dev/urandom -n USER DDNS_UPDATE \
  && cp 'Kddns_update.+157+'*.private /etc/bind/ddns.key \
  && cp  'Kddns_update.+157+'*.private /etc/dhcp/ddns.key


# Download and extract MemTest86+
ENV MEMTEST_VERSION 5.01
RUN wget -q http://www.memtest.org/download/"$MEMTEST_VERSION"/memtest86+-"$MEMTEST_VERSION".bin.gz \
  && gzip -d memtest86+-"$MEMTEST_VERSION".bin.gz \
#  && mkdir -p /var/lib/tftpboot/memtest \
  && mv memtest86+-$MEMTEST_VERSION.bin /var/lib/tftpboot/memtest/memtest86+

# Download and extract Clonezilla
ENV CLONEZILLA_VERSION 2.6.3-7
RUN wget -q https://netix.dl.sourceforge.net/project/clonezilla/clonezilla_live_stable/"$CLONEZILLA_VERSION"/clonezilla-live-"$CLONEZILLA_VERSION"-amd64.zip \
  && unzip -j clonezilla-live-"$CLONEZILLA_VERSION"-amd64.zip live/vmlinuz live/initrd.img live/filesystem.squashfs -d /var/lib/tftpboot/clonezilla
#  && mkdir -p /var/lib/tftpboot/clonezilla \
#  && mv

# Start dnsmasq. It picks up default configuration from /etc/dnsmasq.conf and
# /etc/default/dnsmasq plus any command line switch
EXPOSE 53/udp 53/tcp 67/udp 68/udp 10000/tcp
# ENTRYPOINT ["dnsmasq", "--no-daemon"]
# CMD ["--dhcp-range=192.168.4.100,192.168.4.200,255.255.254.0"]
