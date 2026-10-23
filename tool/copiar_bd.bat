@echo off
rem Copia la base SQLite de la app desde el emulador a esta carpeta
rem (sabores_sucre.db) para abrirla en DBeaver.
rem Requisito: el emulador de Android encendido y la app instalada.

set ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
set DESTINO=%~dp0..\sabores_sucre.db

"%ADB%" exec-out run-as bo.edu.itsec.sabores_sucre cat databases/sabores.db > "%DESTINO%"
if errorlevel 1 (
  echo No se pudo copiar. Revisa que el emulador este encendido y la app instalada.
) else (
  echo Copiada en %DESTINO%
  echo En DBeaver presiona F5 sobre la conexion para ver los datos nuevos.
)
pause
