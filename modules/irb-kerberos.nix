{ wat, ... }:
{
  flake.nixosModules.irb-kerberos = wat.mkModule [ "irb-kerberos" ] (
    { cfg, pkgs, ... }:

    {

      environment.systemPackages = [ pkgs.krb5 ];

      environment.etc."krb5.conf".source = ./_irb-kerberos/krb5.conf;

    }

  );
}
