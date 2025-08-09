{
  mkTrivialModule,
  pkgs,
  ...
}:

mkTrivialModule {

  environment.systemPackages = [ pkgs.krb5 ];

  environment.etc."krb5.conf".source = ./krb5.conf;

}
