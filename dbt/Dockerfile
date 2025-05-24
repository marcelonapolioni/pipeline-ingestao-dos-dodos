FROM python:3.11-slim

# Diretório de trabalho dentro do container
WORKDIR /app

# Instala dependências
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia o projeto DBT e o script de execução
COPY ./dbt /app/dbt_project
COPY run_dbt.py .
# Copia o profiles.yml e define a pasta esperada
RUN mkdir -p /root/.dbt
COPY profiles.yml /root/.dbt/profiles.yml

# Comando de entrada para rodar o servidor Flask (que executa o dbt)
CMD ["python", "run_dbt.py"]
