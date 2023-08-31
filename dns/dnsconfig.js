var REG_NONE = NewRegistrar("none");
var DNS_INWX = NewDnsProvider("inwx");
var DNS_HE = NewDnsProvider("he");
var DNS_HETZNER = NewDnsProvider("hetzner");


hosts = require("../modules/hosts/hosts.json");
function HOST(record_name, hostname) {
  var hostname = hostname || record_name;
  var recs = [];
  ipv4 = hosts[hostname]["ipv4Addresses"] || [];
  ipv6 = hosts[hostname]["ipv6Addresses"] || [];
  for (var a in ipv4) { recs.push(A(record_name, ipv4[a])); }
  for (var a in ipv6) { recs.push(AAAA(record_name, ipv6[a])); }
  if (recs.length > 0) { recs.push(ACME(record_name, hostname)); }
  return recs;
}

function ACME(record_name, target) {
  record_name = "_acme-challenge" + (record_name == "@" ? "" : "." + record_name);
  target = target[target.length-1] == "." ? target : target + ".he.0jb.de.";
  return [ CNAME(record_name, "_acme-challenge."+target) ];
}

function CNAME_ACME(record_name, target) {
  target_cname = target[target.length-1] == "." ? target : target + ".0jb.de.";
  return [
    CNAME(record_name, target_cname),
    ACME(record_name, target)
  ];
}

function INWX_PARKING(record_name) {
  return A(record_name, "185.181.104.242")
}


DEFAULTS(
  NAMESERVER_TTL("1d"),
  DefaultTTL("1h"),
  []
)


D("he.0jb.de", REG_NONE, DnsProvider("he"),
  NAMESERVER_TTL("2d"),
  IGNORE("_acme-challenge.*", "TXT"),
  []
)

D("0jb.de", REG_NONE, DnsProvider("inwx"),
  NS("he", "ns1.he.net."),
  NS("he", "ns2.he.net."),
  NS("he", "ns3.he.net."),
  NS("he", "ns4.he.net."),
  NS("he", "ns5.he.net."),

  MX("@", 10, "agony"),
  TXT("@", "v=spf1 mx -all"),
  TXT("_dmarc", "v=DMARC1; p=none; rua=mailto:admin+dmarc-aggregate@0jb.de; ruf=mailto:admin+dmarc-forensic@0jb.de; fo=1; adkim=s; aspf=s"),
  TXT("beinke.cloud._report._dmarc", "v=DMARC1"),
  TXT("janbeinke.com._report._dmarc", "v=DMARC1"),
  TXT("2018-10._domainkey", "v=DKIM1; k=rsa; p=MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAmqyppEu6rgRpwRIZ9eVgTiXCP8RIzEoZLve5R7aJDlo9qawiVeG1ReLXvTEcbSGpHMZXg+Ew3OkwF3KbT8xAnPelw8E5DrB1pf3IkQKdYILJRNEdarNOnd03Cs4ZDNnpd/sNFeqKVLfSBY9pq8YJ5k7yFYjgVm5KiuB1dqgffiJZ6PiERfMx9yb79NYCNv3JNkfohgcfZtUEZf/WXdJQQzAGzEUkvih12DjFa6JMliAP2c0+ZquMO6aeL+KxKHaN1gimWi/bxpaLXPXSmnFuTJIxQsRGuL5XHwtW+iKJz/1a0WJfhINQ+nipOzZsUsaeui7zaxYGeeLwbc113pJXKsnMc7fw7htFEupHEXOHvcxaBZre+DyLKK/jjK+lM8rOQPUu1V9lUsZ9R4m1FHafMIXYhWmRp72NZpqtmcjXdqaPgAgGlbzxfn0219H5UDT0Yymd6RZN89AaY/ms3sm8L2RCWbcQk64WM8QmO2L9CHMdbhSDknYx3w6/j7BWQO3O8syXZy3sc3/PySr3nqks9syEekqp6HH48znGJblu/bSjXegtOZ+s+bHLoSKsPKCXYPt6DKfoOrnxNVRElG0Op3Ou3idxFNnZxgfAp9wvYrOui9WIJZ6Xe8GUkvVA8eTDEXHAQc577NrQYNd30puusblfRlZ9xG8JwLkrz1jyq6ECAwEAAQ=="),
  TXT("mail._domainkey", "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDEGcg4iDvOQVOTnGLsZcQgAx2wemqYgyvbDKD3vk05nnd+EL8ta8pq0PVNHzuI75hmVohkAD7HJi4G5hudLLfIlVr8Cams7MKYZn13bmKtlKoiuGx2o8Yb9BRmPTkrbHlv7DIBjS/EQt/mWW64qpv5ED0HwgyNpj7F9NXUXMMJMQIDAQAB"),
  TXT("_keybase", "keybase-site-verification=EO_b3ub9rlX1xBO3KbEPfOh6PkrvTZXOOC0EzfIW0TI"),
  TXT("_keybase", "keybase-site-verification=q79aAfVelFuToBXZ8s4I5G1lzFA7JoJanP8np029Z7U"),

  HOST("@", "forever"),

  CNAME("backup", "forever"),
  CNAME("mail", "maildeb9"),
  CNAME("maildeb", "maildeb9"),

  CNAME_ACME("anki", "forever"),
  CNAME_ACME("autoconfig", "agony"),
  CNAME_ACME("element", "forever"),
  CNAME_ACME("grafana", "roborock"),
  CNAME_ACME("grocy", "roborock"),
  CNAME_ACME("ha", "y"),
  CNAME_ACME("home", "roborock"),
  CNAME_ACME("klipper", "y"),
  CNAME_ACME("mailmetrics", "forever"),
  CNAME_ACME("matrix", "forever"),

  []
);

D("beinke.cloud", REG_NONE, DnsProvider("inwx"),
  INWX_PARKING("@"),

  MX("@", 10, "agony.0jb.de."),
  TXT("@", "v=spf1 mx -all"),
  TXT("_dmarc", "v=DMARC1; p=none; rua=mailto:admin+dmarc-aggregate@0jb.de;"),
  TXT("mail._domainkey", "v=DKIM1; k=rsa; s=email; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCdd8tHEdS2GXue5+o131MbV4I8uXYqOxq5qK0oFaChxvUC1sYdXwE+YUsWArT6SFZSADWQIJfvXDtc6JL+dvzQZGsnh9M8CqbIfTo1FHLOWpeKv/wPEbB7fJwqP0mKW9l72DRX7Gyic8VY6ZgTaCA1UjSKlC39FX/AEoyDFpMEwwIDAQAB"),

  CNAME_ACME("autoconfig", "agony"),
  CNAME_ACME("imap", "agony"),
  CNAME_ACME("smtp", "agony"),

  []
)

for (var hostname in hosts) {
  D_EXTEND("0jb.de", HOST(hostname));
}
