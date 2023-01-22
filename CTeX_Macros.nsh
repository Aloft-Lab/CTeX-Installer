!include "TextFunc.nsh"
!include "WordFunc.nsh"
!include "Sections.nsh"
!include "FileAssoc.nsh"
!include "UninstByLog.nsh"
!include "LogicLib_Ext.nsh"
!include "x64.nsh"

; Variables
Var Version
Var MiKTeX
Var Addons
Var Ghostscript
Var GSview
Var WinEdt
Var UN_INSTDIR
Var UN_Version
Var UN_MiKTeX
Var UN_Addons
Var UN_Ghostscript
Var UN_GSview
Var UN_WinEdt
Var SMCTEX
Var MiKTeX_BIN
Var MiKTeX_Setup
Var Ghostscript_DLL

!macro _ExeCmdQ Command Options
	DetailPrint 'Executing: ${Command} ${Options}'
	nsExec::ExecToLog '"${Command}" ${Options}'
!macroend
!define ExeCmdQ '!insertmacro _ExeCmdQ'

Var ExitCode
!macro _ExeCmd Command Options
	${ExeCmdQ} '${Command}' '${Options}'
	Pop $ExitCode
	${If} $ExitCode != "0"
		SetDetailsView show
		MessageBox MB_OK|MB_ICONEXCLAMATION '$(Msg_ExeCmdError) (Exitcode: $ExitCode)$\n"${Command}" ${Options}'
	${EndIf}
!macroend
!define ExeCmd '!insertmacro _ExeCmd'

!macro _CreateURLShortCut URLFile URLSite
	WriteINIStr "${URLFile}.URL" "InternetShortcut" "URL" "${URLSite}"
!macroend
!define CreateURLShortCut "!insertmacro _CreateURLShortCut"

!macro _AppendPath DIR
	${If} ${UserIsAdmin}
		EnVar::SetHKLM
	${Else}
		EnVar::SetHKCU
	${EndIf}
	EnVar::DeleteValue "PATH" "${DIR}"
	EnVar::AddValueEx "PATH" "${DIR}"
!macroend
!define AppendPath "!insertmacro _AppendPath"

!macro _AddEnvVar NAME VALUE
	${If} ${UserIsAdmin}
		EnVar::SetHKLM
	${Else}
		EnVar::SetHKCU
	${EndIf}
	EnVar::Delete "${NAME}"
	EnVar::AddValueEx "${NAME}" "${VALUE}"
!macroend
!define AddEnvVar "!insertmacro _AddEnvVar"

!macro _RemovePath UN DIR
	${If} ${UserIsAdmin}
		EnVar::SetHKLM
		EnVar::DeleteValue "PATH" "${DIR}"
	${EndIf}
	EnVar::SetHKCU
	EnVar::DeleteValue "PATH" "${DIR}"
!macroend
!define RemovePath '!insertmacro _RemovePath ""'
!define un.RemovePath '!insertmacro _RemovePath "un."'

!macro _RemoveEnvVar NAME
	${If} ${UserIsAdmin}
		EnVar::SetHKLM
		EnVar::Delete "${NAME}"
	${EndIf}
	EnVar::SetHKCU
	EnVar::Delete "${NAME}"
!macroend
!define RemoveEnvVar "!insertmacro _RemoveEnvVar"

${Using:StrFunc} StrTok
${Using:StrFunc} UnStrTok
!define un.StrTok '${UnStrTok}'
!macro Define_Func_RemoveToken UN
Function ${UN}RemoveToken
	StrCpy $R9 ""
	StrCpy $R8 0
	${Do}
		${${UN}StrTok} $R7 $R0 $R2 $R8 "1"
		${If} $R7 == ""
			${ExitDo}
		${EndIf}
		${Do}
			StrCpy $R6 $R7 1
			${If} $R6 != " "
				${ExitDo}
			${EndIf}
			StrCpy $R7 $R7 "" 1                ;  Remove leading space
		${Loop}
		${Do}
			StrCpy $R6 $R7 1 -1
			${If} $R6 != " "
				${ExitDo}
			${EndIf}
			StrCpy $R7 $R7 -1                  ;  Remove trailing space
     ${Loop}
		${If} $R7 != $R1                     ;  Remove existing target
		${AndIf} $R7 != ""
			${If} $R9 != ""
				StrCpy $R9 "$R9;$R7"
			${Else}
				StrCpy $R9 "$R7"
			${EndIf}
		${EndIf}
		IntOp $R8 $R8 + 1
	${Loop}
FunctionEnd
!macroend
!insertmacro Define_Func_RemoveToken ""
!insertmacro Define_Func_RemoveToken "un."

!macro _Remove_MiKTeX_Roots
	RMDir /r "$APPDATA\MiKTeX"
	RMDir /r "$LOCALAPPDATA\MiKTeX"
	SetShellVarContext all
	RMDir /r "$APPDATA\MiKTeX"
	SetShellVarContext current
	RMDir /r "$INSTDIR\${UserData_Dir}"
!macroend

!macro Install_Config_MiKTeX
	${If} $MiKTeX != ""
		DetailPrint "Install MiKTeX configs"

		!insertmacro _Remove_MiKTeX_Roots

		StrCpy $0 "$INSTDIR\${MiKTeX_Dir}"
		StrCpy $1 "$0\miktex\$MiKTeX_BIN"

		StrCpy $9 "Software\MiKTeX.org\MiKTeX\$MiKTeX"
		WriteRegStr HKLM "$9\Core" "SharedSetup" "1"
		WriteRegStr HKLM "$9\Core" "CommonInstall" "$0"
		WriteRegStr HKLM "$9\Core" "CommonData" "$INSTDIR\${UserData_Dir}"
		WriteRegStr HKLM "$9\Core" "CommonConfig" "$INSTDIR\${UserData_Dir}"
		WriteRegStr HKLM "$9\Core" "UserInstall" "$INSTDIR\${UserData_Dir}"
		WriteRegStr HKLM "$9\Core" "UserData" "$INSTDIR\${UserData_Dir}"
		WriteRegStr HKLM "$9\Core" "UserConfig" "$INSTDIR\${UserData_Dir}"
		WriteRegStr HKLM "$9\MPM" "AutoInstall" "1"
		WriteRegStr HKLM "$9\MPM" "AutoAdmin" "1"
		WriteRegStr HKLM "$9\MPM" "LastAdminUpdateCheck" "1660000000"
		WriteRegStr HKLM "$9\Setup" "Version" "$MiKTeX_Setup"

		${AppendPath} "$INSTDIR\${UserData_Dir}\miktex\bin"
		${AppendPath} "$1"

; ShortCuts
		StrCpy $9 "$SMCTEX"
		CreateDirectory "$9"
		CreateShortCut "$9\MiKTeX Console.lnk" "$1\miktex-console.exe"
		CreateShortCut "$9\TeXworks.lnk" "$1\miktex-texworks.exe"

		DetailPrint "Update MiKTeX settings"
		${ExeCmd} "$1\mpm.exe" "--register-components --admin --verbose"
		${ExeCmd} "$1\miktex.exe" "--admin --disable-installer --verbose fndb refresh"
		${ExeCmd} "$1\miktex.exe" "--admin --disable-installer --verbose links install --force"
		${ExeCmd} "$1\miktex.exe" "--admin --disable-installer --verbose fontmaps configure"
		${ExeCmd} "$1\miktex.exe" "--admin --disable-installer --verbose languages configure"
		${ExeCmd} "$1\miktex.exe" "--admin --disable-installer --verbose fndb refresh"
		${ExeCmd} "$1\miktex.exe" "--admin --disable-installer --verbose filetypes register"
		${ExeCmd} "$1\initexmf.exe" "--default-paper-size=A4 --admin --disable-installer --verbose"
		${ExeCmd} "$1\yap.exe" "--register"
	${EndIf}
!macroend

!macro Uninstall_Config_MiKTeX UN
	${If} $UN_MiKTeX != ""
		DetailPrint "Uninstall MiKTeX configs"

		${ExeCmd} "$UN_INSTDIR\${MiKTeX_Dir}\miktex\$MiKTeX_BIN\mpm.exe" "--unregister-components --admin --verbose"

		DeleteRegKey HKLM "Software\MiKTeX.org"
		DeleteRegKey HKCU "Software\MiKTeX.org"

		${${UN}RemovePath} "$UN_INSTDIR\${MiKTeX_Dir}\miktex\$MiKTeX_BIN"
		${${UN}RemovePath} "$UN_INSTDIR\${UserData_Dir}\miktex\bin"
		${${UN}RemovePath} "$APPDATA\MiKTeX\$UN_MiKTeX\miktex\bin"

		!insertmacro _Remove_MiKTeX_Roots
	${EndIf}
!macroend

!macro Install_Config_Addons
	${If} $Addons != ""
		DetailPrint "Install CTeX Addons configs"

		StrCpy $0 "$INSTDIR\${Addons_Dir}"

		StrCpy $9 "Software\MiKTeX.org\MiKTeX\$MiKTeX\Core"
		ReadRegStr $R0 HKLM "$9" "CommonRoots"
		${If} $R0 == ""
			WriteRegStr HKLM "$9" "CommonRoots" "$0"
		${Else}
			StrCpy $R1 "$0"
			StrCpy $R2 ";"
			Call RemoveToken
			WriteRegStr HKLM "$9" "CommonRoots" "$0;$R9"
		${EndIf}

		${AppendPath} "$0\ctex\bin"

; Install CCT
		${AppendPath} "$0\cct\bin"
		${AddEnvVar} "CCHZPATH" "$0\cct\fonts"
		${AddEnvVar} "CCPKPATH" "$0\fonts\pk\modeless\cct\dpi$$d"
	
		FileOpen $R0 "$0\cct\bin\cctinit.ini" "w"
		FileWrite $R0 "-T$0\fonts\tfm\cct$\n"
		FileWrite $R0 "-H$0\tex\latex\cct$\n"
		FileClose $R0
	
		${ExeCmd} "$0\cct\bin\cctinit.exe" ""

; Install TY
		${AppendPath} "$0\ty\bin"

		FileOpen $R0 "$0\ty\bin\tywin.cfg" "w"
		FileWrite $R0 "$0\fonts\tfm\ty\$\r$\n"
		FileWrite $R0 "$0\fonts\pk\modeless\ty\DPI@Rr\$\r$\n"
		FileWrite $R0 ".\$\r$\n"
		FileWrite $R0 "$0\ty\bin\$\r$\n"
		FileWrite $R0 "$FONTS\$\r$\n"
		FileWrite $R0 "600$\r$\n1095$\r$\n"
		FileWrite $R0 "simsun.ttc$\r$\nsimkai.ttf$\r$\nsimfang.ttf$\r$\nsimhei.ttf$\r$\nsimsun.ttc$\r$\nsimsun.ttc$\r$\nsimsun.ttc$\r$\nsimsun.ttc$\r$\n"
		FileWrite $R0 "simsun.ttc$\r$\nsimyou.ttf$\r$\nsimsun.ttc$\r$\nsimsun.ttc$\r$\nsimsun.ttc$\r$\nsimli.ttf$\r$\nsimsun.ttc$\r$\nsimsun.ttc$\r$\n"
		FileWrite $R0 "0$\r$\n0$\r$\n$\r$\n$\r$\n$\r$\n$\r$\n$\r$\n$\r$\n$\r$\n$\r$\n$\r$\n$\r$\n$\r$\n$\r$\n$\r$\n$\r$\n$\r$\n$\r$\n$\r$\n$\r$\n0$\r$\n0$\r$\n0$\r$\n0$\r$\n0$\r$\n"
		FileClose $R0
	${EndIf}
!macroend

!macro Uninstall_Config_Addons UN
	${If} $UN_Addons != ""
		DetailPrint "Uninstall CTeX Addons configs"

		StrCpy $0 "$UN_INSTDIR\${Addons_Dir}"
	
		StrCpy $9 "Software\MiKTeX.org\MiKTeX\$UN_MiKTeX\Core"
		ReadRegStr $R0 HKLM "$9" "Roots"
		${If} $R0 != ""
			StrCpy $R1 "$0"
			StrCpy $R2 ";"
			Call ${UN}RemoveToken
			WriteRegStr HKLM "$9" "Roots" "$R9"
		${EndIf}

		${${UN}RemovePath} "$0\ctex\bin"

; Uninstall CCT
		${${UN}RemovePath} "$0\cct\bin"
		${RemoveEnvVar} "CCHZPATH"
		${RemoveEnvVar} "CCPKPATH"

; Uninstall TY
		${${UN}RemovePath} "$0\ty\bin"
	${EndIf}
!macroend

!macro Install_Config_Ghostscript
	${If} $Ghostscript != ""
		DetailPrint "Install Ghostscript configs"

		StrCpy $0 "$INSTDIR\${Ghostscript_Dir}\gs$Ghostscript"
		WriteRegStr HKLM "Software\Artifex\GPL Ghostscript\$Ghostscript" "" "$0"
		
		StrCpy $9 "Software\GPL Ghostscript\$Ghostscript"
		WriteRegStr HKLM "$9" "GS_DLL" "$0\bin\$Ghostscript_DLL"
		WriteRegStr HKLM "$9" "GS_LIB" "$0\bin;$0\lib;$0\fonts;$FONTS"
	
		${AppendPath} "$0\bin"
	${EndIf}
!macroend

!macro Uninstall_Config_Ghostscript UN
	${If} $UN_Ghostscript != ""
		DetailPrint "Uninstall Ghostscript configs"

		DeleteRegKey HKLM "Software\Artifex\GPL Ghostscript"
		EnumRegKey $0 HKLM "Software\Artifex" "0"
		${If} $0 == ""
			DeleteRegKey HKLM "Software\Artifex"
		${EndIf}
		DeleteRegKey HKLM "Software\GPL Ghostscript"
	
		${${UN}RemovePath} "$UN_INSTDIR\${Ghostscript_Dir}\gs$UN_Ghostscript\bin"
	${EndIf}
!macroend

!macro Install_Config_GSview
	${If} $GSview != ""
		DetailPrint "Install GSview configs"

		StrCpy $0 "$INSTDIR\${GSview_Dir}\gsview$GSview"
		WriteRegStr HKLM "Software\Artifex Software\gsview\$GSview" "" "$0"
			
		StrCpy $9 "$0\bin\gsview.exe"
		!insertmacro APP_ASSOCIATE "ps" "CTeX.PS" "PS $(Desc_File)" "$0\resources\pagePS.ico" "Open with GSview" '$9 "%1"'
		!insertmacro APP_ASSOCIATE "eps" "CTeX.EPS" "EPS $(Desc_File)" "$0\resources\pageEPS.ico" "Open with GSview" '$9 "%1"'
	${EndIf}
!macroend

!macro Uninstall_Config_GSview UN
	${If} $UN_GSview != ""
		DetailPrint "Uninstall GSview configs"

		DeleteRegKey HKLM "Software\Artifex Software\gsview"
		EnumRegKey $0 HKLM "Software\Artifex Software" "0"
		${If} $0 == ""
			DeleteRegKey HKLM "Software\Artifex Software"
		${EndIf}
	
		${${UN}RemovePath} "$UN_INSTDIR\${GSview_Dir}\gsview"
	
		!insertmacro APP_UNASSOCIATE "ps" "CTeX.PS"
		!insertmacro APP_UNASSOCIATE "eps" "CTeX.EPS"
	${EndIf}
!macroend

!macro Install_Config_WinEdt
	${If} $WinEdt != ""
		DetailPrint "Install WinEdt configs"

		RMDir /r "$APPDATA\WinEdt"

		StrCpy $0 "$INSTDIR\${WinEdt_Dir}"
		WriteRegStr HKLM32 "Software\WinEdt" "Install Root" "$0"
		WriteRegStr HKLM32 "Software\WinEdt" "AppData" "$0\Local"
		WriteRegStr HKCU32 "Software\VB and VBA Program Settings\TexFriend\Options" "StartupByWinEdt" "False"

		${AppendPath} "$0"
	
		StrCpy $9 "$0\WinEdt.exe"
		!insertmacro APP_ASSOCIATE "tex" "CTeX.TeX" "TeX $(Desc_File)" "$9,0" "Open with WinEdt" '$9 "%1"'
	
; ShortCuts
		StrCpy $9 "$SMCTEX"
		CreateDirectory "$9"
		CreateShortCut "$9\WinEdt.lnk" "$INSTDIR\${WinEdt_Dir}\WinEdt.exe"

		${If} $MiKTeX != ""
			WriteRegStr HKCU "Software\MiKTeX.org\MiKTeX\$MiKTeX\Yap\Settings" "Editor" '$INSTDIR\${WinEdt_Dir}\winedt.exe "[Open(|%f|);SelPar(%l,8)]"'
			CreateDirectory "$INSTDIR\${UserData_Dir}\miktex\config"
			WriteINIStr "$INSTDIR\${UserData_Dir}\miktex\config\yap.ini" "Settings" "Editor" '$INSTDIR\${WinEdt_Dir}\winedt.exe "[Open(|%f|);SelPar(%l,8)]"'
		${EndIf}
	${EndIf}
!macroend

!macro Uninstall_Config_WinEdt UN
	${If} $UN_WinEdt != ""
		DetailPrint "Uninstall WinEdt configs"

		DeleteRegKey HKLM32 "Software\WinEdt"
		DeleteRegKey HKCU32 "Software\VB and VBA Program Settings\TexFriend"
	
		${${UN}RemovePath} "$UN_INSTDIR\${WinEdt_Dir}"

		!insertmacro APP_UNASSOCIATE "tex" "CTeX.TeX"

		RMDir /r "$APPDATA\WinEdt"

		Delete "$SMCTEX\WinEdt.lnk"
	${EndIf}
!macroend

!macro Install_Config_CTeX
	DetailPrint "Install general configs"

	!insertmacro Save_Install_Information

	StrCpy $9 "Software\${APP_NAME}"
	WriteRegStr HKLM "$9" "" "${APP_NAME} ${APP_VERSION}"
	WriteRegStr HKLM "$9" "Install" "$INSTDIR"
	WriteRegStr HKLM "$9" "Version" "$Version"
	WriteRegStr HKLM "$9" "MiKTeX" "$MiKTeX"
	WriteRegStr HKLM "$9" "Addons" "$Addons"
	WriteRegStr HKLM "$9" "Ghostscript" "$Ghostscript"
	WriteRegStr HKLM "$9" "GSview" "$GSview"
	WriteRegStr HKLM "$9" "WinEdt" "$WinEdt"

	StrCpy $9 "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"
	WriteRegStr HKLM "$9" "DisplayName" "${APP_NAME}"
	WriteRegStr HKLM "$9" "DisplayVersion" "$Version"
	WriteRegStr HKLM "$9" "DisplayIcon" "$INSTDIR\Uninstall.exe,0"
	WriteRegStr HKLM "$9" "Publisher" "${APP_COMPANY}"
	WriteRegStr HKLM "$9" "Readme" "$INSTDIR\Readme.txt"
	WriteRegStr HKLM "$9" "HelpLink" "https://github.com/Aloft-Lab/CTeX-Installer/issues"
	WriteRegStr HKLM "$9" "URLInfoAbout" "http://www.ctex.org"
	WriteRegStr HKLM "$9" "UninstallString" "$INSTDIR\Uninstall.exe"

	StrCpy $9 "$INSTDIR\${MiKTeX_Dir}\miktex\$MiKTeX_BIN"
	DetailPrint "Update MiKTeX file name database"
	${ExeCmd} "$9\miktex.exe" "--admin --disable-installer --verbose fndb refresh"
	${ExeCmd} "$9\miktex.exe" "--disable-installer --verbose fndb refresh"
	DetailPrint "Update MiKTeX updmap database"
	${ExeCmd} "$9\miktex.exe" "--admin --disable-installer --verbose fontmaps configure"

	!insertmacro UPDATEFILEASSOC
!macroend

!macro Uninstall_Config_CTeX UN
	DetailPrint "Uninstall general configs"

	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"
	DeleteRegKey HKLM "Software\${APP_NAME}"

	Delete "$UN_INSTDIR\${Logs_Dir}\install.ini"

	RMDir /r "$SMCTEX"

	!insertmacro UPDATEFILEASSOC
!macroend

!macro _Install_Files LogMode Files LogFile
	CreateDirectory "$INSTDIR\${Logs_Dir}"
	LogSet on
	File /r "${Files}"
	LogSet off
	!insertmacro Save_Compressed_Log "${LogMode}" "$INSTDIR\${Logs_Dir}\${LogFile}"
!macroend
!define Install_Files '!insertmacro _Install_Files ""'
!define Install_Files_A '!insertmacro _Install_Files "A"'

!macro _Begin_Install_Files
	CreateDirectory "$INSTDIR\${Logs_Dir}"
	LogSet on
!macroend
!define Begin_Install_Files "!insertmacro _Begin_Install_Files"

!macro _End_Install_Files LogMode LogFile
	LogSet off
	!insertmacro Save_Compressed_Log "${LogMode}" "$INSTDIR\${Logs_Dir}\${LogFile}"
!macroend
!define End_Install_Files '!insertmacro _End_Install_Files ""'
!define End_Install_Files_A '!insertmacro _End_Install_Files "A"'

!macro Uninstall_All_Configs UN
	${If} $UN_INSTDIR != ""
		!insertmacro Uninstall_Config_CTeX "${UN}"
		!insertmacro Uninstall_Config_WinEdt "${UN}"
		!insertmacro Uninstall_Config_GSview "${UN}"
		!insertmacro Uninstall_Config_Ghostscript "${UN}"
		!insertmacro Uninstall_Config_Addons "${UN}"
		!insertmacro Uninstall_Config_MiKTeX "${UN}"
	${EndIf}
!macroend

!macro Uninstall_All_Files UN
	${If} $UN_INSTDIR != ""
		DetailPrint "Uninstall old files"
		${${UN}Uninstall_Files} "$UN_INSTDIR\${Logs_Dir}\install.log"
		${${UN}Uninstall_Files} "$UN_INSTDIR\${Logs_Dir}\install_winedt.log"
		${${UN}Uninstall_Files} "$UN_INSTDIR\${Logs_Dir}\install_gsview.log"
		${${UN}Uninstall_Files} "$UN_INSTDIR\${Logs_Dir}\install_ghostscript.log"
		${${UN}Uninstall_Files} "$UN_INSTDIR\${Logs_Dir}\install_addons.log"
		${${UN}Uninstall_Files} "$UN_INSTDIR\${Logs_Dir}\install_miktex.log"
		RMDir "$UN_INSTDIR\${Logs_Dir}"
		RMDir "$UN_INSTDIR\${WinEdt_Dir}"
		RMDir "$UN_INSTDIR\${GSview_Dir}"
		RMDir "$UN_INSTDIR\${Ghostscript_Dir}"
		RMDir "$UN_INSTDIR\${Addons_Dir}"
		RMDir "$UN_INSTDIR\${MiKTeX_Dir}"
	${EndIf}
!macroend

!macro Save_Install_Information
	StrCpy $9 "$INSTDIR\${Logs_Dir}\install.ini"
	WriteINIStr "$9" "CTeX" "Install" "$INSTDIR"
	WriteINIStr "$9" "CTeX" "Version" "$Version"
	WriteINIStr "$9" "CTeX" "MiKTeX" "$MiKTeX"
	WriteINIStr "$9" "CTeX" "Addons" "$Addons"
	WriteINIStr "$9" "CTeX" "Ghostscript" "$Ghostscript"
	WriteINIStr "$9" "CTeX" "GSview" "$GSview"
	WriteINIStr "$9" "CTeX" "WinEdt" "$WinEdt"
!macroend

!macro Restore_Install_Information
	StrCpy $9 "$INSTDIR\${Logs_Dir}\install.ini"
	${If} ${FileExists} "$9"
		ReadINIStr $Version "$9" "CTeX" "Version"
		ReadINIStr $MiKTeX "$9" "CTeX" "MiKTeX"
		ReadINIStr $Addons "$9" "CTeX" "Addons"
		ReadINIStr $Ghostscript "$9" "CTeX" "Ghostscript"
		ReadINIStr $GSview "$9" "CTeX" "GSview"
		ReadINIStr $WinEdt "$9" "CTeX" "WinEdt"
	${Else}
		StrCpy $Version ${APP_BUILD}
		StrCpy $MiKTeX ${MiKTeX_Version}
		StrCpy $Addons ${MiKTeX_Version}
		StrCpy $Ghostscript ${Ghostscript_Version}
		StrCpy $GSview ${GSview_Version}
		StrCpy $WinEdt ${WinEdt_Version}
	${EndIf}
!macroend

!macro Set_All_Sections_Selection
	${If} $MiKTeX != ""
		!insertmacro Section_Select_X64 ${Section_MiKTeX} ${Section_MiKTeX_x64} ${Section_MiKTeX_x86}
	${EndIf}
	${If} $Addons != ""
		!insertmacro Section_Select_X64 ${Section_Addons} ${Section_Addons_x64} ${Section_Addons_x86}
	${EndIf}
	${If} $Ghostscript != ""
		!insertmacro Section_Select_X64 ${Section_Ghostscript} ${Section_Ghostscript_x64} ${Section_Ghostscript_x86}
	${EndIf}
	${If} $GSview != ""
		!insertmacro Section_Select_X64 ${Section_GSview} ${Section_GSview_x64} ${Section_GSview_x86}
	${EndIf}
	${If} $WinEdt != ""
		!insertmacro Section_Select_X64 ${Section_WinEdt} ${Section_WinEdt_x64} ${Section_WinEdt_x86}
	${EndIf}
!macroend

!macro Set_All_Sections_ReadOnly
	!insertmacro SetSectionFlag ${Section_MiKTeX} ${SF_RO}
	!insertmacro SetSectionFlag ${Section_MiKTeX_x64} ${SF_RO}
	!insertmacro SetSectionFlag ${Section_MiKTeX_x86} ${SF_RO}
	!insertmacro SetSectionFlag ${Section_Addons} ${SF_RO}
	!insertmacro SetSectionFlag ${Section_Addons_x64} ${SF_RO}
	!insertmacro SetSectionFlag ${Section_Addons_x86} ${SF_RO}
	!insertmacro SetSectionFlag ${Section_Ghostscript} ${SF_RO}
	!insertmacro SetSectionFlag ${Section_Ghostscript_x64} ${SF_RO}
	!insertmacro SetSectionFlag ${Section_Ghostscript_x86} ${SF_RO}
	!insertmacro SetSectionFlag ${Section_GSview} ${SF_RO}
	!insertmacro SetSectionFlag ${Section_GSview_x64} ${SF_RO}
	!insertmacro SetSectionFlag ${Section_GSview_x86} ${SF_RO}
	!insertmacro SetSectionFlag ${Section_WinEdt} ${SF_RO}
	!insertmacro SetSectionFlag ${Section_WinEdt_x64} ${SF_RO}
	!insertmacro SetSectionFlag ${Section_WinEdt_x86} ${SF_RO}
!macroend

!macro Update_Install_Information
	StrCpy $Version ${APP_BUILD}
	${If} ${SectionIsSelected} ${Section_MiKTeX}
		StrCpy $MiKTeX ${MiKTeX_Version}
	${EndIf}
	${If} ${SectionIsSelected} ${Section_Addons}
		StrCpy $Addons ${MiKTeX_Version}
	${EndIf}
	${If} ${SectionIsSelected} ${Section_Ghostscript}
		StrCpy $Ghostscript ${Ghostscript_Version}
	${EndIf}
	${If} ${SectionIsSelected} ${Section_GSview}
		StrCpy $GSview ${GSview_Version}
	${EndIf}
	${If} ${SectionIsSelected} ${Section_WinEdt}
		StrCpy $WinEdt ${WinEdt_Version}
	${EndIf}
!macroend

!macro Get_Uninstall_Information
	ReadRegStr $UN_INSTDIR HKLM "Software\${APP_NAME}" "Install"
	ReadRegStr $UN_Version HKLM "Software\${APP_NAME}" "Version"
	ReadRegStr $UN_MiKTeX HKLM "Software\${APP_NAME}" "MiKTeX"
	ReadRegStr $UN_Addons HKLM "Software\${APP_NAME}" "Addons"
	ReadRegStr $UN_Ghostscript HKLM "Software\${APP_NAME}" "Ghostscript"
	ReadRegStr $UN_GSview HKLM "Software\${APP_NAME}" "GSview"
	ReadRegStr $UN_WinEdt HKLM "Software\${APP_NAME}" "WinEdt"
!macroend

!macro Update_Uninstall_Information
	${If} $UN_INSTDIR != ""
		StrCpy $INSTDIR $UN_INSTDIR
	${Else}
		StrCpy $UN_INSTDIR $INSTDIR
		StrCpy $UN_MiKTeX ${MiKTeX_Version}
		StrCpy $UN_Addons ${MiKTeX_Version}
		StrCpy $UN_Ghostscript ${Ghostscript_Version}
		StrCpy $UN_GSview ${GSview_Version}
		StrCpy $UN_WinEdt ${WinEdt_Version}
	${EndIf}
!macroend

Function Update_Log_Line
	${WordReplace} '$R9' '$R0' '$R1' '+*' $R9
	Push $0
FunctionEnd

!macro Update_Log LogFile
	${If} ${FileExists} ${LogFile}
		ReadINIStr $R0 "$INSTDIR\${Logs_Dir}\install.ini" "CTeX" "Install"
		${If} $R0 != ""
		${AndIf} $R0 != "$INSTDIR"
			DetailPrint "Update install log: ${LogFile}"
			StrCpy $R1 "$INSTDIR"
			${LineFind} "${LogFile}" "" "1:-1" "Update_Log_Line"
		${EndIf}
	${EndIf}
!macroend

!macro Update_All_Logs
	!insertmacro Update_Log "$INSTDIR\${Logs_Dir}\install.log"
	!insertmacro Update_Log "$INSTDIR\${Logs_Dir}\install_winedt.log"
	!insertmacro Update_Log "$INSTDIR\${Logs_Dir}\install_gsview.log"
	!insertmacro Update_Log "$INSTDIR\${Logs_Dir}\install_ghostscript.log"
	!insertmacro Update_Log "$INSTDIR\${Logs_Dir}\install_addons.log"
	!insertmacro Update_Log "$INSTDIR\${Logs_Dir}\install_miktex.log"
!macroend

!macro Save_Compressed_Log LogMode LogFile
	StrCpy $0 "$INSTDIR\install.log"
	${If} ${FileExists} $0
		DetailPrint "Compress install log: ${LogFile}"
		FileOpen $1 "$0" "r"
		${If} "${LogMode}" == "A"
			FileOpen $2 "${LogFile}" "a"
			FileSeek $2 0 END
		${Else}
			FileOpen $2 "${LogFile}" "w"
		${EndIf}
		${Do}
			FileReadUTF16LE $1 $R9
			${If} $R9 == ""
				${ExitDo}
			${EndIf}
			StrCpy $R8 $R9 11
			${If} $R8 == "File: overw"
				${Continue}
			${ElseIf} $R8 == "CreateDirec"
				StrCpy $R7 $R9 7 -9
				${If} $R7 == "created"
					${Continue}
				${EndIf}
			${EndIf}
			FileWrite $2 "$R9"
		${Loop}
		FileClose $2
		FileClose $1
		Delete "$0"
	${EndIf}
!macroend

!macro Get_X64_Settings
	${If} ${RunningX64}
		SetRegView 64
		StrCpy $MiKTeX_BIN "bin\x64"
		StrCpy $MiKTeX_Setup ${MiKTeX_Setup64}
		StrCpy $Ghostscript_DLL "gsdll64.dll"
	${Else}
		SetRegView 32
		StrCpy $MiKTeX_BIN "bin"
		StrCpy $MiKTeX_Setup ${MiKTeX_Setup32}
		StrCpy $Ghostscript_DLL "gsdll32.dll"
	${EndIf}
!macroend

!macro Section_Select_X64 SectionMain SectionX64 SectionX86
	!insertmacro SelectSection ${SectionMain}
	${If} ${RunningX64}
		!insertmacro SelectSection ${SectionX64}
		!insertmacro UnselectSection ${SectionX86}
	${Else}
		!insertmacro UnselectSection ${SectionX64}
		!insertmacro SelectSection ${SectionX86}
	${EndIf}
!macroend

!macro Section_Change_X64 SectionMain SectionX64 SectionX86
	${If} ${SectionIsSelected} ${SectionMain}
		${If} ${RunningX64}
			!insertmacro SelectSection ${SectionX64}
			!insertmacro UnselectSection ${SectionX86}
		${Else}
			!insertmacro UnselectSection ${SectionX64}
			!insertmacro SelectSection ${SectionX86}
		${EndIf}
	${Else}
		!insertmacro UnselectSection ${SectionX64}
		!insertmacro UnselectSection ${SectionX86}
	${EndIf}
!macroend

!macro Check_Windows_X64
	${IfNot} ${RunningX64}
		MessageBox MB_OK|MB_ICONSTOP "$(Msg_X64Required)"
		Abort
	${EndIf}
!macroend

!macro Check_Windows_X86
	${If} ${RunningX64}
		MessageBox MB_OK|MB_ICONSTOP "$(Msg_X86Required)"
		Abort
	${EndIf}
!macroend

!macro Check_Admin_Rights
	${IfNot} ${UserIsAdmin}
		MessageBox MB_OK|MB_ICONSTOP "$(Msg_AdminRequired)"
		Abort
	${EndIf}
!macroend

!macro Get_StartMenu_Dir
	${If} ${UserIsAdmin}
		SetShellVarContext all
	${EndIf}
	StrCpy $SMCTEX "$SMPROGRAMS\CTeX"
	SetShellVarContext current
!macroend

!macro Update_MiKTeX_Packages
	DetailPrint "Update MiKTeX packages"
	${If} $MiKTeX != ""
		MessageBox MB_YESNO|MB_ICONQUESTION "$(Msg_UpdateMiKTeX)" /SD IDNO IDNO jumpNoUpdate
			${ExeCmd} "$INSTDIR\${MiKTeX_Dir}\miktex\$MiKTeX_BIN\miktex.exe" "--admin --disable-installer --verbose packages update"
		jumpNoUpdate:
	${EndIf}
!macroend
