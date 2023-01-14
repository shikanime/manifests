FROM hashicorp/terraform:1.3.3

# Change path to Terraform source
WORKDIR /usr/src/app

# Copy source
COPY . .

# Install dependencies
RUN --mount=type=secret,id=google-application-credentials,dst=/root/.config/gcloud/application_default_credentials.json \
    terraform -chdir=deploy/terraform/environments/sfeir-par-router/infrastructure init && \
    terraform -chdir=deploy/terraform/environments/sfeir-par-router/platform init
