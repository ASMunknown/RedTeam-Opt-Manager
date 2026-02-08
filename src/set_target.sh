#!/bin/bash

# =================================================================
# WSL2 GUI UNFREEZE TOOL - Módulo Externo
# =================================================================

# Colores (Deben redefinirse aquí porque es un script independiente)
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Validación de Root (Necesario para reiniciar servicios y matar procesos ajenos)
#if [[ $EUID -ne 0 ]]; then
#   echo -e "${RED}[!] Error: Este módulo requiere permisos de ROOT.${NC}"
#   exit 1
#fi

# Solicitar datos al usuario
read -p "[+] Introduce la IP del objetivo: " TARGET_IP
read -p "[+] Introduce el Hostname del objetivo: " TARGET_NAME

# 1. Limpiar variables antiguas de /etc/environment para evitar duplicados
sed -i '/^IP=/d' /etc/environment
sed -i '/^TARGET=/d' /etc/environment

# 2. Añadir las nuevas variables
echo "IP=\"$TARGET_IP\"" >> /etc/environment
echo "TARGET=\"$TARGET_NAME\"" >> /etc/environment

# 3. (Opcional) Actualizar también /etc/hosts para resolución local
sed -i "/$TARGET_NAME/d" /etc/hosts
echo "$TARGET_IP    $TARGET_NAME" >> /etc/hosts

echo -e "${GREEN} [+] Configuración completada. "
echo -e "${YELLOW} [+] IP set to: $TARGET_IP"
echo -e "${YELLOW} [+] Hostname set to: $TARGET_NAME"
echo -e "\nIMPORTANTE: Para aplicar cambios en la terminal actual, ejecuta: source /etc/environment"

# Cargar los cambios para que el script actual los vea
source /etc/environment

# Si se ejecutó desde main.sh, este exit devuelve el control
return 0
