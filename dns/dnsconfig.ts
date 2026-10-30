const REG_NONE = NewRegistrar("none");
const REG_INWX = NewRegistrar("inwx");

const DNS_DESEC = NewDnsProvider("desec");
const DNS_HE = NewDnsProvider("he");
const DNS_HETZNER = NewDnsProvider("hetzner");
const DNS_INWX = NewDnsProvider("inwx");

type HostData = {
  ipv4Addresses?: string[];
  ipv6Addresses?: string[];
  ipv6Tailscale?: string | null;
};

const hosts = require("hosts.json") as Record<string, HostData>;

function HOST(record_name: string, hostname?: string, options: RecordModifier[] = []): DomainModifier {
  const resolvedHostname = hostname || record_name;
  const host = hosts[resolvedHostname] || {};
  const recs: DomainModifier[] = [];
  const ipv4 = host.ipv4Addresses || [];
  const ipv6 = host.ipv6Addresses || [];
  const ipv6Tailscale = host.ipv6Tailscale ?? null;
  for (const address of ipv4) {
    recs.push(A(record_name, address, ...options));
  }
  for (const address of ipv6) {
    recs.push(AAAA(record_name, address, ...options));
  }
  if (recs.length === 0 && ipv6Tailscale !== null) {
    recs.push(AAAA(record_name, ipv6Tailscale, ...options));
  }
  if (recs.length > 0) {
    recs.push(ACME(record_name, resolvedHostname));
  }
  return recs;
}

function ACME(record_name: string, target: string, options: RecordModifier[] = []): DomainModifier {
  const challengeRecordName = "_acme-challenge" + (record_name === "@" ? "" : "." + record_name);
  if (target === "agony") target = "agony.he.0jb.de.";
  if (target === "ingress") target = "ingress.he.0jb.de.";
  target = target[target.length - 1] === "." ? target : target + ".desec.0jb.de.";
  return [CNAME(challengeRecordName, "_acme-challenge." + target, ...options)];
}

function CNAME_ACME(record_name: string, target: string, options: RecordModifier[] = []): DomainModifier {
  const target_cname = target[target.length - 1] === "." ? target : target + ".0jb.de.";
  return [CNAME(record_name, target_cname, ...options), ACME(record_name, target)];
}

function INGRESS(record_name: string, target: string, options: RecordModifier[] = []): DomainModifier {
  return [CNAME(record_name, "ingress.0jb.de.", ...options), ACME(record_name, target)];
}

function INWX_PARKING(record_name: string): DomainModifier {
  return A(record_name, "185.181.104.242");
}

function CAA_LETSENCRYPT(record_name = "@"): DomainModifier {
  return CAA_BUILDER({
    label: record_name,
    issue: ["letsencrypt.org;validationmethods=dns-01"],
    issue_critical: true,
  });
}

function FASTMAIL_MX(record_name = "@"): DomainModifier {
  return [
    MX(record_name, 10, "in1-smtp.messagingengine.com."),
    MX(record_name, 20, "in2-smtp.messagingengine.com."),
  ];
}

interface FastmailProps {
  extra_spf?: string[],
}

function FASTMAIL(domain: string, props: FastmailProps = {}): DomainModifier {
  const extra_spf = props.extra_spf ?? [];
  return [
    FASTMAIL_MX(),
    CNAME("fm1._domainkey", "fm1." + domain + ".dkim.fmhosted.com."),
    CNAME("fm2._domainkey", "fm2." + domain + ".dkim.fmhosted.com."),
    CNAME("fm3._domainkey", "fm3." + domain + ".dkim.fmhosted.com."),
    SPF_BUILDER({
      parts: [
        "v=spf1",
        ...extra_spf,
        "include:spf.messagingengine.com.",
        "-all",
      ],
    }),
    TXT("_dmarc", "v=DMARC1; p=reject; rua=mailto:admin+dmarc-aggregate@0jb.de; ruf=mailto:admin+dmarc-forensic@0jb.de; fo=1; adkim=s; aspf=s"),
  ];
}

DEFAULTS(
  NAMESERVER_TTL("1d"),
  DefaultTTL("1h")
);

D("he.0jb.de", REG_NONE, DnsProvider("he"),
  NAMESERVER_TTL("2d"),
  IGNORE("_acme-challenge.*", "TXT")
);

D("0jb.de", REG_NONE, DnsProvider("desec"),
  CAA_LETSENCRYPT(),

  NS("he", "ns1.he.net."),
  NS("he", "ns2.he.net."),
  NS("he", "ns3.he.net."),
  NS("he", "ns4.he.net."),
  NS("he", "ns5.he.net."),

  IGNORE("_acme-challenge.*.desec", "TXT"),
  CAA("*.desec", "issue", ";"),  // needed to prevent NXDOMAIN in acme lookup

  FASTMAIL("0jb.de"),

  TXT("beinke.cloud._report._dmarc", "v=DMARC1"),
  TXT("janbeinke.com._report._dmarc", "v=DMARC1"),

  TXT("_keybase", "keybase-site-verification=EO_b3ub9rlX1xBO3KbEPfOh6PkrvTZXOOC0EzfIW0TI"),
  TXT("_keybase", "keybase-site-verification=q79aAfVelFuToBXZ8s4I5G1lzFA7JoJanP8np029Z7U"),

  HOST("@", "forever"),

  CNAME("backup", "forever"),
  CNAME("mc", "forever"),

  CNAME_ACME("anki", "forever"),
  CNAME_ACME("autoconfig", "agony"),
  CNAME_ACME("bruchstr", "rqwx2qyix9huowcrs3nuslek89tr3ogu.ui.nabu.casa."),
  CNAME_ACME("crowdsec", "forever"),
  CNAME_ACME("element", "forever"),
  CNAME_ACME("ender3s1", "y"),
  INGRESS("grafana", "y"),
  INGRESS("ha", "hass"),
  A("local.ha", "192.168.1.30"),
  ACME("local.ha", "hass"),
  CNAME_ACME("klipper", "y"),
  CNAME_ACME("loki", "y"),
  INGRESS("ma", "hass"),
  A("local.ma", "192.168.1.30"),
  ACME("local.ma", "hass"),
  CNAME_ACME("mailmetrics", "forever"),
  CNAME_ACME("matrix", "forever"),
  CNAME_ACME("prometheus", "y"),
  CNAME_ACME("spoolman", "y"),

  ACME("snapcast", "y"),
  A("snapcast", "192.168.1.3")
);

D("beinke.cloud", REG_NONE, DnsProvider("inwx"),
  CAA_LETSENCRYPT(),

  INWX_PARKING("@"),
  ACME("@", "ingress"),

  FASTMAIL("beinke.cloud", {
    extra_spf: [
      "a:agony.0jb.de."
    ],
  }),
  FASTMAIL_MX("*"),
  FASTMAIL_MX("sibylle"),

  INGRESS("actual", "starblade"),
  INGRESS("audiobooks", "y"),
  INGRESS("auth", "starblade"),
  CNAME_ACME("autoconfig", "agony"),
  INGRESS("docs.sibylle", "starblade"),
  CNAME_ACME("imap", "agony"),
  INGRESS("paperless", "starblade"),
  CNAME_ACME("pw", "forever"),
  CNAME_ACME("smtp", "agony")
);

D("janbeinke.com", REG_NONE, DnsProvider("inwx"),
  CAA_LETSENCRYPT(),

  INWX_PARKING("@"),
  ACME("@", "ingress"),

  FASTMAIL("janbeinke.com"),

  TXT("_keybase", "keybase-site-verification=zHhKLQ9z6u8O1qIS1irkZmAQng6Z--lzJMyMEjp5KFw")
);

D("thelegy.de", REG_NONE, DnsProvider("inwx"),
  CAA_LETSENCRYPT(),

  INWX_PARKING("@"),
  ACME("@", "ingress"),

  TXT("_keybase", "keybase-site-verification=EO_b3ub9rlX1xBO3KbEPfOh6PkrvTZXOOC0EzfIW0TI")
);

D("die-cloud.org", REG_NONE, DnsProvider("inwx"),
  CAA_LETSENCRYPT(),

  INWX_PARKING("@"),
  ACME("@", "ingress"),

  FASTMAIL("die-cloud.org"),
);

D("janbeinke.de", REG_NONE, DnsProvider("inwx"),
  CAA_LETSENCRYPT(),

  INWX_PARKING("@"),

  TXT("_keybase", "keybase-site-verification=q79aAfVelFuToBXZ8s4I5G1lzFA7JoJanP8np029Z7U")
);

D("peterbeinke.de", REG_NONE, DnsProvider("inwx"),
  CAA_LETSENCRYPT(),

  INWX_PARKING("@"),
);

for (const hostname of Object.keys(hosts)) {
  D_EXTEND("0jb.de", [
    HOST(hostname),
    CNAME("*." + hostname, hostname),
  ]);
}
