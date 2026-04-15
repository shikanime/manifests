resource "random_password" "api_key" {
  length  = 32
  lower   = true
  numeric = true
  special = false
  upper   = false
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
      <ApiKey>${random_password.api_key.result}</ApiKey>
      <AuthenticationMethod>None</AuthenticationMethod>
      <BindAddress>*</BindAddress>
      <EnableSsl>True</EnableSsl>
      <InstanceName>radarr</InstanceName>
      <LaunchBrowser>False</LaunchBrowser>
      <LogLevel>info</LogLevel>
      <Port>7878</Port>
      <SslCertPassword>${data.kubernetes_secret_v1.pkcs12_password.data["password"]}</SslCertPassword>
      <SslCertPath>/etc/ssl/private/keystore.p12</SslCertPath>
      <SslPort>9898</SslPort>
      <UrlBase></UrlBase>
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
