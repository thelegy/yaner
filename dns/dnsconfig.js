"use strict";
var __spreadArray = (this && this.__spreadArray) || function (to, from, pack) {
    if (pack || arguments.length === 2) for (var i = 0, l = from.length, ar; i < l; i++) {
        if (ar || !(i in from)) {
            if (!ar) ar = Array.prototype.slice.call(from, 0, i);
            ar[i] = from[i];
        }
    }
    return to.concat(ar || Array.prototype.slice.call(from));
};
var REG_NONE = NewRegistrar("none");
var REG_INWX = NewRegistrar("inwx");
var DNS_DESEC = NewDnsProvider("desec");
var DNS_HE = NewDnsProvider("he");
var DNS_HETZNER = NewDnsProvider("hetzner");
var DNS_INWX = NewDnsProvider("inwx");
var hosts = require("hosts.json");
function HOST(record_name, hostname, options) {
    var _a;
    if (options === void 0) { options = []; }
    var resolvedHostname = hostname || record_name;
    var host = hosts[resolvedHostname] || {};
    var recs = [];
    var ipv4 = host.ipv4Addresses || [];
    var ipv6 = host.ipv6Addresses || [];
    var ipv6Tailscale = (_a = host.ipv6Tailscale) !== null && _a !== void 0 ? _a : null;
    for (var _i = 0, ipv4_1 = ipv4; _i < ipv4_1.length; _i++) {
        var address = ipv4_1[_i];
        recs.push(A.apply(void 0, __spreadArray([record_name, address], options, false)));
    }
    for (var _b = 0, ipv6_1 = ipv6; _b < ipv6_1.length; _b++) {
        var address = ipv6_1[_b];
        recs.push(AAAA.apply(void 0, __spreadArray([record_name, address], options, false)));
    }
    if (recs.length === 0 && ipv6Tailscale !== null) {
        recs.push(AAAA.apply(void 0, __spreadArray([record_name, ipv6Tailscale], options, false)));
    }
    if (recs.length > 0) {
        recs.push(ACME(record_name, resolvedHostname));
    }
    return recs;
}
function ACME(record_name, target, options) {
    if (options === void 0) { options = []; }
    var challengeRecordName = "_acme-challenge" + (record_name === "@" ? "" : "." + record_name);
    if (target === "agony")
        target = "agony.he.0jb.de.";
    if (target === "ingress")
        target = "ingress.he.0jb.de.";
    target = target[target.length - 1] === "." ? target : target + ".desec.0jb.de.";
    return [CNAME.apply(void 0, __spreadArray([challengeRecordName, "_acme-challenge." + target], options, false))];
}
function CNAME_ACME(record_name, target, options) {
    if (options === void 0) { options = []; }
    var target_cname = target[target.length - 1] === "." ? target : target + ".0jb.de.";
    return [CNAME.apply(void 0, __spreadArray([record_name, target_cname], options, false)), ACME(record_name, target)];
}
function INGRESS(record_name, target, options) {
    if (options === void 0) { options = []; }
    return [CNAME.apply(void 0, __spreadArray([record_name, "ingress.0jb.de."], options, false)), ACME(record_name, target)];
}
function INWX_PARKING(record_name) {
    return A(record_name, "185.181.104.242");
}
function CAA_LETSENCRYPT(record_name) {
    if (record_name === void 0) { record_name = "@"; }
    return CAA_BUILDER({
        label: record_name,
        issue: ["letsencrypt.org;validationmethods=dns-01"],
        issue_critical: true,
    });
}
function FASTMAIL_MX(record_name) {
    if (record_name === void 0) { record_name = "@"; }
    return [
        MX(record_name, 10, "in1-smtp.messagingengine.com."),
        MX(record_name, 20, "in2-smtp.messagingengine.com."),
    ];
}
function FASTMAIL(domain, props) {
    var _a;
    if (props === void 0) { props = {}; }
    var extra_spf = (_a = props.extra_spf) !== null && _a !== void 0 ? _a : [];
    return [
        FASTMAIL_MX(),
        CNAME("fm1._domainkey", "fm1." + domain + ".dkim.fmhosted.com."),
        CNAME("fm2._domainkey", "fm2." + domain + ".dkim.fmhosted.com."),
        CNAME("fm3._domainkey", "fm3." + domain + ".dkim.fmhosted.com."),
        SPF_BUILDER({
            parts: __spreadArray(__spreadArray([
                "v=spf1"
            ], extra_spf, true), [
                "include:spf.messagingengine.com.",
                "-all",
            ], false),
        }),
        TXT("_dmarc", "v=DMARC1; p=reject; rua=mailto:admin+dmarc-aggregate@0jb.de; ruf=mailto:admin+dmarc-forensic@0jb.de; fo=1; adkim=s; aspf=s"),
    ];
}
DEFAULTS(NAMESERVER_TTL("1d"), DefaultTTL("1h"));
D("he.0jb.de", REG_NONE, DnsProvider("he"), NAMESERVER_TTL("2d"), IGNORE("_acme-challenge.*", "TXT"));
D("0jb.de", REG_NONE, DnsProvider("desec"), CAA_LETSENCRYPT(), NS("he", "ns1.he.net."), NS("he", "ns2.he.net."), NS("he", "ns3.he.net."), NS("he", "ns4.he.net."), NS("he", "ns5.he.net."), IGNORE("_acme-challenge.*.desec", "TXT"), CAA("*.desec", "issue", ";"), // needed to prevent NXDOMAIN in acme lookup
FASTMAIL("0jb.de"), TXT("beinke.cloud._report._dmarc", "v=DMARC1"), TXT("janbeinke.com._report._dmarc", "v=DMARC1"), TXT("_keybase", "keybase-site-verification=EO_b3ub9rlX1xBO3KbEPfOh6PkrvTZXOOC0EzfIW0TI"), TXT("_keybase", "keybase-site-verification=q79aAfVelFuToBXZ8s4I5G1lzFA7JoJanP8np029Z7U"), HOST("@", "forever"), CNAME("backup", "forever"), CNAME("mc", "forever"), CNAME_ACME("anki", "forever"), CNAME_ACME("autoconfig", "agony"), CNAME_ACME("bruchstr", "rqwx2qyix9huowcrs3nuslek89tr3ogu.ui.nabu.casa."), CNAME_ACME("crowdsec", "forever"), CNAME_ACME("element", "forever"), CNAME_ACME("ender3s1", "y"), INGRESS("grafana", "y"), INGRESS("ha", "hass"), A("local.ha", "192.168.1.30"), ACME("local.ha", "hass"), CNAME_ACME("klipper", "y"), CNAME_ACME("loki", "y"), INGRESS("ma", "hass"), A("local.ma", "192.168.1.30"), ACME("local.ma", "hass"), CNAME_ACME("mailmetrics", "forever"), CNAME_ACME("matrix", "forever"), CNAME_ACME("prometheus", "y"), CNAME_ACME("spoolman", "y"), ACME("snapcast", "y"), A("snapcast", "192.168.1.3"));
D("beinke.cloud", REG_NONE, DnsProvider("inwx"), CAA_LETSENCRYPT(), INWX_PARKING("@"), ACME("@", "ingress"), FASTMAIL("beinke.cloud", {
    extra_spf: [
        "a:agony.0jb.de."
    ],
}), FASTMAIL_MX("*"), FASTMAIL_MX("sibylle"), INGRESS("actual", "starblade"), INGRESS("audiobooks", "y"), INGRESS("auth", "starblade"), CNAME_ACME("autoconfig", "agony"), INGRESS("docs.sibylle", "starblade"), CNAME_ACME("imap", "agony"), INGRESS("paperless", "starblade"), CNAME_ACME("pw", "forever"), CNAME_ACME("smtp", "agony"));
D("janbeinke.com", REG_NONE, DnsProvider("inwx"), CAA_LETSENCRYPT(), INWX_PARKING("@"), ACME("@", "ingress"), FASTMAIL("janbeinke.com"), TXT("_keybase", "keybase-site-verification=zHhKLQ9z6u8O1qIS1irkZmAQng6Z--lzJMyMEjp5KFw"));
D("thelegy.de", REG_NONE, DnsProvider("inwx"), CAA_LETSENCRYPT(), INWX_PARKING("@"), ACME("@", "ingress"), TXT("_keybase", "keybase-site-verification=EO_b3ub9rlX1xBO3KbEPfOh6PkrvTZXOOC0EzfIW0TI"));
D("die-cloud.org", REG_NONE, DnsProvider("inwx"), CAA_LETSENCRYPT(), INWX_PARKING("@"), ACME("@", "ingress"), FASTMAIL("die-cloud.org"));
D("janbeinke.de", REG_NONE, DnsProvider("inwx"), CAA_LETSENCRYPT(), INWX_PARKING("@"), TXT("_keybase", "keybase-site-verification=q79aAfVelFuToBXZ8s4I5G1lzFA7JoJanP8np029Z7U"));
D("peterbeinke.de", REG_NONE, DnsProvider("inwx"), CAA_LETSENCRYPT(), INWX_PARKING("@"));
for (var _i = 0, _a = Object.keys(hosts); _i < _a.length; _i++) {
    var hostname = _a[_i];
    D_EXTEND("0jb.de", [
        HOST(hostname),
        CNAME("*." + hostname, hostname),
    ]);
}
