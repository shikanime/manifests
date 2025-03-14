resource "kubernetes_manifest" "helmchart_cert_manager" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "cert-manager"
      namespace = "kube-system"
    }
    spec = {
      repo            = "https://charts.jetstack.io"
      chart           = "cert-manager"
      targetNamespace = "cert-manager"
      version         = "v1.17.1"
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
      valuesContent   = <<-EOT
        crds:
          enabled: true
      EOT
    }
  }

  depends_on = [kubernetes_namespace.cert_manager]
}

resource "kubernetes_manifest" "helmchart_grafana_monitoring" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "grafana-monitoring"
      namespace = "kube-system"
    }
    spec = {
      repo            = "https://grafana.github.io/helm-charts"
      chart           = "k8s-monitoring"
      targetNamespace = "grafana"
      version         = "2.0.18"
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
      valuesContent   = <<-EOT
        cluster:
          name: ${var.name}
        clusterMetrics:
          enabled: true
          opencost:
            enabled: true
            metricsSource: grafana-cloud-metrics
            opencost:
              exporter:
                defaultClusterId: ${var.name}
              prometheus:
                existingSecretName: grafana-monitoring-prometheus
                external:
                  url: https://prometheus-prod-01-eu-west-0.grafana.net/api/prom
          kepler:
            enabled: true
            image:
              tag: release-0.7.8 # FIX: https://github.com/sustainable-computing-io/kepler/issues/1866
        clusterEvents:
          enabled: true
        destinations:
          - name: grafana-cloud-metrics
            type: prometheus
            url: https://prometheus-prod-01-eu-west-0.grafana.net/api/prom/push
            auth:
              type: basic
            secret:
              create: false
              name: grafana-monitoring-prometheus
          - name: grafana-cloud-logs
            type: loki
            url: https://logs-prod-eu-west-0.grafana.net/loki/api/v1/push
            auth:
              type: basic
            secret:
              create: false
              name: grafana-monitoring-loki
          - name: grafana-cloud-traces
            type: otlp
            url: https://tempo-eu-west-0.grafana.net:443
            protocol: grpc
            auth:
              type: basic
            secret:
              create: false
              name: grafana-monitoring-tempo
            metrics:
              enabled: false
            logs:
              enabled: false
            traces:
              enabled: true
        podLogs:
          enabled: true
        applicationObservability:
          enabled: true
          receivers:
            otlp:
              grpc:
                enabled: true
                port: 4317
              http:
                enabled: true
                port: 4318
            zipkin:
              enabled: true
              port: 9411
        integrations:
          alloy:
            instances:
              - name: alloy
                labelSelectors:
                  app.kubernetes.io/name:
                    - alloy-metrics
                    - alloy-singleton
                    - alloy-logs
                    - alloy-receiver
        alloy-metrics:
          enabled: true
        alloy-singleton:
          enabled: true
        alloy-logs:
          enabled: true
        alloy-receiver:
          enabled: true
          alloy:
            extraPorts:
              - name: otlp-grpc
                port: 4317
                targetPort: 4317
                protocol: TCP
              - name: otlp-http
                port: 4318
                targetPort: 4318
                protocol: TCP
              - name: zipkin
                port: 9411
                targetPort: 9411
                protocol: TCP
        EOT
    }
  }

  depends_on = [kubernetes_namespace.grafana]
}

resource "kubernetes_manifest" "helmchart_longhorn" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "longhorn"
      namespace = "kube-system"
    }
    spec = {
      repo            = "https://charts.longhorn.io"
      chart           = "longhorn"
      targetNamespace = "longhorn-system"
      version         = "1.8.1"
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
      valuesContent   = <<-EOT
        defaultSettings:
          allowCollectingLonghornUsageMetrics: false
          backupstorePollInterval: 6000
          defaultReplicaCount: 2
          replicaAutoBalance: least-effort
          snapshotDataIntegrityCronjob: "0 4 */7 * *"
        defaultBackupStore:
          backupTarget: s3://${var.longhorn_backupstore.bucket}@${var.longhorn_backupstore.region}/
          backupTargetCredentialSecret: longhorn-hetzner-backups
        persistence:
          defaultClassReplicaCount: 2
          defaultFsType: xfs
      EOT
    }
  }

  depends_on = [kubernetes_namespace.longhorn_system]
}

resource "kubernetes_manifest" "helmchart_multus" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "multus"
      namespace = "kube-system"
    }
    spec = {
      repo            = "https://rke2-charts.rancher.io"
      chart           = "rke2-multus"
      targetNamespace = "kube-system"
      version         = "v4.1.404"
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
      valuesContent   = <<-EOT
        config:
          fullnameOverride: multus
          cni_conf:
            confDir: /var/lib/rancher/k3s/agent/etc/cni/net.d
            binDir: /var/lib/rancher/k3s/data/cni/
            kubeconfig: /var/lib/rancher/k3s/agent/etc/cni/net.d/multus.d/multus.kubeconfig
        manifests:
          dhcpDaemonSet: true
      EOT
    }
  }
}

resource "kubernetes_manifest" "helmchart_node_feature_discovery" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "node-feature-discovery"
      namespace = "kube-system"
    }
    spec = {
      repo            = "https://kubernetes-sigs.github.io/node-feature-discovery/charts"
      chart           = "node-feature-discovery"
      targetNamespace = "kube-system"
      version         = "0.17.2"
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
    }
  }
}

resource "kubernetes_manifest" "helmchart_vpa" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "vpa"
      namespace = "kube-system"
    }
    spec = {
      repo            = "https://charts.fairwinds.com/stable"
      chart           = "vpa"
      targetNamespace = "kube-system"
      version         = "4.7.2"
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
    }
  }
}
