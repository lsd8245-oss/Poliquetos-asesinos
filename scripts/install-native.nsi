Unicode True
!include "MUI2.nsh"
!ifndef EDITION
 !define EDITION "Normal"
!endif
!ifndef GAME_EXE
 !error "Define GAME_EXE with the exported native game path"
!endif
!ifndef OUTFILE
 !error "Define OUTFILE with the installer path"
!endif
Name "Poliquetos Asesinos - ${EDITION}"
OutFile "${OUTFILE}"
InstallDir "$LOCALAPPDATA\Poliquetos Asesinos ${EDITION}"
RequestExecutionLevel user
SetCompressor /SOLID lzma
SetCompressorDictSize 16
ShowInstDetails show
!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\Poliquetos-${EDITION}.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Abrir Poliquetos Asesinos"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Spanish"
Section "Juego"
 SetOutPath "$INSTDIR"
 File /oname=Poliquetos-${EDITION}.exe "${GAME_EXE}"
 File /oname=LICENSE-Godot.txt "${__FILEDIR__}/../licenses/Godot-LICENSE.txt"
 File /oname=COPYRIGHT-Godot.txt "${__FILEDIR__}/../licenses/Godot-COPYRIGHT.txt"
 WriteUninstaller "$INSTDIR\Desinstalar.exe"
 CreateDirectory "$SMPROGRAMS\Poliquetos Asesinos"
 CreateShortCut "$SMPROGRAMS\Poliquetos Asesinos\${EDITION}.lnk" "$INSTDIR\Poliquetos-${EDITION}.exe"
 CreateShortCut "$DESKTOP\Poliquetos Asesinos - ${EDITION}.lnk" "$INSTDIR\Poliquetos-${EDITION}.exe"
 WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\PoliquetosAsesinos${EDITION}" "DisplayName" "Poliquetos Asesinos - ${EDITION}"
 WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\PoliquetosAsesinos${EDITION}" "UninstallString" '"$INSTDIR\Desinstalar.exe"'
SectionEnd
Section "Uninstall"
 Delete "$DESKTOP\Poliquetos Asesinos - ${EDITION}.lnk"
 Delete "$SMPROGRAMS\Poliquetos Asesinos\${EDITION}.lnk"
 RMDir "$SMPROGRAMS\Poliquetos Asesinos"
 Delete "$INSTDIR\Poliquetos-${EDITION}.exe"
 Delete "$INSTDIR\Desinstalar.exe"
 Delete "$INSTDIR\LICENSE-Godot.txt"
 Delete "$INSTDIR\COPYRIGHT-Godot.txt"
 RMDir "$INSTDIR"
 DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\PoliquetosAsesinos${EDITION}"
 ; Saved games in the user's data folder deliberately survive uninstall.
SectionEnd
