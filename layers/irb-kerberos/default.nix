{ pkgs, ... }:
{

  environment.systemPackages = [ pkgs.kerberos ];

  environment.etc."krb5.conf".source = ./krb5.conf;

}