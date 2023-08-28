var REG_NONE = NewRegistrar("none");
var DNS_INWX = NewDnsProvider("inwx");
var DNS_HE = NewDnsProvider("he");


hosts = require("../modules/hosts/hosts.json");
function HOST(record_name, hostname) {
  var hostname = hostname || record_name;
  var recs = [];
  ipv4 = hosts[hostname]["ipv4Addresses"] || [];
  ipv6 = hosts[hostname]["ipv6Addresses"] || [];
  for (var a in ipv4) { recs.push(A(record_name, ipv4[a])); }
  for (var a in ipv6) { recs.push(AAAA(record_name, ipv6[a])); }
  return recs;
}


D("0jb.de", REG_NONE, DnsProvider("he"),
  DefaultTTL("1h"),

  HOST("@", "forever"),
  MX("@", 10, "agony"),
  TXT("@", "v=spf1 mx -all"),
  TXT("_dmarc", "v=DMARC1; p=none; rua=mailto:admin+dmarc-aggregate@0jb.de; ruf=mailto:admin+dmarc-forensic@0jb.de; fo=1; adkim=s; aspf=s"),
  TXT("beinke.cloud._report._dmarc", "v=DMARC1"),
  TXT("janbeinke.com._report._dmarc", "v=DMARC1"),
  TXT("2018-10._domainkey", "v=DKIM1; k=rsa; p=MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAmqyppEu6rgRpwRIZ9eVgTiXCP8RIzEoZLve5R7aJDlo9qawiVeG1ReLXvTEcbSGpHMZXg+Ew3OkwF3KbT8xAnPelw8E5DrB1pf3IkQKdYILJRNEdarNOnd03Cs4ZDNnpd/sNFeqKVLfSBY9pq8YJ5k7yFYjgVm5KiuB1dqgffiJZ6PiERfMx9yb79NYCNv3JNkfohgcfZtUEZf/WXdJQQzAGzEUkvih12DjFa6JMliAP2c0+ZquMO6aeL+KxKHaN1gimWi/bxpaLXPXSmnFuTJIxQsRGuL5XHwtW+iKJz/1a0WJfhINQ+nipOzZsUsaeui7zaxYGeeLwbc113pJXKsnMc7fw7htFEupHEXOHvcxaBZre+DyLKK/jjK+lM8rOQPUu1V9lUsZ9R4m1FHafMIXYhWmRp72NZpqtmcjXdqaPgAgGlbzxfn0219H5UDT0Yymd6RZN89AaY/ms3sm8L2RCWbcQk64WM8QmO2L9CHMdbhSDknYx3w6/j7BWQO3O8syXZy3sc3/PySr3nqks9syEekqp6HH48znGJblu/bSjXegtOZ+s+bHLoSKsPKCXYPt6DKfoOrnxNVRElG0Op3Ou3idxFNnZxgfAp9wvYrOui9WIJZ6Xe8GUkvVA8eTDEXHAQc577NrQYNd30puusblfRlZ9xG8JwLkrz1jyq6ECAwEAAQ=="),
  TXT("mail._domainkey", "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDEGcg4iDvOQVOTnGLsZcQgAx2wemqYgyvbDKD3vk05nnd+EL8ta8pq0PVNHzuI75hmVohkAD7HJi4G5hudLLfIlVr8Cams7MKYZn13bmKtlKoiuGx2o8Yb9BRmPTkrbHlv7DIBjS/EQt/mWW64qpv5ED0HwgyNpj7F9NXUXMMJMQIDAQAB"),
  TXT("_keybase", "keybase-site-verification=EO_b3ub9rlX1xBO3KbEPfOh6PkrvTZXOOC0EzfIW0TI"),
  TXT("_keybase", "keybase-site-verification=q79aAfVelFuToBXZ8s4I5G1lzFA7JoJanP8np029Z7U"),

  CNAME("_acme-challenge", "_acme-challenge.forever.0jb.de."),
  CNAME("_acme-challenge.anki", "_acme-challenge.forever.0jb.de."),
  CNAME("_acme-challenge.matrix", "_acme-challenge.forever.0jb.de."),
  CNAME("_acme-challenge.element", "_acme-challenge.forever.0jb.de."),
  CNAME("_acme-challenge.mailmetrics", "_acme-challenge.forever.0jb.de."),
  CNAME("_acme-challenge.autoconfig", "_acme-challenge.agony.0jb.de."),
  CNAME("_acme-challenge.ha", "_acme-challenge.y.0jb.de."),
  CNAME("_acme-challenge.klipper", "_acme-challenge.y.0jb.de."),

  CNAME("anki", "forever.0jb.de."),
  CNAME("autoconfig", "agony.0jb.de."),
  CNAME("backup", "forever.0jb.de."),
  CNAME("element", "forever.0jb.de."),
  CNAME("grafana", "roborock.0jb.de."),
  CNAME("grocy", "roborock.0jb.de."),
  CNAME("ha", "y.0jb.de."),
  CNAME("klipper", "y.0jb.de."),
  CNAME("mail", "maildeb9.0jb.de."),
  CNAME("maildeb", "maildeb9.0jb.de."),
  CNAME("mailmetrics", "forever.0jb.de."),
  CNAME("matrix", "forever.0jb.de."),

  IGNORE("ever"),
  IGNORE("home"),

  IGNORE("_acme-challenge.agony"),
  IGNORE("_acme-challenge.ever"),
  IGNORE("_acme-challenge.forever"),
  IGNORE("_acme-challenge.grafana"),
  IGNORE("_acme-challenge.grocy"),
  IGNORE("_acme-challenge.home"),
  IGNORE("_acme-challenge.roborock"),
  IGNORE("_acme-challenge.y"),

  []
);

for (var hostname in hosts) {
  D_EXTEND("0jb.de", HOST(hostname));
}
