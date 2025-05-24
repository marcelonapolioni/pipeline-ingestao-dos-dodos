from flask import Flask
import subprocess

app = Flask(__name__)

@app.route("/", methods=["GET"])
def run_dbt():
    subprocess.run(["dbt", "deps", "--project-dir", "/app/dbt_project"], check=True)
    subprocess.run(["dbt", "run", "--project-dir", "/app/dbt_project"], check=True)
    return "DBT executed successfully", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
