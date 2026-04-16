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
      <LogLevel>info</LogLevel>
      <BindAddress>*</BindAddress>
      <EnableSsl>True</EnableSsl>
      <SslCertPath>/etc/ssl/private/keystore.p12</SslCertPath>
      <Port>8686</Port>
      <UrlBase></UrlBase>
      <ApiKey>${random_id.api_key.hex}</ApiKey>
      <AuthenticationMethod>Forms</AuthenticationMethod>
      <UpdateMechanism>Docker</UpdateMechanism>
      <SslPort>6868</SslPort>
      <LaunchBrowser>True</LaunchBrowser>
      <Branch>master</Branch>
      <SslCertPassword>${data.kubernetes_secret_v1.pkcs12_password.data["password"]}</SslCertPassword>
      <InstanceName>Lidarr</InstanceName>
      <AnalyticsEnabled>False</AnalyticsEnabled>
      <AuthenticationRequired>Enabled</AuthenticationRequired>
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
