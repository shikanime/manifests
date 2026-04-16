resource "random_id" "api_key" {
  byte_length = 16
}

data "kubernetes_secret_v1" "pkcs12_password" {
  metadata {
    name      = var.passwordSecretRef.name
    namespace = var.namespace
  }
}

locals {
  config_xml = <<-XML
    <Config>
      <BindAddress>*</BindAddress>
      <Port>9696</Port>
      <SslPort>6969</SslPort>
      <EnableSsl>True</EnableSsl>
      <LaunchBrowser>True</LaunchBrowser>
      <ApiKey>${random_id.api_key.hex}</ApiKey>
      <AuthenticationMethod>Forms</AuthenticationMethod>
      <AuthenticationRequired>Enabled</AuthenticationRequired>
      <Branch>master</Branch>
      <LogLevel>info</LogLevel>
      <SslCertPath>/etc/ssl/private/keystore.p12</SslCertPath>
      <SslCertPassword>${data.kubernetes_secret_v1.pkcs12_password.data["password"]}</SslCertPassword>
      <UrlBase></UrlBase>
      <InstanceName>Prowlarr</InstanceName>
      <UpdateMechanism>Docker</UpdateMechanism>
      <AnalyticsEnabled>False</AnalyticsEnabled>
    </Config>
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
    "config.xml" = trimspace(local.config_xml)
  }

  type = "Opaque"
}
