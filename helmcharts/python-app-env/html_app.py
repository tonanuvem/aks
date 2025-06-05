from flask import Flask, render_template_string, request
import os
import platform
import subprocess
import psutil
import sys
import time
import socket

app = Flask(__name__)

# HTML template definido aqui, mas movido visualmente para baixo
TEMPLATE_HTML = '''...'''

def get_system_info():
    info = {
        "Sistema Operacional": platform.system(),
        "Versão do SO": platform.version(),
        "Kernel": platform.release(),
        "Plataforma": platform.platform(),
        "CPU": "Desconhecido",
        "Núcleos (lógicos)": os.cpu_count()
    }

    try:
        with open("/proc/cpuinfo") as f:
            for line in f:
                if "model name" in line:
                    info["CPU"] = line.split(":")[1].strip()
                    break
    except Exception as e:
        info["CPU"] = f"Erro ao obter CPU: {e}"

    try:
        output = subprocess.check_output(
            ["nvidia-smi", "--query-gpu=name", "--format=csv,noheader"],
            stderr=subprocess.STDOUT
        ).decode().strip()
        info["GPU"] = output or "Nenhuma GPU detectada"
    except Exception:
        info["GPU"] = "Não detectada GPU ou nvidia-smi ausente"

    mem = psutil.virtual_memory()
    info["Memória Total (GB)"] = round(mem.total / (1024**3), 2)
    info["Python"] = sys.version.split()[0]

    try:
        hostname = socket.gethostname()
        ip_address = socket.gethostbyname(hostname)
    except:
        hostname, ip_address = "Desconhecido", "Desconhecido"

    info["Hostname"] = hostname
    info["IP"] = ip_address

    info["Em Container"] = False
    try:
        if os.path.exists("/.dockerenv"):
            info["Em Container"] = True
        else:
            with open("/proc/1/cgroup") as f:
                if any("docker" in line or "kubepods" in line for line in f):
                    info["Em Container"] = True
    except Exception:
        pass

    uptime_seconds = time.time() - psutil.boot_time()
    info["Uptime (h)"] = round(uptime_seconds / 3600, 2)

    return info

@app.route("/")
def show_env_vars():
    env_vars = {
        "chave1": os.getenv("chave1", "Variável chave1 não definida"),
        "chave2": os.getenv("chave2", "Variável chave2 não definida"),
    }
    return render_template_string(TEMPLATE_HTML, env_vars=env_vars, system_info=get_system_info(), mostrar_todas=False)

@app.route("/list_env_var")
def list_env_var():
    return render_template_string(TEMPLATE_HTML, env_vars=dict(os.environ), system_info=get_system_info(), mostrar_todas=True)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

# ------------------------ HTML TEMPLATE NO FINAL ----------------------------

TEMPLATE_HTML = '''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <title>Variáveis de Ambiente</title>
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/css/materialize.min.css" rel="stylesheet">
    <style>
        table td, table th {
            word-break: break-word;
            max-width: 300px;
        }
    </style>
</head>
<body>
<nav class="teal lighten-2 z-depth-1">
    <div class="nav-wrapper container">
        <a href="#" class="brand-logo center">
            <i class="material-icons left">cloud</i>FIAP - Variáveis de Ambiente
        </a>
    </div>
</nav>

<main class="container" style="margin-top: 20px;">
    <div class="row">
        <div class="col s12 m10 offset-m1 l8 offset-l2">
            <div class="card z-depth-3">

                <div class="card-content">
                <span class="card-title"><i class="material-icons teal-text text-lighten-1">info</i> Detalhes do Ambiente</span>
                <table class="highlight responsive-table">
                    <thead>
                    <tr><th>Informação</th><th>Valor</th></tr>
                    </thead>
                    <tbody>
                    {% for key, value in system_info.items() %}
                    <tr><td>{{ key }}</td><td>{{ value }}</td></tr>
                    {% endfor %}
                    </tbody>
                </table>
                </div>

                <div class="card-content">
                    <span class="card-title">
                        <i class="material-icons teal-text text-lighten-1">settings</i> Detalhes das Variáveis
                    </span>
                    <p>Aqui estão as variáveis de ambiente configuradas:</p>
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

                <div class="card-content center-align">
                    {% if mostrar_todas %}
                        <a href="{{ url_for('show_env_vars') }}" class="waves-effect waves-light btn teal lighten-1">
                            <i class="material-icons left">arrow_back</i>Mostrar Apenas chave1 e chave2
                        </a>
                    {% else %}
                        <a href="{{ url_for('list_env_var') }}" class="waves-effect waves-light btn teal lighten-1">
                            <i class="material-icons left">list</i>Listar Todas as Variáveis
                        </a>
                    {% endif %}
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
