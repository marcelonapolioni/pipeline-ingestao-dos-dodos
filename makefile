# ─── Variáveis de configuração ────────────────────────────────────────────────
# Você pode sobrescrever qualquer uma delas via ENV ou linha de comando:
#
#    make build PROJECT_ID=outro-projeto LOG_BUCKET=meu-bucket
#
PROJECT_ID   ?= pelagic-gist-311517       # ID do projeto GCP
REGION       ?= us-central1              # Região do Artifact Registry
REPO         ?= docker-repo              # Nome do repositório no Artifact Registry
IMAGE_NAME   ?= dbt-image                # Nome da imagem Docker
LOG_BUCKET   ?=  pelagic-gist-311517-cloudbuild-logs      # Bucket customizado para logs do Cloud Build

# ─── Tag da imagem ────────────────────────────────────────────────────────────
# Usa o SHA curto do último commit Git
BUILD_TAG    := $(shell git rev-parse --short HEAD)

# ─── URI completa da imagem ───────────────────────────────────────────────────
IMAGE_URI    := $(REGION)-docker.pkg.dev/$(PROJECT_ID)/$(REPO)/$(IMAGE_NAME):$(BUILD_TAG)

# --- Target: build ---
# Constroi a imagem Docker e envia para o Artifact Registry
# A variável IMAGE_URI é esperada do ambiente (passada via --substitutions pelo Cloud Build)
.PHONY: build
build:
	@echo "► Construindo e enviando imagem Docker: $(IMAGE_URI)"
	docker build -t "$(IMAGE_URI)" .  # Constrói a imagem usando o Dockerfile local e aplica a tag
	docker push "$(IMAGE_URI)"         # Envia a imagem com a tag para o Artifact Registry

# ─── Target: test ──────────────────────────────────────────────────────────────
.PHONY: test
test:
	@echo "▶ Executando testes DBT localmente"
	# entra no diretório dbt, instala deps, verifica conexão e executa testes
	cd dbt && \
	dbt deps && \
	dbt debug && \
	dbt test


