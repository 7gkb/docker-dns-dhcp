$ORIGIN .
$TTL 3600	; 1 hour
sec.7gkb.ru		IN SOA	srv-dns-dhcp-05.sec.7gkb.ru. root.sec.7gkb.ru. (
				2007011001 ; serial
				3600       ; refresh (1 hour)
				600        ; retry (10 minutes)
				86400      ; expire (1 day)
				600        ; minimum (10 minutes)
				)
			NS	srv-dns-dhcp-05.sec.7gkb.ru.
			MX	10 srv-dns-dhcp-03.sec.7gkb.ru.
$ORIGIN sec.7gkb.ru.
mail			CNAME	srv-dns-dhcp-03
$TTL 3600	; 1 hour
pop			CNAME	srv-dns-dhcp-03
router			A	192.168.108.254
srv-dns-dhcp-03		A	192.168.108.250
srv-dns-dhcp-05		A	192.168.5.250
srv05			CNAME	srv-dns-dhcp-05
srv03			CNAME	srv-dns-dhcp-03
www			CNAME	srv-dns-dhcp-03
