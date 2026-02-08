#!/bin/bash

# =================================================================
# SCRIPT PRINCIPAL DE AUTOMATIZACIÓN - RED TEAM TOOLS
# =================================================================

# 1. Validación de privilegios de ROOT
if [[ $EUID -ne 0 ]]; then
   echo -e "\n[!] ERROR CRÍTICO: Este script debe ser ejecutado como ROOT."
   echo -e "    Uso: sudo ./main.sh\n"
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


# Función para mostrar el menú
show_menu() {
    echo -e "\n${BLUE}==========================================${NC}"
    echo -e "      ${YELLOW}AUTOMATIZACIÓN DE HERRAMIENTAS${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo -e "1) Instalar Nueva Herramienta (Git + Venv + Alias)"
    echo -e "2) Ver Alias Actuales en el Sistema"
    echo -e "3) Repara GUIs (WSL2)"
    echo -e "4) Salir"
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
            echo -e "${RED}Saliendo...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Opción no válida.${NC}"
            ;;
    esac
done
