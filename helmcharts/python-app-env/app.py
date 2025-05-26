from flask import Flask
import os

app = Flask(__name__)

@app.route("/")
def show_env_vars():
    chave1 = os.getenv("chave1", "Variável chave1 não definida")
    chave2 = os.getenv("chave2", "Variável chave2 não definida")
    
    return f"""
    <html lang="pt-BR">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <title>Variáveis de Ambiente</title>
        <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
        <link href="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/css/materialize.min.css" rel="stylesheet">
    </head>
    <body>
        <nav class="teal lighten-2 z-depth-1">
            <div class="nav-wrapper container">
                <a href="#" class="brand-logo center">
                    <i class="material-icons left">cloud</i>Variáveis de Ambiente
                </a>
                <ul id="nav-mobile" class="right hide-on-med-and-down">
                    <li><a href="#"><i class="material-icons left">info_outline</i>Sobre</a></li>
                </ul>
            </div>
        </nav>
        <main>
            <div class="container">
                <div class="row">
                    <div class="col s12 m8 offset-m2 l6 offset-l3">
                        <div class="card z-depth-3">
                            <div class="card-content">
                                <span class="card-title">
                                    <i class="material-icons teal-text text-lighten-1">settings</i>
                                    Detalhes das Variáveis
                                </span>
                                <p>Aqui estão as variáveis de ambiente configuradas:</p>
                                <div class="divider" style="margin: 15px 0;"></div>
                                <ul class="collection with-header">
                                    <li class="collection-header"><h5>Suas Variáveis</h5></li>
                                    <li class="collection-item">
                                        <div>
                                            <strong>chave1:</strong>
                                            <span class="secondary-content">{chave1}</span>
                                        </div>
                                    </li>
                                    <li class="collection-item">
                                        <div>
                                            <strong>chave2:</strong>
                                            <span class="secondary-content">{chave2}</span>
                                        </div>
                                    </li>
                                    <li class="collection-item">
                                        <div>
                                            <strong>outra_chave:</strong>
                                            <span class="secondary-content">valor_da_outra_chave</span>
                                        </div>
                                    </li>
                                </ul>
                            </div>
                            <div class="card-action center-align">
                                <a href="#" class="waves-effect waves-light btn teal lighten-1">
                                    <i class="material-icons left">refresh</i>Atualizar
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/js/materialize.min.js"></script>
        <script>
            // Inicialização de componentes Materialize, se necessário
            document.addEventListener('DOMContentLoaded', function() {
                // Nenhum componente específico precisa de inicialização para esta página simples
                // Mas se você adicionar dropdowns, modais, etc., eles seriam inicializados aqui.
            });
        </script>
    </body>
    </html>
    """

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
