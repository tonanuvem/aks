from flask import Flask, render_template
import os

app = Flask(__name__)

@app.route("/")
def show_env_vars():
    chave1 = os.getenv("chave1", "Variável chave1 não definida")
    chave2 = os.getenv("chave2", "Variável chave2 não definida")
    return render_template("index.html", chave1=chave1, chave2=chave2)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
