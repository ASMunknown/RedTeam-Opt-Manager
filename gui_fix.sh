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
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[!] Error: Este módulo requiere permisos de ROOT.${NC}"
   exit 1
fi

# Detectar usuario real (SUDO_USER) para rutas de /home
REAL_USER=$SUDO_USER
if [ -z "$REAL_USER" ]; then
    REAL_USER=$(whoami)
fi
REAL_UID=$(id -u $REAL_USER)

echo -e "${YELLOW}[*] Iniciando diagnóstico de interfaz gráfica (WSLg)...${NC}"

# =================================================================
# PASO 1: DETECCION INTELIGENTE DE PROCESOS GRÁFICOS
# =================================================================
SOCKET_X11="/tmp/.X11-unix/X0"
SOCKET_WAYLAND="/run/user/$REAL_UID/wayland-0"

echo -e "${BLUE}[1/4] Buscando procesos enganchados a X11/Wayland...${NC}"

# Usamos lsof para ver quién tiene abierto el socket gráfico
PIDS_TO_KILL=""

if [ -e "$SOCKET_X11" ]; then
    # Obtener PIDs de X11 ignorando errores
    XPIDS=$(lsof -t "$SOCKET_X11" 2>/dev/null)
    PIDS_TO_KILL="$PIDS_TO_KILL $XPIDS"
fi

if [ -e "$SOCKET_WAYLAND" ]; then
    # Obtener PIDs de Wayland
    WPIDS=$(lsof -t "$SOCKET_WAYLAND" 2>/dev/null)
    PIDS_TO_KILL="$PIDS_TO_KILL $WPIDS"
fi

# Limpiamos la lista de PIDs (quitar duplicados y espacios vacíos)
CLEAN_PIDS=$(echo "$PIDS_TO_KILL" | tr ' ' '\n' | sort -u | grep -v "^$")

if [ -n "$CLEAN_PIDS" ]; then
    echo -e "${RED}[!] Procesos gráficos detectados y terminados:${NC}"
    
    # Mostrar nombres para feedback visual
    for pid in $CLEAN_PIDS; do
        pname=$(ps -p $pid -o comm= 2>/dev/null)
        echo -e "    - $pname (PID: $pid)"
    done

    # Matar procesos
    echo "$CLEAN_PIDS" | xargs -r kill -9 2>/dev/null
else
    echo -e "${GREEN}[OK] No se encontraron procesos gráficos bloqueados.${NC}"
fi

# =================================================================
# PASO 2: LIMPIEZA DE AUDIO (PulseAudio suele congelar la UI)
# =================================================================
echo -e "${BLUE}[2/4] Reiniciando subsistema de audio...${NC}"
killall -9 pulseaudio 2>/dev/null
# Borrar locks antiguos de Pulse
rm -rf /home/$REAL_USER/.config/pulse/*.lock 2>/dev/null
rm -rf /tmp/pulse-* 2>/dev/null

# =================================================================
# PASO 3: REINICIO DE SERVICIOS DEL SISTEMA (DBus)
# =================================================================
echo -e "${BLUE}[3/4] Refrescando DBus y Sockets...${NC}"
# DBus gestiona la comunicación entre apps gráficas
service dbus restart

# Limpiar lock de X11 si quedó huérfano (importante para poder abrir apps de nuevo)
if [ -f "/tmp/.X11-unix/X0-lock" ]; then
    rm -f /tmp/.X11-unix/X0-lock
fi

# =================================================================
# PASO 4: LIMPIEZA DE CACHÉ GPU (Opcional, previene glitches)
# =================================================================
echo -e "${BLUE}[4/4] Limpiando caché de shaders...${NC}"
rm -rf /home/$REAL_USER/.cache/mesa_shader_cache 2>/dev/null

echo -e "\n${GREEN}[✔] Interfaz gráfica reiniciada exitosamente.${NC}"
echo -e "${YELLOW}[INFO] Ya puedes intentar abrir tu herramienta.${NC}"

# Si se ejecutó desde main.sh, este exit devuelve el control
exit 0
