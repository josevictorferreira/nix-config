# k9s cluster configurations
# Pure data export - no module boilerplate
{ }:
{
  homelab = {
    cluster = "ze-homelab";
    readOnly = false;
    namespace = {
      active = "apps";
      favorites = [
        "all"
        "monitoring"
        "rook-ceph"
      ];
    };
    view = {
      active = "pods";
    };
  };

  agrosmartEks = {
    cluster = "agrosmart-eks";
    readOnly = false;
    namespace = {
      active = "default";
      favorites = [
        "production"
        "all"
      ];
    };
    view = {
      active = "pods";
    };
  };
}
