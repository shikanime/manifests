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
      <EnableSsl>True</EnableSsl>
      <Port>8989</Port>
      <SslPort>9898</SslPort>
      <UrlBase></UrlBase>
      <BindAddress>*</BindAddress>
      <ApiKey>${random_id.api_key.hex}</ApiKey>
      <AuthenticationMethod>Forms</AuthenticationMethod>
      <UpdateMechanism>Docker</UpdateMechanism>
      <LaunchBrowser>True</LaunchBrowser>
      <Branch>main</Branch>
      <InstanceName>Sonarr</InstanceName>
      <SyslogPort>514</SyslogPort>
      <UpdateAutomatically>True</UpdateAutomatically>
      <AuthenticationRequired>Enabled</AuthenticationRequired>
      <SslCertPath>/etc/ssl/private/keystore.p12</SslCertPath>
      <SslCertPassword>${data.kubernetes_secret_v1.pkcs12_password.data["password"]}</SslCertPassword>
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
