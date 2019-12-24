FROM debian:latest

LABEL maintainer "eduard.v@bk.ru"

# Install the necessary packages
RUN apt-get -y -q update && apt-get -y -q install bind9 bind9utils isc-dhcp-server dnsutils wget unzip tftpd-hpa procps

ENV SYSLINUX_VERSION 6.03
ENV TEMP_SYSLINUX_PATH /tmp/syslinux-"$SYSLINUX_VERSION"
ENV DHCP_DEV ens18
WORKDIR /tmp
RUN \
  mkdir -p "$TEMP_SYSLINUX_PATH" \
  && wget -q https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-"$SYSLINUX_VERSION".tar.gz \
  && tar -xzf syslinux-"$SYSLINUX_VERSION".tar.gz \
  && mkdir -p /srv/tftp /srv/tftp/memtest /srv/tftp/clonezilla /srv/tftp/gparted \
  && chown tftp:tftp /srv/tftp \
  && cp "$TEMP_SYSLINUX_PATH"/bios/core/pxelinux.0 /srv/tftp/ \
  && cp "$TEMP_SYSLINUX_PATH"/bios/com32/libutil/libutil.c32 /srv/tftp/ \
  && cp "$TEMP_SYSLINUX_PATH"/bios/com32/elflink/ldlinux/ldlinux.c32 /srv/tftp/ \
  && cp "$TEMP_SYSLINUX_PATH"/bios/com32/menu/menu.c32 /srv/tftp/ \
  && rm -rf "$TEMP_SYSLINUX_PATH" \
  && rm /tmp/syslinux-"$SYSLINUX_VERSION".tar.gz

# your ip address
#ENV IP_ADDRESS 10.77.77.1

# Configure PXE and TFTP
COPY srv/tftp/ /srv/tftp/

# Configure DNS & DHCP
COPY etc/bind /etc/bind
COPY etc/dhcp /etc/dhcp
RUN chown -R bind:bind /etc/bind
RUN dnssec-keygen -a HMAC-MD5 -b 128 -r /dev/urandom -n USER DDNS_UPDATE \
  && echo "key DDNS_UPDATE {" > /etc/bind/ddns.key \
  && echo "  algorithm HMAC-MD5.SIG-ALG.REG.INT;" >> /etc/bind/ddns.key \
  && grep "Key:" 'Kddns_update.+157+'*.private | awk -F ' ' '{print "  secret \""$2"\";"}' >> /etc/bind/ddns.key \
  && echo "};" >> /etc/bind/ddns.key \
  && cp  /etc/bind/ddns.key /etc/dhcp/ddns.key \
  && > /var/lib/dhcp/dhcpd.leases \
  && echo "INTERFACESv4=\"$DHCP_DEV\"" > /etc/default/isc-dhcp-server
#  && cp 'Kddns_update.+157+'*.private /etc/bind/ddns.key \
#  && cp  'Kddns_update.+157+'*.private /etc/dhcp/ddns.key
COPY var/cache/bind /var/cache/bind

# Download and extract MemTest86+
ENV MEMTEST_VERSION 5.01
RUN wget -q http://www.memtest.org/download/"$MEMTEST_VERSION"/memtest86+-"$MEMTEST_VERSION".bin.gz \
  && gzip -d memtest86+-"$MEMTEST_VERSION".bin.gz \
  && mv memtest86+-$MEMTEST_VERSION.bin /srv/tftp/memtest/memtest86+

# Download and extract Clonezilla
ENV CLONEZILLA_VERSION 2.6.3-7
RUN wget -q https://netix.dl.sourceforge.net/project/clonezilla/clonezilla_live_stable/"$CLONEZILLA_VERSION"/clonezilla-live-"$CLONEZILLA_VERSION"-amd64.zip \
  && unzip -j -o clonezilla-live-"$CLONEZILLA_VERSION"-amd64.zip live/vmlinuz live/initrd.img live/filesystem.squashfs -d /srv/tftp/clonezilla

# Download and extract Gparted
ENV GPARTED_VERSION 1.0.0-5
RUN wget -q https://netix.dl.sourceforge.net/project/gparted/gparted-live-stable/"$GPARTED_VERSION"/gparted-live-"$GPARTED_VERSION"-amd64.zip \
  && unzip -j -o gparted-live-"$GPARTED_VERSION"-amd64.zip live/vmlinuz live/initrd.img live/filesystem.squashfs -d /srv/tftp/gparted

# Start dnsmasq. It picks up default configuration from /etc/dnsmasq.conf and
# /etc/default/dnsmasq plus any command line switch
EXPOSE 53/udp 53/tcp 67/udp 68/udp 10000/tcp
# ENTRYPOINT ["dnsmasq", "--no-daemon"]
# CMD ["--dhcp-range=192.168.4.100,192.168.4.200,255.255.254.0"]
#ENTRYPOINT [ "bind" ]
#ENTRYPOINT [ "/usr/sbin/named", "-4", "-c /etc/bind/named.conf" ]
#CMD [ "dhcpd" ]
#RUN dhcpd && bind
#CMD [ "tail", "-f", "/var/lib/dhcp/dhcpd.leases" ]
CMD /etc/init.d/tftpd-hpa start
