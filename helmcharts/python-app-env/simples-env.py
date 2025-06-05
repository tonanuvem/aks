from flask import Flask, render_template_string, request
import os

app = Flask(__name__)

# ========================= TEMPLATE HTML ==============================
TEMPLATE_HTML = '''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <title>Variáveis de Ambiente</title>
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/css/materialize.min.css" rel="stylesheet">
</head>
<body>
<main class="container" style="margin-top: 20px;">
    <div class="row">
        <div class="col s12 m10 offset-m1 l8 offset-l2">
            <div class="card z-depth-3">
                <div class="card-content">
                    <span class="card-title">
                        <i class="material-icons teal-text text-lighten-1">settings</i> Detalhes das Variáveis
                    </span>
                    <div class="divider" style="margin: 15px 0;"></div>

                    <table class="highlight responsive-table">
                        <thead>
                            <tr><th>Variável</th><th>Valor</th></tr>
                        </thead>
                        <tbody>
                            {% for key, value in env_vars.items() %}
                            <tr><td>{{ key }}</td><td>{{ value }}</td></tr>
                            {% endfor %}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</main>
<script src="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/js/materialize.min.js"></script>
<script>document.addEventListener('DOMContentLoaded', function() { M.updateTextFields(); });</script>
</body>
</html>
'''

# ========================= CODIGO PYTHON ==============================
@app.route("/")
def show_env_vars():
    env_vars = {
        "chave1": os.getenv("chave1", "Variável chave1 não definida"),
        "chave2": os.getenv("chave2", "Variável chave2 não definida"),
    }
    return render_template_string(TEMPLATE_HTML, env_vars=env_vars)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
