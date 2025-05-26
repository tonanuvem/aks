from flask import Flask, render_template, request
import os

app = Flask(__name__)

@app.route("/")
def show_env_vars():
    env_vars = {
        "chave1": os.getenv("chave1", "Variável chave1 não definida"),
        "chave2": os.getenv("chave2", "Variável chave2 não definida"),
    }
    return render_template("index.html", env_vars=env_vars, mostrar_todas=False)

@app.route("/list_env_var")
def list_env_var():
    env_vars = dict(os.environ)
    return render_template("index.html", env_vars=env_vars, mostrar_todas=True)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
