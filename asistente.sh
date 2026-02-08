#!/bin/bash

# =================================================================
# SCRIPT PRINCIPAL DE AUTOMATIZACIÓN - RED TEAM TOOLS
# =================================================================

# 1. Validación de privilegios de ROOT
if [[ $EUID -ne 0 ]]; then
   echo -e "\n[!] ERROR CRÍTICO: Este script debe ser ejecutado como ROOT."
   echo -e "    Uso: sudo ./asistente.sh\n"
   exit 1
fi

# 2. Configuración de colores y estética
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificamos que el script instalador exista
INSTALLER_SCRIPT="./install_tool.sh"
if [ ! -f "$INSTALLER_SCRIPT" ]; then
    echo -e "${RED}[!] No se encuentra el archivo $INSTALLER_SCRIPT en este directorio.${NC}"
    exit 1
fi

GUI_FIX_SCRIPT="./gui_fix.sh"
if [ ! -f "$GUI_FIX_SCRIPT" ]; then
    echo -e "${RED}[!] No se encuentra el archivo $GUI_FIX_SCRIPT en este directorio.${NC}"
    exit 1
fi
# =================================================================
# FUNCIÓN DE AUTO-INSTALACIÓN (NUEVA)
# =================================================================
install_self() {
    echo -e "\n${YELLOW}[*] Iniciando auto-instalación del RedTeam Manager...${NC}"
    
    TARGET_DIR="/opt/RedTeam-Manager"
    ALIAS_NAME="asistente" # <--- Puedes cambiar esto por lo que quieras (ej: rtm)
    
    # 1. Crear directorio y copiar archivos
    echo -e "${CYAN}[1/3] Copiando archivos a $TARGET_DIR...${NC}"
    if [ -d "$TARGET_DIR" ]; then
        echo -e "${YELLOW}[!] El directorio ya existe. Actualizando archivos...${NC}"
    else
        mkdir -p "$TARGET_DIR"
    fi
    
    # Copiamos solo los scripts y el readme
    cp asistente.sh install_tool.sh gui_fix.sh README.md "$TARGET_DIR/"
    
    # 2. Asignar permisos ejecutables
    echo -e "${CYAN}[2/3] Ajustando permisos...${NC}"
    chmod +x "$TARGET_DIR"/*.sh
    
    # IMPORTANTE: Cambiamos el dueño a root, ya que es una herramienta de sistema
    chown -R root:root "$TARGET_DIR"
    
    # 3. Crear Alias Global
    echo -e "${CYAN}[3/3] Creando alias global '$ALIAS_NAME'...${NC}"
    
    # El alias debe invocar sudo automáticamente porque main.sh lo requiere
    ALIAS_CMD="alias $ALIAS_NAME='sudo $TARGET_DIR/$ALIAS_NAME.sh'"
    
    add_alias_safe() {
        local rc_file=$1
        if [ -f "$rc_file" ]; then
            # Borrar alias previo si existe para evitar duplicados
            sed -i "/alias $ALIAS_NAME=/d" "$rc_file"
            echo -e "\n# Alias para RedTeam Manager" >> "$rc_file"
            echo "$ALIAS_CMD" >> "$rc_file"
            echo -e "${GREEN}[+] Alias agregado a $rc_file${NC}"
        fi
    }
    
    add_alias_safe "/home/$SUDO_USER/.bashrc"
    add_alias_safe "/root/.bashrc"
    
    echo -e "\n${GREEN}[✔] ¡Instalación completada!${NC}"
    echo -e "${YELLOW}[INFO] Cierra esta terminal y abre una nueva.${NC}"
    echo -e "       Solo escribe: ${CYAN}$ALIAS_NAME${NC} para abrir este menú."
}

# Función para mostrar el menú
show_menu() {
    echo -e "\n${BLUE}==========================================${NC}"
    echo -e "      ${YELLOW}AUTOMATIZACIÓN DE HERRAMIENTAS${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo -e "1) Instalar Nueva Herramienta (Git + Venv + Alias)"
    echo -e "2) Ver Alias Actuales en el Sistema"
    echo -e "3) Repara GUIs (WSL2)"
    echo -e "4) Autoinstalación"
    echo -e "5) Salir"
    echo -e "${BLUE}------------------------------------------${NC}"
    echo -n "Selecciona una opción: "
}

# Lógica Principal
while true; do
    show_menu
    read -r opt
    case $opt in
        1)
            echo -e "\n${GREEN}[*] --- CONFIGURACIÓN DE NUEVA HERRAMIENTA ---${NC}"
            
            # Captura de datos
            read -p "1. URL del Repositorio Git: " repo_url
            read -p "2. Nombre para el VirtualEnv (ej: venv-impacket): " venv_name
            read -p "3. Nombre del Alias (comando final): " alias_name
            
            echo -e "${YELLOW}[INFO] Si dejas esto vacío, el alias abrirá solo Python.${NC}"
            read -p "4. Script principal a ejecutar (Opcional, ej: secretsdump.py): " script_target
            
            # Validación básica
            if [[ -z "$repo_url" || -z "$venv_name" || -z "$alias_name" ]]; then
                echo -e "${RED}[!] Error: Los campos 1, 2 y 3 son obligatorios.${NC}"
            else
                echo -e "\n${GREEN}[*] Ejecutando instalador...${NC}"
                
                # Llamada al script secundario pasando los 4 argumentos
                # Nota: Las comillas son vitales para manejar espacios o cadenas vacías
                bash "$INSTALLER_SCRIPT" "$repo_url" "$venv_name" "$alias_name" "$script_target"
                
                echo -e "\n${YELLOW}[IMPORTANTE] Ejecuta 'source ~/.bashrc' para usar el alias.${NC}"
            fi
            ;;
        2)
            echo -e "\n${BLUE}[*] Alias configurados en tu usuario ($SUDO_USER):${NC}"
            grep "^alias" "/home/$SUDO_USER/.bashrc" || echo "No se encontraron alias."
            
            echo -e "\n${BLUE}[*] Alias configurados en ROOT:${NC}"
            grep "^alias" "/root/.bashrc" || echo "No se encontraron alias."
            
            read -p "Presiona Enter para continuar..." temp
            ;;
            
         3)
            # Llamamos a la nueva función de reparación
            echo -e "${GREEN}Limpiando procesos...${NC}"
            bash "$GUI_FIX_SCRIPT"
            exit 0
            ;;
	4)
            # Llamada a la nueva función de auto-instalación
            install_self
            read -p "Presiona Enter..." temp
            ;;
            
        5)
            echo -e "${RED}Saliendo...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Opción no válida.${NC}"
            ;;
    esac
done
