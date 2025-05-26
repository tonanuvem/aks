from flask import Flask, render_template
import os

app = Flask(__name__)

@app.route("/")
def show_env_vars():
    env_vars = {
        "chave1": os.getenv("chave1", "Variável chave1 não definida"),
        "chave2": os.getenv("chave2", "Variável chave2 não definida"),
    }
    return render_template("index.html", env_vars=env_vars)

@app.route("/set_env_var", methods=["POST"])
def set_env_var():
    key = request.form.get("key")
    value = request.form.get("value")
    if key and value:
        os.environ[key] = value
    return redirect(url_for("show_env_vars"))
    
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
