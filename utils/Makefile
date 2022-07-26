inflate-transmission:
	helm template transmission k8s-at-home/transmission \
		--output-dir transmission/chart \
		--values transmission/values.yaml

inflate-jellyfin:
	helm template jellyfin k8s-at-home/jellyfin \
		--output-dir jellyfin/chart \
		--values jellyfin/values.yaml

inflate-sonarqube:
	helm template sonarqube sonarqube/sonarqube \
		--output-dir sonarqube/chart \
		--values sonarqube/values.yaml

inflate-prefect-server:
	helm template prefect-server prefecthq/prefect-server \
		--output-dir prefect-server/chart \
		--values prefect-server/values.yaml

inflate-haproxy:
	helm template haproxy haproxytech/haproxy \
		--output-dir haproxy/chart \
		--values haproxy/values.yaml
