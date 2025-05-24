FROM python:3.11-slim

# Define o diretório de trabalho
WORKDIR /app

# Copia requirements e instala dependências (incluindo FF e dbt)
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir functions-framework dbt-core dbt-bigquery

# Copia o código do pipeline e o projeto dbt
COPY main.py ./main.py
COPY dbt/      ./dbt/

# Define a porta esperada pelo Cloud Run
ENV PORT=8080
EXPOSE 8080

# Entry‑point: Functions Framework carregando o módulo/função certa e escutando na porta
ENTRYPOINT ["functions-framework"]
CMD ["--target", "hello_http", "--source", "main.py", "--signature-type", "http", "--port", "8080"]
