
; Use compression
!ifdef BUILD_FULL
	SetCompressor /FINAL LZMA
	SetCompressorDictSize 128
!else
	SetCompressor /FINAL /SOLID LZMA
	SetCompressorDictSize 128
!endif

!include "CTeX_Version.nsh"

; Functions and Macros
!include "CTeX_Macros.nsh"

; Build settings
!define Include_Files_x64
!define Include_Files_x86

; Variables
Var UN_CONFIG_ONLY

; Main Install settings
BrandingText "${APP_NAME} ${APP_BUILD} (C) ${APP_COMPANY}"

!define Name "${APP_NAME} ${APP_VERSION_STAGE}"
!define InstallDir "C:\CTEX"

!define OutFileS1
!define OutFileS2
!ifdef BUILD_X64_ONLY
	!undef Include_Files_x86
	!define /redef OutFileS1 "_x64"
!endif
!ifdef BUILD_X86_ONLY
	!undef Include_Files_x64
	!define /redef OutFileS1 "_x86"
!endif
!ifdef BUILD_FULL
	!define /redef OutFileS2 "_Full"
!endif
!define OutFile "CTeX_${APP_BUILD}${OutFileS1}${OutFileS2}.exe"

!ifdef BUILD_REPAIR
	!define /redef InstallDir "$EXEDIR"
	!define /redef OutFile "Repair.exe"
!endif

Name "${Name}"
InstallDir "${InstallDir}"
OutFile "${OutFile}"

; Other settings
RequestExecutionLevel admin

; Modern interface settings
!include "MUI2.nsh"

!define MUI_ABORTWARNING
!ifndef BUILD_REPAIR
!define MUI_ICON "CTeX.ico"
!else
!define MUI_ICON "CTeX_Repair.ico"
!endif
!define MUI_UNICON "CTeX_Uninst.ico"
!define MUI_CUSTOMFUNCTION_GUIINIT onMUIInit

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE $(license)
!insertmacro MUI_PAGE_COMPONENTS
!ifndef BUILD_REPAIR
!define MUI_PAGE_CUSTOMFUNCTION_SHOW PageDirectoryShow
!endif
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; Set languages (first is default language)
!insertmacro MUI_LANGUAGE "SimpChinese"
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_RESERVEFILE_LANGDLL

Section -InitSection

	Call SectionInit

SectionEnd	

Section "MiKTeX" Section_MiKTeX
SectionEnd

Section "-MiKTeX_x64" Section_MiKTeX_x64

!ifdef Include_Files_x64
	SetOverwrite on
	SetOutPath "$INSTDIR\${MiKTeX_Dir}"

!ifndef BUILD_REPAIR
!ifndef BUILD_FULL
	${Install_Files} "MiKTeX.basic\*.*" "install_miktex.log"
!else
	${Install_Files} "MiKTeX.full\*.*" "install_miktex.log"
!endif
!endif

	!insertmacro Install_Config_MiKTeX
!endif

SectionEnd

Section "-MiKTeX_x86" Section_MiKTeX_x86

!ifdef Include_Files_x86
	SetOverwrite on
	SetOutPath "$INSTDIR\${MiKTeX_Dir}"

!ifndef BUILD_REPAIR
!ifndef BUILD_FULL
	${Install_Files} "MiKTeX.basic-x86\*.*" "install_miktex.log"
!else
	${Install_Files} "MiKTeX.full-x86\*.*" "install_miktex.log"
!endif
!endif

	!insertmacro Install_Config_MiKTeX
!endif

SectionEnd

Section "CTeX Addons" Section_Addons

	SetOverwrite On
	SetOutPath "$INSTDIR\${Addons_Dir}"

!ifndef BUILD_REPAIR
	${Install_Files} "Addons\CTeX\*.*" "install_addons.log"
	${Install_Files_A} "Addons\CJK\*.*" "install_addons.log"
	${Install_Files_A} "Addons\CCT\*.*" "install_addons.log"
	${Install_Files_A} "Addons\TY\*.*" "install_addons.log"
	${Install_Files_A} "Addons\Packages\*.*" "install_addons.log"

	${If} ${RunningX64}
!ifdef Include_Files_x64
		${Install_Files_A} "Addons\x64\*.*" "install_addons.log"
!endif
	${Else}
!ifdef Include_Files_x86
		${Install_Files_A} "Addons\x86\*.*" "install_addons.log"
!endif
	${EndIf}
!endif

	!insertmacro Install_Config_Addons

; Install Chinese fonts
!ifndef BUILD_REPAIR
	DetailPrint "Run FontSetup"
	${ExeCmd} "$INSTDIR\${Addons_Dir}\ctex\bin\FontSetup.exe" '/S /LANG=$LANGUAGE /CTEXSETUP="$INSTDIR\${Addons_Dir}"'
!endif

SectionEnd

Section "Ghostscript" Section_Ghostscript
SectionEnd

Section "-Ghostscript_x64" Section_Ghostscript_x64

!ifdef Include_Files_x64
	SetOverwrite on
	SetOutPath "$INSTDIR\${Ghostscript_Dir}"

!ifndef BUILD_REPAIR
	${Install_Files} "Ghostscript\*.*" "install_ghostscript.log"
!endif

	!insertmacro Install_Config_Ghostscript
!endif

SectionEnd

Section "-Ghostscript_x86" Section_Ghostscript_x86

!ifdef Include_Files_x86
	SetOverwrite on
	SetOutPath "$INSTDIR\${Ghostscript_Dir}"

!ifndef BUILD_REPAIR
	${Install_Files} "Ghostscript-x86\*.*" "install_ghostscript.log"
!endif

	!insertmacro Install_Config_Ghostscript
!endif

SectionEnd

Section "GSview" Section_GSview
SectionEnd

Section "-GSview_x64" Section_GSview_x64

!ifdef Include_Files_x64
	SetOverwrite on
	SetOutPath "$INSTDIR\${GSview_Dir}"

!ifndef BUILD_REPAIR
	${Install_Files} "GSview\*.*" "install_gsview.log"
!endif

	!insertmacro Install_Config_GSview
!endif

SectionEnd

Section "-GSview_x86" Section_GSview_x86

!ifdef Include_Files_x86
	SetOverwrite on
	SetOutPath "$INSTDIR\${GSview_Dir}"

!ifndef BUILD_REPAIR
	${Install_Files} "GSview-x86\*.*" "install_gsview.log"
!endif

	!insertmacro Install_Config_GSview
!endif

SectionEnd

Section "WinEdt" Section_WinEdt

	SetOverwrite on
	SetOutPath "$INSTDIR\${WinEdt_Dir}"

!ifndef BUILD_REPAIR
	${Install_Files} "WinEdt\*.*" "install_winedt.log"
!endif

	!insertmacro Install_Config_WinEdt

SectionEnd

Section -FinishSection

	SetOverwrite on
	SetOutPath $INSTDIR

!ifndef BUILD_REPAIR
	${Begin_Install_Files}
	File Readme.txt
	File Changes.txt
	File Repair.exe
	${End_Install_Files} "install.log"
!endif

	!insertmacro Install_Config_CTeX

	WriteUninstaller "$INSTDIR\Uninstall.exe"
	CreateDirectory "$SMCTEX"
	CreateShortCut "$SMCTEX\Uninstall CTeX.lnk" "$INSTDIR\Uninstall.exe"

	!insertmacro Update_MiKTeX_Packages

SectionEnd

; Modern install component descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
	!insertmacro MUI_DESCRIPTION_TEXT ${Section_MiKTeX} $(Desc_MiKTeX)
	!insertmacro MUI_DESCRIPTION_TEXT ${Section_Addons} $(Desc_Addons)
	!insertmacro MUI_DESCRIPTION_TEXT ${Section_Ghostscript} $(Desc_Ghostscript)
	!insertmacro MUI_DESCRIPTION_TEXT ${Section_GSview} $(Desc_GSview)
	!insertmacro MUI_DESCRIPTION_TEXT ${Section_WinEdt} $(Desc_WinEdt)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;Uninstall section
Section Uninstall

	;Remove configs...
	!insertmacro Uninstall_All_Configs "un."

	${If} $UN_CONFIG_ONLY != ""
		Return
	${EndIf}

	; Clean up CTeX
	!insertmacro Uninstall_All_Files "un."

	; Delete self
	Delete "$UN_INSTDIR\Uninstall.exe"

	; Remove remaining directories
	RMDir $UN_INSTDIR
	${If} ${FileExists} $UN_INSTDIR
		MessageBox MB_YESNO $(Msg_RemoveInstDir) /SD IDNO IDNO jumpNoRemove
			RMDir /r $UN_INSTDIR
		jumpNoRemove:
	${EndIf}

SectionEnd

; On initialization
Function .onInit

	!insertmacro MUI_LANGDLL_DISPLAY

	!insertmacro Get_X64_Settings
	!insertmacro Get_StartMenu_Dir
	!insertmacro Get_Uninstall_Information
	!insertmacro Restore_Install_Information
	!insertmacro Set_All_Sections_Selection
	
!ifdef BUILD_REPAIR
	!insertmacro Set_All_Sections_ReadOnly
!endif

	${If} ${Silent}
		Call onMUIInit
	${EndIf}

FunctionEnd

Function onMUIInit

!ifdef BUILD_X64_ONLY
	!insertmacro Check_Windows_X64
!endif
!ifdef BUILD_X86_ONLY
	!insertmacro Check_Windows_X86
!endif

	!insertmacro Check_Obsolete_Version
	!insertmacro Check_Update_Version
	!insertmacro Check_Admin_Rights

FunctionEnd

Function un.onInit
	${GetParameters} $R0
	${GetOptions} $R0 "/CONFIG_ONLY=" $UN_CONFIG_ONLY

	!insertmacro Get_X64_Settings
	!insertmacro Get_StartMenu_Dir
	!insertmacro Get_Uninstall_Information
	!insertmacro Update_Uninstall_Information

FunctionEnd

Function .onSelChange
	!insertmacro Section_Change_X64 ${Section_MiKTeX} ${Section_MiKTeX_x64} ${Section_MiKTeX_x86}
	!insertmacro Section_Change_X64 ${Section_Ghostscript} ${Section_Ghostscript_x64} ${Section_Ghostscript_x86}
	!insertmacro Section_Change_X64 ${Section_GSview} ${Section_GSview_x64} ${Section_GSview_x86}
FunctionEnd

Function SectionInit

!ifndef BUILD_REPAIR
	!insertmacro Update_Install_Information
!else
	!insertmacro Update_All_Logs
!endif

	DetailPrint "Remove old installation"
	${If} $UN_INSTDIR != ""
	${AndIf} ${FileExists} "$UN_INSTDIR\Uninstall.exe"
!ifdef BUILD_REPAIR
		StrCpy $R0 "/CONFIG_ONLY=yes"
!else
		StrCpy $R0 ""
!endif
		${ExeCmd} "$UN_INSTDIR\Uninstall.exe" '/S $R0 _?=$UN_INSTDIR'
	${Else}
		!insertmacro Uninstall_All_Configs ""
!ifndef BUILD_REPAIR
		!insertmacro Uninstall_All_Files ""
!endif
	${EndIf}

FunctionEnd

!ifndef BUILD_REPAIR
Function PageDirectoryShow

	${If} $UN_INSTDIR != ""
		FindWindow $R0 "#32770" "" $HWNDPARENT
		GetDlgItem $R1 $R0 1019
			SendMessage $R1 ${EM_SETREADONLY} 1 0
		GetDlgItem $R1 $R0 1001
			EnableWindow $R1 0
	${EndIf}

FunctionEnd
!endif

!insertmacro Set_Version_Information

; Language strings
LicenseLangString license ${LANG_SIMPCHINESE} License-zh.txt
LicenseLangString license ${LANG_ENGLISH} License-en.txt

LangString Desc_MiKTeX ${LANG_SIMPCHINESE} "Windows下最好用的TeX系统之一，它带有一个很优秀的DVI预览器Yap。"
LangString Desc_MiKTeX ${LANG_ENGLISH} "One of the best TeX system on Windows platform, with an excellent DVI previewer Yap."
LangString Desc_Addons ${LANG_SIMPCHINESE} "中文TeX组件，包括CJK/CCT/TY和相应的字体设置，以及一些中文LaTeX宏包。"
LangString Desc_Addons ${LANG_ENGLISH} "Chinese TeX addons, including CJK/CCT/TY and their Chinese font settings, and several Chinese LaTeX packages."
LangString Desc_Ghostscript ${LANG_SIMPCHINESE} "PS (PostScript)语言和PDF文件的解释器，可在非PS打印机上打印它们。可以将PS文件和PDF文件相互转换。"
LangString Desc_Ghostscript ${LANG_ENGLISH} "PS (PostScript) and PDF interpreter."
LangString Desc_GSview ${LANG_SIMPCHINESE} "GSview是Ghostscript的图形界面程序，通过Ghostscript的支持，可以很方便地浏览和修改PS文件。"
LangString Desc_GSview ${LANG_ENGLISH} "GSview is the frontend GUI of Ghostscript, used with Ghostscript to view and edit PS (PostScript) file."
LangString Desc_WinEdt ${LANG_SIMPCHINESE} "WinEdt是一个编辑器，它内置了对TeX的良好支持。在它的菜单上和按钮上可以直接调用TeX程序，包括编译、预览等。WinEdt还能帮助你迅速输入各种TeX命令和符号，省去你记忆大量命令的烦恼。"
LangString Desc_WinEdt ${LANG_ENGLISH} "WinEdt a well designed text editor with full support to edit and compile TeX file."

LangString Desc_File ${LANG_SIMPCHINESE} "文档"
LangString Desc_File ${LANG_ENGLISH} "File"

LangString Msg_X64Required ${LANG_SIMPCHINESE} "安装本程序需要64位Windows操作系统！"
LangString Msg_X64Required ${LANG_ENGLISH} "The 64-bit version of Windows is required to install the program!"
LangString Msg_X86Required ${LANG_SIMPCHINESE} "安装本程序需要32位Windows操作系统！"
LangString Msg_X86Required ${LANG_ENGLISH} "The 32-bit version of Windows is required to install the program!"
LangString Msg_AdminRequired ${LANG_SIMPCHINESE} "安装本程序需要管理员权限！"
LangString Msg_AdminRequired ${LANG_ENGLISH} "Adminstrator rights are required to install the program!"
LangString Msg_ObsoleteVersion ${LANG_SIMPCHINESE} "在系统中发现旧版的CTeX，请先卸载！"
LangString Msg_ObsoleteVersion ${LANG_ENGLISH} "Found obsolete version of CTeX installed in the system, please uninstall first!"
LangString Msg_WrongVersion ${LANG_SIMPCHINESE} "系统中安装了其他版本的CTeX，是否继续？"
LangString Msg_WrongVersion ${LANG_ENGLISH} "Another version of CTeX is installed in the system, continue?"
LangString Msg_Downgrade ${LANG_SIMPCHINESE} "系统中安装了更高版本的CTeX，是否继续进行降级安装？"
LangString Msg_Downgrade ${LANG_ENGLISH} "Newer version of CTeX is installed in the system, continue to downgrade setup?"
LangString Msg_RemoveInstDir ${LANG_SIMPCHINESE} "是否完全删除安装目录？"
LangString Msg_RemoveInstDir ${LANG_ENGLISH} "Remove all files in the installed diretory?"
LangString Msg_FontSetup ${LANG_SIMPCHINESE} "是否运行中文字体安装程序？"
LangString Msg_FontSetup ${LANG_ENGLISH} "Run the Chinese font setup program?"
LangString Msg_UpdateMiKTeX ${LANG_SIMPCHINESE} "是否在线更新MiKTeX？"
LangString Msg_UpdateMiKTeX ${LANG_ENGLISH} "Update MiKTeX through Internet?"
LangString Msg_ExeCmdError ${LANG_SIMPCHINESE} "执行以下命令时发现错误，请检查安装日志！"
LangString Msg_ExeCmdError ${LANG_ENGLISH} "Found errors when executing the following command, please check the installation log!"

; eof