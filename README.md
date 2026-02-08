# 🛡️ RedTeam Opt Manager

> **Automatiza la instalación, aislamiento y configuración de herramientas de Hacking en Linux.**

Un gestor de herramientas basado en Bash diseñado para Pentesters y Red Teamers. Este script automatiza el clonado de repositorios en `/opt`, crea entornos virtuales de Python (`venv`) aislados para cada herramienta y genera **alias inteligentes** tanto para tu usuario local como para `root`.

¡Olvídate de los conflictos de librerías y del "pip install" que rompe tu sistema!

## 🚀 Características

- **Centralización en `/opt`**: Mantiene tu sistema limpio instalando todo en el directorio estándar de aplicaciones opcionales.
- **Aislamiento Total**: Cada herramienta tiene su propio `python3 -m venv`. Las dependencias de *Impacket* no chocarán con las de *NetExec*.
- **Detección Inteligente**: Detecta automáticamente si la herramienta usa `requirements.txt`, `setup.py` o `pyproject.toml`.
- **Alias Híbridos**: Genera alias automáticamente en `.bashrc` tanto para tu usuario actual como para `root`.
- **Ejecución Contextual**: Los alias generados ejecutan la herramienta sin cambiar tu directorio actual (`cd`). ¡Perfecto para trabajar en `/tmp` o carpetas de evidencias!
- **LSOF es necesario si se quiere utilizar el modo de reparación de GUI en WSL2

## 📋 Requisitos

El script funciona en cualquier distribución basada en Debian/Ubuntu (Kali, Parrot, Ubuntu, etc.).

```bash
sudo apt update
sudo apt install git python3 python3-venv python3-pip lsof
