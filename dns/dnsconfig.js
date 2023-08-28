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

  []
);

for (var hostname in hosts) {
  D_EXTEND("0jb.de", HOST(hostname));
}
