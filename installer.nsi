!define APPNAME "Aura Estándar"
!define COMPANYNAME "JP Labs"
!define DESCRIPTION "Punto de venta simple y personalizable"
!define VERSIONMAJOR 1
!define VERSIONMINOR 0
!define VERSIONBUILD 0

Name "${APPNAME}"
OutFile "AuraEstandar_Instalador.exe"
InstallDir "$PROGRAMFILES64\${APPNAME}"

# NSIS tomará el icono directamente de tu ejecutable compilado
!define MUI_ICON "windows\runner\resources\app_icon.ico"
!define MUI_UNICON "windows\runner\resources\app_icon.ico"

RequestExecutionLevel admin

!include "MUI2.nsh"

!define MUI_ABORTWARNING

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "Spanish"

Section "Install"
    SetOutPath "$INSTDIR"
    
    # Copia todo lo compilado por Flutter
    File /r "build\windows\x64\runner\Release\*.*"

    # Crea el acceso directo en el escritorio usando el icono del ejecutable
    CreateShortcut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\aura_estandar.exe" "" "$INSTDIR\aura_estandar.exe" 0
    
    # Crea el desinstalador
    WriteUninstaller "$INSTDIR\uninstall.exe"
    
    # Registro para "Agregar o quitar programas"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" "$INSTDIR\uninstall.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayIcon" "$INSTDIR\aura_estandar.exe"
SectionEnd

Section "Uninstall"
    Delete "$INSTDIR\*.*"
    RMDir /r "$INSTDIR"
    Delete "$DESKTOP\${APPNAME}.lnk"
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
SectionEnd
