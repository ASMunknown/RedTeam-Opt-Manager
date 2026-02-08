#!/bin/bash

# ==========================================
# SCRIPT DE INSTALACIÓN (EJECUCIÓN DIRECTA)
# ==========================================

# Argumentos recibidos del main.sh
REPO_URL=$1
VENV_NAME=$2
ALIAS_NAME=$3
SCRIPT_TARGET=$4  # <--- NUEVO ARGUMENTO OPCIONAL (Ej: psexec.py)

# Validar argumentos obligatorios
if [ -z "$REPO_URL" ] || [ -z "$VENV_NAME" ] || [ -z "$ALIAS_NAME" ]; then
    echo "[!] Error: Faltan argumentos obligatorios."
    echo "Uso: ./install_tool.sh <URL> <VENV_NAME> <ALIAS> [SCRIPT_TARGET]"
    exit 1
fi

# Configuración de rutas
TOOL_NAME=$(basename "$REPO_URL" .git)
TARGET_DIR="/opt/$TOOL_NAME"
USER_RC="/home/$SUDO_USER/.bashrc"
ROOT_RC="/root/.bashrc"

echo -e "\n[*] --- Instalando: $TOOL_NAME ---"

# 1. Clonado
if [ -d "$TARGET_DIR" ]; then
    echo "[!] Directorio existe. Saltando clonado."
else
    cd /opt
    git clone "$REPO_URL"
fi

# 2. Permisos (Usuario dueño)
chown -R $SUDO_USER:$SUDO_USER "$TARGET_DIR"

# 3. VENV e Instalación
echo "[*] Configurando entorno virtual..."
sudo -u $SUDO_USER bash -c "
    cd $TARGET_DIR
    python3 -m venv $VENV_NAME
    source $VENV_NAME/bin/activate
    pip install --upgrade pip
    
    if [ -f 'requirements.txt' ]; then
        pip install -r requirements.txt
    elif [ -f 'setup.py' ]; then
        pip install .
    fi
"

# 4. Construcción del Alias Inteligente
# Definimos la ruta completa al python del venv
VENV_PYTHON="$TARGET_DIR/$VENV_NAME/bin/python3"

if [ -n "$SCRIPT_TARGET" ]; then
    # CASO A: El usuario especificó un script (ej: secretsdump.py)
    # Buscamos dónde está ese script (en la raíz o en carpetas dentro como 'examples')
    SCRIPT_PATH=$(find "$TARGET_DIR" -name "$SCRIPT_TARGET" -type f | head -n 1)
    
    if [ -z "$SCRIPT_PATH" ]; then
        echo "[!] ADVERTENCIA: No se encontró el archivo '$SCRIPT_TARGET' en el repo."
        echo "    El alias apuntará solo al intérprete Python."
        COMMAND="$VENV_PYTHON"
    else
        # El comando será: /opt/venv/python /opt/repo/script.py
        COMMAND="$VENV_PYTHON $SCRIPT_PATH"
    fi
else
    # CASO B: No se especificó script, el alias será solo el intérprete
    # Uso: alias script.py
    COMMAND="$VENV_PYTHON"
fi

# 5. Función de inyección de alias
add_alias() {
    local rc_file=$1
    local user_role=$2
    
    if [ -f "$rc_file" ]; then
        # Eliminamos alias anterior si existe para evitar duplicados sucios
        sed -i "/alias $ALIAS_NAME=/d" "$rc_file"
        
        echo -e "\n# Alias para $TOOL_NAME" >> "$rc_file"
        # Aquí está la magia: un comando directo sin 'cd' ni 'activate'
        echo "alias $ALIAS_NAME='$COMMAND'" >> "$rc_file"
        echo "[+] Alias configurado en $user_role: $ALIAS_NAME -> $COMMAND"
    fi
}

echo -e "\n[*] Configurando alias en .bashrc..."
add_alias "$USER_RC" "Usuario"
add_alias "$ROOT_RC" "Root"

echo -e "\n[✔] Instalación completada."
