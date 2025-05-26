from flask import Flask, render_template, request
import os
import platform
import subprocess
import psutil
import sys
import time
import socket

app = Flask(__name__)

def get_system_info():

    info = {}

    # Sistema Operacional
    info["Sistema Operacional"] = platform.system()
    info["Versão do SO"] = platform.version()
    info["Kernel"] = platform.release()
    info["Plataforma"] = platform.platform()

    # CPU
    info["CPU"] = "Desconhecido"
    try:
        if os.path.exists("/proc/cpuinfo"):  # Linux
            with open("/proc/cpuinfo") as f:
                for line in f:
                    if "model name" in line:
                        info["CPU"] = line.split(":")[1].strip()
                        break
        else:  # Windows ou outro
            cpu_name = platform.processor()
            if not cpu_name:
                cpu_name = os.environ.get("PROCESSOR_IDENTIFIER", "Desconhecido")
            info["CPU"] = cpu_name
    except Exception as e:
        info["CPU"] = f"Erro ao obter CPU: {e}"

    info["Núcleos (lógicos)"] = os.cpu_count()

    # GPU info
    info["GPU"] = "Não detectada ou nvidia-smi ausente"
    try:
        # tenta rodar nvidia-smi --query-gpu=name --format=csv,noheader
        output = subprocess.check_output(
            ["nvidia-smi", "--query-gpu=name", "--format=csv,noheader"],
            stderr=subprocess.STDOUT
        ).decode().strip()
        if output:
            info["GPU"] = output
        else:
            info["GPU"] = "Nenhuma GPU detectada, mas sem nome"
    except Exception:
        info["GPU"] = " Não detectada GPU ou nvidia-smi ausente"

    # Memória
    mem = psutil.virtual_memory()
    info["Memória Total (GB)"] = round(mem.total / (1024**3), 2)

    # Python
    info["Python"] = sys.version.split()[0]

    # Host e IP
    try:
        hostname = socket.gethostname()
        ip_address = socket.gethostbyname(hostname)
    except:
        hostname = "Desconhecido"
        ip_address = "Desconhecido"
    info["Hostname"] = hostname
    info["IP"] = ip_address

    # Container detection
    info["Em Container"] = False
    try:
        if os.path.exists("C:\\.dockerenv"):
            info["Em Container"] = True
        elif os.path.exists("/.dockerenv"):
            info["Em Container"] = True
        elif os.path.exists("/proc/1/cgroup"):
            with open("/proc/1/cgroup") as f:
                if any("docker" in line or "kubepods" in line for line in f):
                    info["Em Container"] = True
    except Exception:
        pass

    # Uptime
    uptime_seconds = time.time() - psutil.boot_time()
    uptime_horas = round(uptime_seconds / 3600, 2)
    info["Uptime (h)"] = uptime_horas

    return info


@app.route("/")
def show_env_vars():
    env_vars = {
        "chave1": os.getenv("chave1", "Variável chave1 não definida"),
        "chave2": os.getenv("chave2", "Variável chave2 não definida"),
    }
    system_info = get_system_info()
    return render_template("index.html", env_vars=env_vars, system_info=system_info, mostrar_todas=False)

@app.route("/list_env_var")
def list_env_var():
    env_vars = dict(os.environ)
    system_info = get_system_info()
    return render_template("index.html", env_vars=env_vars, system_info=system_info, mostrar_todas=True)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
