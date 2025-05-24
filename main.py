import logging
import traceback

import functions_framework
import requests
import pandas as pd
from google.cloud import bigquery

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)

def run_extraction() -> bool:
    try:
        logging.info("🔐 Iniciando autenticação no Auth0")
        auth_url = "https://paineldocorretor.auth0.com/oauth/token"
        auth_payload = {
            "grant_type": "http://auth0.com/oauth/grant-type/password-realm",
            "username": "vanessa.burgo@razycorretora.com.br",
            "password": "Razy2025!",
            "audience": "https://paineldocorretor.com.br/api/",
            "scope": "openid profile offline_access email",
            "client_id": "MtCJ0bBdECwihpKoeTBf9L0E6JvCEx24",
            "realm": "Username-Password-Authentication"
        }
        response = requests.post(auth_url, json=auth_payload)
        response.raise_for_status()
        token = response.json().get("access_token")
        logging.info("✅ Autenticação bem‑sucedida, token obtido")

        logging.info("🌐 Executando consulta GraphQL")
        graphql_url = "https://api.paineldocorretor.net/graphql"
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "User-Agent": "Mozilla/5.0"
        }
        query = """
        query NegociosExportacao($request: NegociosFilterInput!) {
            negocios: negociosElastic(request: $request) {
                items {
                    id
                    nome
                    contrato
                    criadoEm
                    fechamento
                    valor
                    etapa { nome }
                    contato {
                        id
                        nome
                        email
                        documento
                        cidade
                        telefones
                        avatar
                    }
                    vendedor { email }
                    produto {
                        id
                        nome
                        ramo
                    }
                    etiquetas { nome }
                    anotacoes {
                        criadoEm
                        mensagem
                        criadoPor { nome }
                    }
                }
            }
        }
        """
        variables = {"request": {"take": 10000, "conditions": []}}
        gql_resp = requests.post(graphql_url, headers=headers, json={
            "query": query,
            "variables": variables,
            "operationName": "NegociosExportacao"
        })
        gql_resp.raise_for_status()
        data = gql_resp.json()

        if not data.get("data") or not data["data"].get("negocios"):
            raise RuntimeError(f"Resposta API inválida: {data}")
        logging.info("✅ GraphQL OK, normalizando dados")

        items = data["data"]["negocios"]["items"]
        logging.info(f"📦 Itens retornados pela API: {len(items)}")

        df = pd.json_normalize(items)
        df.columns = [c.replace(".", "_") for c in df.columns]
        logging.info(f"📊 DataFrame montado: {df.shape[0]} linhas, {df.shape[1]} colunas")

        def limpar_celula(v):
            if isinstance(v, list):
                return ", ".join(
                    str(i.get("nome", i)) if isinstance(i, dict) else str(i)
                    for i in v
                )
            if isinstance(v, dict):
                return str(v)
            return v

        df = df.applymap(limpar_celula)

        # Filtrar apenas a partir de 2025
        DATA_CORTE = '2025-01-01'
        if 'criadoEm' in df.columns:
            df['criadoEm'] = pd.to_datetime(df['criadoEm'], errors='coerce')
            linhas_antes = df.shape[0]
            df = df[df['criadoEm'] >= DATA_CORTE]
            linhas_depois = df.shape[0]
            logging.info(
                f"📅 Aplicado filtro para criadoEm >= {DATA_CORTE}. "
                f"Registros antes: {linhas_antes} | Registros após: {linhas_depois}"
            )
        else:
            logging.warning("⚠️ Coluna 'criadoEm' não encontrada para filtrar por data.")

        # --------------------------------------------------------------------------------------

        logging.info("✅ Dados prontos, carregando no BigQuery")

        client = bigquery.Client()
        table_id = "pelagic-gist-311517.crm_raw.negocios"
        job_config = bigquery.LoadJobConfig(
            write_disposition="WRITE_TRUNCATE",
            autodetect=True
        )
        job = client.load_table_from_dataframe(df, table_id, job_config=job_config)
        job.result()
        logging.info(f"🚀 Dados carregados com sucesso em {table_id}")

        # Diagnóstico adicional
        table = client.get_table(table_id)
        logging.info(f"📈 Tabela contém {table.num_rows} linhas")
        logging.info(f"📋 Esquema da tabela: {[field.name for field in table.schema]}")

        return True

    except Exception:
        logging.exception("❌ Falha na extração ou carregamento")
        return False

@functions_framework.http
def hello_http(request):
    logging.info("🚨 Trigger HTTP recebido")
    ok = run_extraction()
    if not ok:
        return "⚠️ Erro ao extrair/carregar dados", 500
    return "✅ Dados carregados no BigQuery com sucesso!"
