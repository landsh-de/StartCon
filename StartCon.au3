#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=res\StartCon.ico
#AutoIt3Wrapper_Outfile=bin\StartCon.exe
#AutoIt3Wrapper_Outfile_x64=bin\StartCon64.exe
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_Res_Comment=Ein Starter fuer externe Programme. Konfiguriert ueber eine INI-Datei mit gleichem Namen der EXE-Datei.
#AutoIt3Wrapper_Res_Description=Ein Starter fuer externe Programme. Konfiguriert ueber eine INI-Datei mit gleichem Namen der EXE-Datei.
#AutoIt3Wrapper_Res_Fileversion=1.0.0.26
#AutoIt3Wrapper_Res_LegalCopyright=Copyright 2017-2021 by Veit Berwig. Lizenzierung unter der GPL 3.0 (Open-Source)
#AutoIt3Wrapper_Res_Language=1031
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#AutoIt3Wrapper_Res_Field=Author|Veit Berwig
#AutoIt3Wrapper_Res_Field=Info|Ein Starter fuer externe Programme. Konfiguriert ueber eine INI-Datei mit gleichem Namen der EXE-Datei.
#AutoIt3Wrapper_Run_Tidy=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

; ########### !!! THIS FILE IS ENCODED IN UTF-8 with BOM !!! ##########
; Author: 	Veit Berwig
; Desc.: 	Program-Launcher derived fron StartController for launching
;			programs without commandline-options
; Version: 	1.0.0.23
; Important Info:	We have to do a case sensitive    string-diff with:
; 					If Not ("String1" == "String2") Then ...
;					We have to do a case in-sensitive string-diff with:
; 					If Not ("String1" <> "String2") Then ...
; 					here !!
;
; == 	Tests if two strings are equal. Case sensitive.
;		The left and right values are converted to strings if they are
;		not strings already. This operator should only be used if
;		string comparisons need to be case sensitive.
; <> 	Tests if two values are not equal. Case insensitive	when used
;		with strings. To do a case sensitive not equal comparison use
; Not ("string1" == "string2")
;

#cs
	;**********************************************************************
	History:

	1.0.0.0 - 1.0.0.23

	-	Old Code


	1.0.0.24 (25.01.2021)

	- 	New Code

	-	Strip down the code to only execute a given program with local
		environment by using an ini-filename
	- 	File-Creation removed from code.
	- 	File-Creation for ini-config-file, when not existent

	1.0.0.25 (02.06.2021)

	-	Added a new option "DontCheckPATH" in INI-file for diabling the check
		of file-existence; so we can use programs without full-spec path
		and use them from search-PATH.

	1.0.0.26 (17.06.2021)

	-	Added a new option "REMOVE" in INI-file for deleting files after
		[KillApp]-Section. This is for a cleanup in order to remove
		stale files. Now user-context environment-variables are supported
		for cleaning up old files; i.e. %USERPROFILE%, %APPDATA%, %TEMP%,
		etc. For example cleaning up the socket-files of "gpg-agent" after
		killing all "Gpg4Win"-processes in order to start "Kleopatra"
		much faster under Windows at first time.

	-   The cleanupProc() was disabled, due to double execution of some
		functions in the main program and twice on exit() by cleanupProc().

	;**********************************************************************
#ce

#include <File.au3>
#include <string.au3>
#include <Constants.au3>
#include <StringConstants.au3>
#include <GuiConstants.au3>
#include <GUIConstantsEx.au3>
#include <FileConstants.au3>
#include <WinAPI.au3>
#include <Misc.au3>
#include <Date.au3>

; product name
Global $prod_name = "StartCon"

; generate dynamic name-instance from filename
Global $app_name = $prod_name
; retrieve short version of @ScriptName
Global $scriptname_short = StringTrimRight(@ScriptName, 4) ; Remove the 4 rightmost characters from the string.
If Not (StringLen($scriptname_short) = 0) Then
	$app_name = $scriptname_short
EndIf

Global $app_version = "1.0.0.26"
Global $app_copy = "Copyright 2017-2021 Veit Berwig"
Global $appname = $prod_name & " " & $app_version
Global $appGUID = $app_name & "-888f6427-5ef6-4678-87b3-722cedf676d7"


Local $PATHENVCLEAN
Global $sEnvPATH = EnvGet("PATH")
Global $pidController = 0
Global $pidController2 = 0

Global $ComSpec, $ComSpec_loc
Global $sControllerpath, $sControllerpath_, $PrgWorkDir, $PrgWorkDirloc, $EnvUpdate_bool
Global $Config_File, $launchapp, $dontcheckpath, $launchproc, $launchapp_param, $launchproc_sleep
Global $https_proxy, $http_proxy, $ftp_proxy
Global $launchproc_cascade, $launchproc_cascade_bool, $launchproc_hidden, $launchproc_hidden_bool
Global $launchproc_wait, $launchproc_wait_bool
Global $launchproc_dontcheck, $launchproc_dontcheck_bool

Global $killapp
Global $killapp0, $killapp1, $killapp2, $killapp3, $killapp4
Global $killapp5, $killapp6, $killapp7, $killapp8, $killapp9
Global $killapp10, $killapp11, $killapp12, $killapp13, $killapp14
Global $killapp15, $killapp16, $killapp17, $killapp18, $killapp19

Global $closewin
Global $closewin0, $closewin1, $closewin2, $closewin3, $closewin4
Global $closewin5, $closewin6, $closewin7, $closewin8, $closewin9
Global $closewin10, $closewin11, $closewin12, $closewin13, $closewin14
Global $closewin15, $closewin16, $closewin17, $closewin18, $closewin19

Global $remove
Global $remove0, $remove1, $remove2, $remove3, $remove4
Global $remove5, $remove6, $remove7, $remove8, $remove9
Global $remove10, $remove11, $remove12, $remove13, $remove14
Global $remove15, $remove16, $remove17, $remove18, $remove19

Global $closewinWAIT_bool, $closewinTMOUT

Global $sDateTime = @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC

Opt("GUIOnEventMode", 1)
Opt("TrayOnEventMode", 1)
Opt("TrayAutoPause", 0)    ; The script will not pause when selecting the tray icon.
Opt("TrayMenuMode", 2)     ; Items are not checked when selected.
Opt("ExpandEnvStrings", 1) ; 1 = erweitert Umgebungsvariablen innerhalb von Strings und %-Symbolen im Code und in den INI-Dateien.

; Extend the behaviour of the script tray icon/menu.
; This can be done with a combination (adding) of the following values.
; 0 = default menu items (Script Paused/Exit) are appended to the usercreated menu;
;     usercreated checked items will automatically unchecked; if you double click
;     the tray icon then the controlid is returned which has the "Default"-style (default).
; 1 = no default menu
; 2 = user created checked items will not automatically unchecked if you click it
; 4 = don't return the menuitemID which has the "default"-style in the main
;     contextmenu if you double click the tray icon
; 8 = turn off auto check of radio item groups
Opt("TrayMenuMode", 10)
; Opt("TrayMenuMode", 1)

TrayItemSetText($TRAY_ITEM_EXIT, $app_name & " beenden ...") ; Set the text of the default 'Exit' item.
TrayItemSetText($TRAY_ITEM_PAUSE, $app_name & " anhalten ...") ; Set the text of the default 'Pause' item.

TraySetClick(16)
TraySetToolTip($app_name)

$sControllerpath = FileGetLongName(@ScriptDir)
; If whe have only 3 chars, then we are in the root-dir with an
; additional backslash at the end of the pathname. this will
; result in \\; so we have to fix this here.
If (StringLen($sControllerpath) = 3) Then
	$sControllerpath_ = StringRegExpReplace($sControllerpath, "([\\])", "")
Else
	$sControllerpath_ = $sControllerpath
EndIf

; debug-info
;MsgBox(0, "Controllerpath is:", $sControllerpath_)

; Check for running only one instance of process (in Misc.au3)
; $sOccurenceName String to identify the occurrence of the script.
; This string may not contain the \ character unless you are placing the
; object in a namespace (See Remarks).
;
; $iFlag [optional] Behavior options.
; 0 - Exit the script with the exit code -1 if another instance already exists.
; 1 - Return from the function without exiting the script.
; 2 - Allow the object to be accessed by anybody in the system. This is useful
;     if specifying a "Global\" object in a multi-user environment.
; You can place the object in a namespace by prefixing your object name with
; either "Global\" or "Local\". "Global\" objects combined with the flag 2 are
; useful in multi-user environments.
If _Singleton($appGUID, 1) = 0 Then
	MsgBox(16, $appname, "Eine Instanz dieses Programmes:" & @CRLF & '"' & $appname & '"' & @CRLF & "läuft schon im Hauptspeicher !" & @CRLF & @CRLF & "Bitte das Programm erst beenden !", 10)
	Exit
EndIf


; ------------ WRITE DEFAULT INI FILE


; Build absolute file-pathname
$Config_File = FileGetLongName($sControllerpath_ & "\" & $app_name & ".ini")

; Install the ini-file if no ini-file is existent
If (FileExists($Config_File) <> 1) Then
	; Write the value of 'Value' to the key 'Key' and in the section labelled 'Section'.
	; IniWrite("INI-File", "Section", "Key", "Value")
	IniWrite($Config_File, "Main Prefs", "LaunchAPP", "rel-path\program.exe")
	IniWrite($Config_File, "Main Prefs", "DontCheckPATH", "false")
	IniWrite($Config_File, "Main Prefs", "LaunchPROC", "program.exe")
	IniWrite($Config_File, "Main Prefs", "LaunchPROC_SLEEP", "4")

	IniWrite($Config_File, "Main Prefs", "WORK_DIR", "")
	IniWrite($Config_File, "Main Prefs", "ComSpec", "")

	IniWrite($Config_File, "Main Prefs", "LaunchAPP_Param", "")
	IniWrite($Config_File, "Main Prefs", "LaunchPROC_CASCADE", "false")
	IniWrite($Config_File, "Main Prefs", "LaunchPROC_HIDDEN", "false")

	IniWrite($Config_File, "Main Prefs", "LaunchPROC_WAIT", "true")
	IniWrite($Config_File, "Main Prefs", "LaunchPROC_DONTCHECK", "false")

	IniWrite($Config_File, "Main Prefs", "EnvUpdate", "false")

	IniWrite($Config_File, "Main Prefs", "http_proxy", "")
	IniWrite($Config_File, "Main Prefs", "http_proxy_format_example", "http://proxyserver:proxyport/")
	IniWrite($Config_File, "Main Prefs", "http_proxy_example", "http://127.0.0.1:3128/")
	IniWrite($Config_File, "Main Prefs", "https_proxy", "")
	IniWrite($Config_File, "Main Prefs", "https_proxy_format_example", "https://proxyserver:proxyport/")
	IniWrite($Config_File, "Main Prefs", "https_proxy_example", "https://127.0.0.1:3128/")
	IniWrite($Config_File, "Main Prefs", "ftp_proxy", "")
	IniWrite($Config_File, "Main Prefs", "ftp_proxy_format_example", "http://proxyserver:proxyport/")
	IniWrite($Config_File, "Main Prefs", "ftp_proxy_example", "http://127.0.0.1:3128/")


	IniWrite($Config_File, "KillApp", "KILLAPP0", "")
	IniWrite($Config_File, "KillApp", "KILLAPP1", "")
	IniWrite($Config_File, "KillApp", "KILLAPP2", "")
	IniWrite($Config_File, "KillApp", "KILLAPP3", "")
	IniWrite($Config_File, "KillApp", "KILLAPP4", "")
	IniWrite($Config_File, "KillApp", "KILLAPP5", "")
	IniWrite($Config_File, "KillApp", "KILLAPP6", "")
	IniWrite($Config_File, "KillApp", "KILLAPP7", "")
	IniWrite($Config_File, "KillApp", "KILLAPP8", "")
	IniWrite($Config_File, "KillApp", "KILLAPP9", "")

	IniWrite($Config_File, "KillApp", "KILLAPP10", "")
	IniWrite($Config_File, "KillApp", "KILLAPP11", "")
	IniWrite($Config_File, "KillApp", "KILLAPP12", "")
	IniWrite($Config_File, "KillApp", "KILLAPP13", "")
	IniWrite($Config_File, "KillApp", "KILLAPP14", "")
	IniWrite($Config_File, "KillApp", "KILLAPP15", "")
	IniWrite($Config_File, "KillApp", "KILLAPP16", "")
	IniWrite($Config_File, "KillApp", "KILLAPP17", "")
	IniWrite($Config_File, "KillApp", "KILLAPP18", "")
	IniWrite($Config_File, "KillApp", "KILLAPP19", "")

	IniWrite($Config_File, "Remove", "REMOVE0", "")
	IniWrite($Config_File, "Remove", "REMOVE1", "")
	IniWrite($Config_File, "Remove", "REMOVE2", "")
	IniWrite($Config_File, "Remove", "REMOVE3", "")
	IniWrite($Config_File, "Remove", "REMOVE4", "")
	IniWrite($Config_File, "Remove", "REMOVE5", "")
	IniWrite($Config_File, "Remove", "REMOVE6", "")
	IniWrite($Config_File, "Remove", "REMOVE7", "")
	IniWrite($Config_File, "Remove", "REMOVE8", "")
	IniWrite($Config_File, "Remove", "REMOVE9", "")

	IniWrite($Config_File, "Remove", "REMOVE10", "")
	IniWrite($Config_File, "Remove", "REMOVE11", "")
	IniWrite($Config_File, "Remove", "REMOVE12", "")
	IniWrite($Config_File, "Remove", "REMOVE13", "")
	IniWrite($Config_File, "Remove", "REMOVE14", "")
	IniWrite($Config_File, "Remove", "REMOVE15", "")
	IniWrite($Config_File, "Remove", "REMOVE16", "")
	IniWrite($Config_File, "Remove", "REMOVE17", "")
	IniWrite($Config_File, "Remove", "REMOVE18", "")
	IniWrite($Config_File, "Remove", "REMOVE19", "")

	IniWrite($Config_File, "CloseWin", "CLOSEWIN0", "")
	IniWrite($Config_File, "CloseWin", "CLOSEWIN1", "")
	IniWrite($Config_File, "CloseWin", "CLOSEWIN2", "")
	IniWrite($Config_File, "CloseWin", "CLOSEWIN3", "")
	IniWrite($Config_File, "CloseWin", "CLOSEWIN4", "")
	IniWrite($Config_File, "CloseWin", "CLOSEWIN5", "")
	IniWrite($Config_File, "CloseWin", "CLOSEWIN6", "")
	IniWrite($Config_File, "CloseWin", "CLOSEWIN7", "")
	IniWrite($Config_File, "CloseWin", "CLOSEWIN8", "")
	IniWrite($Config_File, "CloseWin", "CLOSEWIN9", "")

	IniWrite($Config_File, "CloseWin", "CLOSEWIN10", "")
	IniWrite($Config_File, "CloseWin", "CLOSEWIN11", "")
	IniWrite($Config_File, "CloseWin", "CLOSEWIN12", "")
	IniWrite($Config_File, "CloseWin", "CLOSEWIN13", "")
	IniWrite($Config_File, "CloseWin", "CLOSEWIN14", "")
	IniWrite($Config_File, "CloseWin", "CLOSEWIN15", "")
	IniWrite($Config_File, "CloseWin", "CLOSEWIN16", "")
	IniWrite($Config_File, "CloseWin", "CLOSEWIN17", "")
	IniWrite($Config_File, "CloseWin", "CLOSEWIN18", "")
	IniWrite($Config_File, "CloseWin", "CLOSEWIN19", "")

	IniWrite($Config_File, "CloseWin", "CLOSEWINWAIT", "false")
	IniWrite($Config_File, "CloseWin", "CLOSEWINTMOUT", "10")

EndIf


; ------------ READ INI FILE


$launchapp = StringLower(IniRead($Config_File, "Main Prefs", "LaunchAPP", ""))

; Check for file-existence of LaunchAPP - executable (default: checking is enabled).
$dontcheckpath = StringLower(IniRead($Config_File, "Main Prefs", "DontCheckPATH", "false"))
If $dontcheckpath <> "true" Then
	$dontcheckpath = "false"
EndIf

$launchproc = StringLower(IniRead($Config_File, "Main Prefs", "LaunchPROC", ""))

$PrgWorkDir = IniRead($Config_File, "Main Prefs", "WORK_DIR", "")
If $PrgWorkDir <> "" Then
	$PrgWorkDirloc = FileGetLongName($PrgWorkDir)
	If Not FileExists($PrgWorkDirloc) Then
		MsgBox(64, $appname, "Das Verzeichnis in der Variablen " & """" & "WORK_DIR" & """" & ":" & @CRLF & @CRLF & $PrgWorkDirloc & @CRLF & @CRLF & "konnte nicht gefunden werden !" & @CRLF & @CRLF & "Es muss ein existierender Pfad angegeben werden !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
		Exit
	EndIf
Else
	;Assign("PrgWorkDirloc", $sControllerpath_)
	$PrgWorkDirloc = $sControllerpath_
EndIf

$ComSpec = StringLower(IniRead($Config_File, "Main Prefs", "ComSpec", ""))
$ComSpec_loc = ""
If $ComSpec <> "" Then
	$ComSpec_loc = FileGetLongName($ComSpec)
	If Not FileExists($ComSpec_loc) Then
		MsgBox(64, $appname, "Die Datei in der Variablen " & """" & "ComSpec" & """" & ":" & @CRLF & @CRLF & $ComSpec_loc & @CRLF & @CRLF & "konnte nicht gefunden werden !" & @CRLF & @CRLF & "Es muss ein existierender Pfad angegeben werden !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
		Exit
	EndIf
	If StringRight($ComSpec, 4) <> ".exe" Then
		MsgBox(64, $appname, "Die Datei in der Variablen " & """" & "ComSpec" & """" & ":" & @CRLF & @CRLF & $ComSpec_loc & @CRLF & @CRLF & "muss eine ausführbare .exe-Datei sein !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
		Exit
	EndIf
EndIf

If $launchapp = "" Then
	MsgBox(16, "Fehler in der INI-Datei ...", "Die Variable:" & @CRLF & @CRLF & '"' & "LaunchAPP" & '"' & @CRLF & @CRLF & "muss (darf) den absoluten Pfad zu diesem Programm  " & @CRLF & "und die ausführbare Datei beinhalten !", 10)
	Exit
EndIf

If $launchproc = "" Then
	MsgBox(16, "Fehler in der INI-Datei ...", "Die Variable:" & @CRLF & @CRLF & '"' & "LaunchPROC" & '"' & @CRLF & @CRLF & "muss den ausführbaren Teil der Variablen LaunchAPP  " & @CRLF & "oder ein gestartetes Programm beinhalten !", 10)
	Exit
EndIf

If $launchproc = ".exe" Then
	MsgBox(16, "Fehler in der INI-Datei ...", "Die Variable:" & @CRLF & @CRLF & '"' & "LaunchPROC" & '"' & @CRLF & @CRLF & "muss den ausführbaren Teil der Variablen LaunchAPP  " & @CRLF & "oder ein gestartetes Programm beinhalten !", 10)
	Exit
EndIf

If StringRight($launchproc, 4) <> ".exe" Then
	MsgBox(16, "Fehler in der INI-Datei ...", "Die Variable:" & @CRLF & @CRLF & '"' & "LaunchPROC" & '"' & @CRLF & @CRLF & "muss den ausführbaren Teil der Variablen LaunchAPP  " & @CRLF & "oder ein gestartetes Programm beinhalten !", 10)
	Exit
EndIf

$launchproc_sleep = IniRead($Config_File, "Main Prefs", "LaunchPROC_SLEEP", "4")
If StringIsDigit($launchproc_sleep) <> 1 Then
	MsgBox(16, "Fehler in der INI-Datei ...", "Die Variable:" & @CRLF & @CRLF & '"' & "LaunchPROC_SLEEP" & '"' & @CRLF & @CRLF & "muss einen numerischen Wert in Sekunden " & @CRLF & "( z.B.: 6 für 6 Sek. ) beinhalten !", 10)
	Exit
EndIf

; Check for exporting local environment to global environment and update its content to the OS
$EnvUpdate_bool = StringLower(IniRead($Config_File, "Main Prefs", "EnvUpdate", "false"))
If $EnvUpdate_bool <> "true" Then
	$EnvUpdate_bool = "false"
EndIf

; Check proxy-url formats
$http_proxy = IniRead($Config_File, "Main Prefs", "http_proxy", "")
If $http_proxy <> "" Then
	If StringLen($http_proxy) > 50 Then
		MsgBox(64, $appname, "Die Variable " & """" & "http_proxy" & """" & ":" & @CRLF & @CRLF & $http_proxy & @CRLF & @CRLF & "ist grösser als 50 Zeichen !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
		Exit
	EndIf
	If StringInStr($http_proxy, ":", 0, 1) = 0 Then
		MsgBox(64, $appname, "Die Variable " & """" & "http_proxy" & """" & ":" & @CRLF & @CRLF & $http_proxy & @CRLF & @CRLF & "enthält kein "":"" Zeichen !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
		Exit
	EndIf
EndIf

; Check proxy-url formats
$https_proxy = IniRead($Config_File, "Main Prefs", "https_proxy", "")
If $https_proxy <> "" Then
	If StringLen($https_proxy) > 50 Then
		MsgBox(64, $appname, "Die Variable " & """" & "https_proxy" & """" & ":" & @CRLF & @CRLF & $https_proxy & @CRLF & @CRLF & "ist grösser als 50 Zeichen !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
		Exit
	EndIf
	If StringInStr($https_proxy, ":", 0, 1) = 0 Then
		MsgBox(64, $appname, "Die Variable " & """" & "https_proxy" & """" & ":" & @CRLF & @CRLF & $https_proxy & @CRLF & @CRLF & "enthält kein "":"" Zeichen !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
		Exit
	EndIf
EndIf

; Check proxy-url formats
$ftp_proxy = IniRead($Config_File, "Main Prefs", "ftp_proxy", "")
If $ftp_proxy <> "" Then
	If StringLen($ftp_proxy) > 50 Then
		MsgBox(64, $appname, "Die Variable " & """" & "ftp_proxy" & """" & ":" & @CRLF & @CRLF & $ftp_proxy & @CRLF & @CRLF & "ist grösser als 50 Zeichen !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
		Exit
	EndIf
	If StringInStr($ftp_proxy, ":", 0, 1) = 0 Then
		MsgBox(64, $appname, "Die Variable " & """" & "ftp_proxy" & """" & ":" & @CRLF & @CRLF & $ftp_proxy & @CRLF & @CRLF & "enthält kein "":"" Zeichen !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
		Exit
	EndIf
EndIf

; Check for cascaded execution of same-named processes.
; (name.exe is calling name.exe in another dir and is exiting after child execution ...)
$launchproc_cascade = StringLower(IniRead($Config_File, "Main Prefs", "LaunchPROC_CASCADE", "false"))
If $launchproc_cascade = "false" Then
	$launchproc_cascade_bool = "0"
ElseIf $launchproc_cascade = "true" Then
	$launchproc_cascade_bool = "1"
Else
	MsgBox(16, "Fehler in der INI-Datei ...", "Die Variable:" & @CRLF & @CRLF & '"' & "LaunchPROC_CASCADE" & '"' & @CRLF & @CRLF & "muss einen BOOLEAN Wert mit " & '"' & "true" & '"' & " oder " & '"' & "false" & '"' & " beinhalten !", 10)
	Exit
EndIf

; Check for execution check if already running.
; (could be a problem when multiple processes running; like "cmd.exe")
$launchproc_dontcheck = StringLower(IniRead($Config_File, "Main Prefs", "LaunchPROC_DONTCHECK", "false"))
If $launchproc_dontcheck = "false" Then
	$launchproc_dontcheck_bool = "0"
ElseIf $launchproc_dontcheck = "true" Then
	$launchproc_dontcheck_bool = "1"
Else
	MsgBox(16, "Fehler in der INI-Datei ...", "Die Variable:" & @CRLF & @CRLF & '"' & "LaunchPROC_DONTCHECK" & '"' & @CRLF & @CRLF & "muss einen BOOLEAN Wert mit " & '"' & "true" & '"' & " oder " & '"' & "false" & '"' & " beinhalten !", 10)
	Exit
EndIf

; Check for waiting of execution of same-named processes.
; (synchronous mode, when true)
$launchproc_wait = StringLower(IniRead($Config_File, "Main Prefs", "LaunchPROC_WAIT", "true"))
If $launchproc_wait = "false" Then
	$launchproc_wait_bool = "0"
ElseIf $launchproc_wait = "true" Then
	$launchproc_wait_bool = "1"
Else
	MsgBox(16, "Fehler in der INI-Datei ...", "Die Variable:" & @CRLF & @CRLF & '"' & "LaunchPROC_WAIT" & '"' & @CRLF & @CRLF & "muss einen BOOLEAN Wert mit " & '"' & "true" & '"' & " oder " & '"' & "false" & '"' & " beinhalten !", 10)
	Exit
EndIf

; Check for hidden execution flag of same-named process.
$launchproc_hidden = StringLower(IniRead($Config_File, "Main Prefs", "LaunchPROC_HIDDEN", "false"))
If $launchproc_hidden = "false" Then
	$launchproc_hidden_bool = @SW_SHOWNORMAL
ElseIf $launchproc_hidden = "true" Then
	$launchproc_hidden_bool = @SW_HIDE
Else
	MsgBox(16, "Fehler in der INI-Datei ...", "Die Variable:" & @CRLF & @CRLF & '"' & "LaunchPROC_HIDDEN" & '"' & @CRLF & @CRLF & "muss einen BOOLEAN Wert mit " & '"' & "true" & '"' & " oder " & '"' & "false" & '"' & " beinhalten !", 10)
	Exit
EndIf

; Search for special string "XXXXXX" and replace it with
; local program-start-time-string, so we are able to
; create unique output file every second.
$launchapp_param = IniRead($Config_File, "Main Prefs", "LaunchAPP_Param", "")
If (StringInStr($launchapp_param, "XXXXXX") <> 0) Then
	Local $s_launchapp_param = StringReplace($launchapp_param, "XXXXXX", $sDateTime)
	$launchapp_param = $s_launchapp_param
EndIf


; Read apps to kill
$killapp0 = StringLower(IniRead($Config_File, "KillApp", "KILLAPP0", ""))
$killapp1 = StringLower(IniRead($Config_File, "KillApp", "KILLAPP1", ""))
$killapp2 = StringLower(IniRead($Config_File, "KillApp", "KILLAPP2", ""))
$killapp3 = StringLower(IniRead($Config_File, "KillApp", "KILLAPP3", ""))
$killapp4 = StringLower(IniRead($Config_File, "KillApp", "KILLAPP4", ""))
$killapp5 = StringLower(IniRead($Config_File, "KillApp", "KILLAPP5", ""))
$killapp6 = StringLower(IniRead($Config_File, "KillApp", "KILLAPP6", ""))
$killapp7 = StringLower(IniRead($Config_File, "KillApp", "KILLAPP7", ""))
$killapp8 = StringLower(IniRead($Config_File, "KillApp", "KILLAPP8", ""))
$killapp9 = StringLower(IniRead($Config_File, "KillApp", "KILLAPP9", ""))

$killapp10 = StringLower(IniRead($Config_File, "KillApp", "KILLAPP10", ""))
$killapp11 = StringLower(IniRead($Config_File, "KillApp", "KILLAPP11", ""))
$killapp12 = StringLower(IniRead($Config_File, "KillApp", "KILLAPP12", ""))
$killapp13 = StringLower(IniRead($Config_File, "KillApp", "KILLAPP13", ""))
$killapp14 = StringLower(IniRead($Config_File, "KillApp", "KILLAPP14", ""))
$killapp15 = StringLower(IniRead($Config_File, "KillApp", "KILLAPP15", ""))
$killapp16 = StringLower(IniRead($Config_File, "KillApp", "KILLAPP16", ""))
$killapp17 = StringLower(IniRead($Config_File, "KillApp", "KILLAPP17", ""))
$killapp18 = StringLower(IniRead($Config_File, "KillApp", "KILLAPP18", ""))
$killapp19 = StringLower(IniRead($Config_File, "KillApp", "KILLAPP19", ""))

; Read opbjects to remove from filesystem
$remove0 = StringLower(IniRead($Config_File, "Remove", "REMOVE0", ""))
$remove1 = StringLower(IniRead($Config_File, "Remove", "REMOVE1", ""))
$remove2 = StringLower(IniRead($Config_File, "Remove", "REMOVE2", ""))
$remove3 = StringLower(IniRead($Config_File, "Remove", "REMOVE3", ""))
$remove4 = StringLower(IniRead($Config_File, "Remove", "REMOVE4", ""))
$remove5 = StringLower(IniRead($Config_File, "Remove", "REMOVE5", ""))
$remove6 = StringLower(IniRead($Config_File, "Remove", "REMOVE6", ""))
$remove7 = StringLower(IniRead($Config_File, "Remove", "REMOVE7", ""))
$remove8 = StringLower(IniRead($Config_File, "Remove", "REMOVE8", ""))
$remove9 = StringLower(IniRead($Config_File, "Remove", "REMOVE9", ""))

$remove10 = StringLower(IniRead($Config_File, "Remove", "REMOVE10", ""))
$remove11 = StringLower(IniRead($Config_File, "Remove", "REMOVE11", ""))
$remove12 = StringLower(IniRead($Config_File, "Remove", "REMOVE12", ""))
$remove13 = StringLower(IniRead($Config_File, "Remove", "REMOVE13", ""))
$remove14 = StringLower(IniRead($Config_File, "Remove", "REMOVE14", ""))
$remove15 = StringLower(IniRead($Config_File, "Remove", "REMOVE15", ""))
$remove16 = StringLower(IniRead($Config_File, "Remove", "REMOVE16", ""))
$remove17 = StringLower(IniRead($Config_File, "Remove", "REMOVE17", ""))
$remove18 = StringLower(IniRead($Config_File, "Remove", "REMOVE18", ""))
$remove19 = StringLower(IniRead($Config_File, "Remove", "REMOVE19", ""))

; Read windows names to softly close windows
$closewin0 = IniRead($Config_File, "CloseWin", "CLOSEWIN0", "")
$closewin1 = IniRead($Config_File, "CloseWin", "CLOSEWIN1", "")
$closewin2 = IniRead($Config_File, "CloseWin", "CLOSEWIN2", "")
$closewin3 = IniRead($Config_File, "CloseWin", "CLOSEWIN3", "")
$closewin4 = IniRead($Config_File, "CloseWin", "CLOSEWIN4", "")
$closewin5 = IniRead($Config_File, "CloseWin", "CLOSEWIN5", "")
$closewin6 = IniRead($Config_File, "CloseWin", "CLOSEWIN6", "")
$closewin7 = IniRead($Config_File, "CloseWin", "CLOSEWIN7", "")
$closewin8 = IniRead($Config_File, "CloseWin", "CLOSEWIN8", "")
$closewin9 = IniRead($Config_File, "CloseWin", "CLOSEWIN9", "")

$closewin10 = IniRead($Config_File, "CloseWin", "CLOSEWIN10", "")
$closewin11 = IniRead($Config_File, "CloseWin", "CLOSEWIN11", "")
$closewin12 = IniRead($Config_File, "CloseWin", "CLOSEWIN12", "")
$closewin13 = IniRead($Config_File, "CloseWin", "CLOSEWIN13", "")
$closewin14 = IniRead($Config_File, "CloseWin", "CLOSEWIN14", "")
$closewin15 = IniRead($Config_File, "CloseWin", "CLOSEWIN15", "")
$closewin16 = IniRead($Config_File, "CloseWin", "CLOSEWIN16", "")
$closewin17 = IniRead($Config_File, "CloseWin", "CLOSEWIN17", "")
$closewin18 = IniRead($Config_File, "CloseWin", "CLOSEWIN18", "")
$closewin19 = IniRead($Config_File, "CloseWin", "CLOSEWIN19", "")

; Check for waiting of closing windows
$closewinWAIT_bool = StringLower(IniRead($Config_File, "CloseWin", "CLOSEWINWAIT", "false"))
If $closewinWAIT_bool <> "true" Then
	$closewinWAIT_bool = "false"
EndIf

; Check for timeout when waiting for closing windows
$closewinTMOUT = IniRead($Config_File, "CloseWin", "CLOSEWINTMOUT", "10")
If StringIsDigit($closewinTMOUT) <> 1 Then
	MsgBox(16, "Fehler in der INI-Datei ...", "Die Variable:" & @CRLF & @CRLF & '"' & "CLOSEWINTMOUT" & '"' & @CRLF & @CRLF & "muss einen numerischen Wert in Sekunden " & @CRLF & "( z.B.: 6 für 6 Sek. ) beinhalten !", 10)
	Exit
EndIf

; Check format of $remove0-$remove19 paths
For $i = 0 To 19 Step 1
	$remove = Eval("remove" & $i)

	If $remove <> "" Then
		If StringLen($remove) > 256 Then
			MsgBox(64, $appname, "Eine Variable in der Sektion " & """" & "[Remove]" & """" & ":" & @CRLF & @CRLF & $remove & @CRLF & @CRLF & "ist grösser als 256 Zeichen !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
			Exit
		EndIf
		If StringLen($remove) < 10 Then
			MsgBox(64, $appname, "Eine Variable in der Sektion " & """" & "[Remove]" & """" & ":" & @CRLF & @CRLF & $remove & @CRLF & @CRLF & "ist kleiner als 10 Zeichen !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
			Exit
		EndIf
		If StringInStr($remove, "\", 0, 1) = 0 Then
			MsgBox(64, $appname, "Eine Variable in der Sektion " & """" & "[Remove]" & """" & ":" & @CRLF & @CRLF & $remove & @CRLF & @CRLF & "enthält kein ""\"" Zeichen !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
			Exit
		EndIf
	EndIf

Next

; ------------ CRECK FILES

; ------------ WRITE ENVIRONMENT

EnvSet("EXEC_DATE", $sDateTime)
EnvSet("WORK_DIR", $PrgWorkDirloc)
EnvSet("DIRCMD", "/O:GNE")


If $ComSpec_loc <> "" Then
	EnvSet("ComSpec", $ComSpec_loc)
EndIf

; ------------ Set the proxy-server for programs evaluating the http_proxy scheme
If $http_proxy <> "" Then
	EnvSet("http_proxy", $http_proxy)
EndIf
If $https_proxy <> "" Then
	EnvSet("https_proxy", $https_proxy)
EndIf
If $ftp_proxy <> "" Then
	EnvSet("ftp_proxy", $ftp_proxy)
EndIf


; PATH of local execution
EnvSet("CONTROLLERPATH", $sControllerpath_)

; Cleanup PATH-String from trash
$PATHENVCLEAN = $sControllerpath_
EnvSet("PATH", $PATHENVCLEAN & ";" & $sEnvPATH)

; Make Environment global
If $EnvUpdate_bool = "true" Then EnvUpdate()

If $launchproc_dontcheck = "false" Then
	If ProcessExists($launchproc) Then
		MsgBox(16, $appname, "Der Prozess:" & @CRLF & '"' & $launchproc & '"' & @CRLF & "läuft schon im Hauptspeicher !" & @CRLF & @CRLF & "Bitte das Programm erst beenden !", 10)
		Exit
	EndIf
EndIf

OnAutoItExitRegister("cleanupProc")
runController()
Exit


Func runController()

	If $dontcheckpath = "false" Then
		If Not FileExists($launchapp) Then
			MsgBox(64, $appname, "In dem Verzeichnis:" & @CRLF & $sControllerpath_ & @CRLF & "konnte die Datei:" & @CRLF & @CRLF & '"' & $launchapp & '"' & @CRLF & @CRLF & "nicht gefunden werden !" & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 10)
			Exit
		EndIf
	EndIf

	If $pidController = 0 Then
		$pidController = Run($launchapp & " " & $launchapp_param, $PrgWorkDirloc, $launchproc_hidden_bool)
	EndIf

	If $launchproc_wait = "true" Then
		; Wait for process ...
		; We pay attention for loaders which are named like their started applications !!
		;Sleep($launchproc_sleep) ; Sleep for $launchproc_sleep seconds and wait for possible loaders.
		TraySetToolTip($app_name & ":" & " warte max. " & $launchproc_sleep & " Sek. auf Prozess ...")
		ProcessWait($launchproc, $launchproc_sleep) ; Wait for the $launchproc process to exist.

		TraySetToolTip($app_name & ":" & " warte auf Prozess-Ende ...")
		ProcessWaitClose($pidController) ; Wait for the $launchproc process to exit.

		; check for cascaded execution of same-named processes.
		; (name.exe is calling name.exe in another dir and is exiting after child execution ...)
		; ToDo: additional checks are necessary here due to new created PID for sub-process
		; 		Maybe $pidController2 is not the correct PID here ...
		If $launchproc_cascade_bool = "1" Then
			TraySetToolTip($app_name & ":" & " warte max. " & $launchproc_sleep & " Sek. auf Prozess ...")
			$pidController2 = ProcessWait($launchproc, $launchproc_sleep) ; Wait for the $launchproc process to exist.

			TraySetToolTip($app_name & ":" & " warte auf Prozess-Ende ...")
			ProcessWaitClose($pidController2) ; Wait for the $launchproc process to exit.
		EndIf

	EndIf

	TraySetToolTip($app_name)

	; First try to close windows named CLOSEWIN0-CLOSEWIN19 softly
	For $i = 0 To 19 Step 1
		$closewin = Eval("closewin" & $i)
		If $closewin <> "" Then
			WinClose($closewin)
			If $closewinWAIT_bool == "true" Then
				WinWaitClose($closewin, "", $closewinTMOUT)
			EndIf
		EndIf
	Next

	; Second forced kill processes KILLAPP0-KILLAPP19
	For $i = 0 To 19 Step 1
		$killapp = Eval("killapp" & $i)
		If $killapp <> "" Then
			If StringRight($killapp, 4) = ".exe" Then
				ProcessClose($killapp)
			EndIf
		EndIf
	Next

	; Third try to delete filesystem-objects REMOVE0-REMOVE19
	For $i = 0 To 19 Step 1
		$remove = Eval("remove" & $i)
		If $remove <> "" Then
			Local $iFileExists = FileExists($remove)
			If $iFileExists Then
				; For debugging
				; MsgBox(48, $appname, "Löschung von Objekt:" & @CRLF & @CRLF & '"' & $remove & '"' & @CRLF & @CRLF & "erfolgt in 20 Sek. oder nach Kilck von OK ...   ", 10)
				; Exit
				Local $iDelete = FileDelete($remove)
				; For debugging
				; If $iDelete Then
				; 	MsgBox(64, $appname, "Löschung von Objekt:" & @CRLF & @CRLF & '"' & $remove & '"' & @CRLF & @CRLF & "erfolgreich !   ", 10)
				; Else
				; 	MsgBox(16, $appname, "Fehler beim Löschen von Objekt:" & @CRLF & @CRLF & '"' & $remove & '"' & " !", 10)
				; EndIf
			EndIf
		EndIf
	Next

EndFunc   ;==>runController

Func cleanupProc()

	;	; First try to close windows named CLOSEWIN0-CLOSEWIN19 softly
	;	For $i = 0 To 19 Step 1
	;		$closewin = Eval("closewin" & $i)
	;		If $closewin <> "" Then
	;			WinClose($closewin)
	;			If $closewinWAIT_bool == "true" Then
	;				WinWaitClose($closewin, "", $closewinTMOUT)
	;			EndIf
	;		EndIf
	;	Next
	;
	;	; Second forced kill processes KILLAPP0-KILLAPP19
	;	For $i = 0 To 19 Step 1
	;		$killapp = Eval("killapp" & $i)
	;		If $killapp <> "" Then
	;			If StringRight($killapp, 4) = ".exe" Then
	;				ProcessClose($killapp)
	;			EndIf
	;		EndIf
	;	Next
	;
	;	; Third try to delete filesystem-objects REMOVE0-REMOVE19
	;	For $i = 0 To 19 Step 1
	;		$remove = Eval("remove" & $i)
	;		If $remove <> "" Then
	;			Local $iFileExists = FileExists($remove)
	;			If $iFileExists Then
	;				; For debugging
	;				; MsgBox(48, $appname, "Löschung von Objekt:" & @CRLF & @CRLF & '"' & $remove & '"' & @CRLF & @CRLF & "erfolgt in 20 Sek. oder nach Kilck von OK ...   ", 10)
	;				; Exit
	;				Local $iDelete = FileDelete($remove)
	;				; For debugging
	;				; If $iDelete Then
	;				; 	MsgBox(64, $appname, "Löschung von Objekt:" & @CRLF & @CRLF & '"' & $remove & '"' & @CRLF & @CRLF & "erfolgreich !   ", 10)
	;				; Else
	;				; 	MsgBox(16, $appname, "Fehler beim Löschen von Objekt:" & @CRLF & @CRLF & '"' & $remove & '"' & " !", 10)
	;				; EndIf
	;			EndIf
	;		EndIf
	;	Next

EndFunc   ;==>cleanupProc
