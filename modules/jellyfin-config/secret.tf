data "kubernetes_secret_v1" "pkcs12_password" {
  metadata {
    name      = var.passwordSecretRef.name
    namespace = var.namespace
  }
}

locals {
  network_xml = <<-XML
    <?xml version="1.0" encoding="utf-8"?>
    <NetworkConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
      <BaseUrl />
      <EnableHttps>true</EnableHttps>
      <RequireHttps>true</RequireHttps>
      <CertificatePath>/etc/ssl/private/keystore.p12</CertificatePath>
      <CertificatePassword>${data.kubernetes_secret_v1.pkcs12_password.data["password"]}</CertificatePassword>
      <InternalHttpPort>8096</InternalHttpPort>
      <InternalHttpsPort>8920</InternalHttpsPort>
      <PublicHttpPort>8096</PublicHttpPort>
      <PublicHttpsPort>8920</PublicHttpsPort>
      <AutoDiscovery>true</AutoDiscovery>
      <EnableIPv4>true</EnableIPv4>
      <EnableIPv6>true</EnableIPv6>
      <EnableRemoteAccess>true</EnableRemoteAccess>
      <LocalNetworkSubnets />
      <LocalNetworkAddresses />
      <KnownProxies />
      <IgnoreVirtualInterfaces>true</IgnoreVirtualInterfaces>
      <VirtualInterfaceNames>
        <string>veth</string>
      </VirtualInterfaceNames>
      <EnablePublishedServerUriByRequest>false</EnablePublishedServerUriByRequest>
      <PublishedServerUriBySubnet>
        <string>192.168.0.0/16=jellyfin.taila659a.ts.net</string>
        <string>100.64.0.0/8=jellyfin.taila659a.ts.net</string>
        <string>10.244.0.0/16=jellyfin.taila659a.ts.net</string>
      </PublishedServerUriBySubnet>
      <RemoteIPFilter>
        <string>192.168.0.0/16</string>
        <string>127.0.0.1/8</string>
        <string>100.64.0.0/10</string>
        <string>10.244.0.0/16</string>
      </RemoteIPFilter>
      <IsRemoteIPFilterBlacklist>false</IsRemoteIPFilterBlacklist>
    </NetworkConfiguration>
  XML
}

resource "kubernetes_secret_v1" "startup_config" {
  metadata {
    name        = var.name
    namespace   = var.namespace
    labels      = var.labels
    annotations = var.annotations
  }

  data = {
    "network.xml" = trimspace(local.network_xml)
  }

  type = "Opaque"
}
