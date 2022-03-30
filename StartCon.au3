#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=res\StartCon.ico
#AutoIt3Wrapper_Outfile=bin\StartCon.exe
#AutoIt3Wrapper_Outfile_x64=bin\StartCon64.exe
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_Res_Comment=Ein Starter fuer externe Programme. Konfiguriert ueber eine INI-Datei mit gleichem Namen der EXE-Datei.
#AutoIt3Wrapper_Res_Description=Ein Starter fuer externe Programme. Konfiguriert ueber eine INI-Datei mit gleichem Namen der EXE-Datei.
#AutoIt3Wrapper_Res_Fileversion=1.0.0.28
#AutoIt3Wrapper_Res_LegalCopyright=Copyright 2017-2022 by Veit Berwig. Lizenzierung unter der GPL 3.0 (Open-Source)
#AutoIt3Wrapper_Res_Language=1031
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#AutoIt3Wrapper_Res_Field=Author|Veit Berwig
#AutoIt3Wrapper_Res_Field=Info|Ein Starter fuer externe Programme. Konfiguriert ueber eine INI-Datei mit gleichem Namen der EXE-Datei.
#AutoIt3Wrapper_Run_Tidy=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

; ########### !!! THIS FILE IS ENCODED IN UTF-8 with BOM !!! ##########
; Author........: Veit Berwig
; Desc..........: Program-Launcher derived fron StartController for
;                 launching programs without commandline-options
; Version.......: 1.0.0.28
; Important Info: We have to do a case sensitive    string-diff with:
;                 If Not ("String1" == "String2") Then ...
;                 We have to do a case in-sensitive string-diff with:
;                 If Not ("String1" <> "String2") Then ...
;                 here !!
;
; == Tests if two strings are equal. Case sensitive.
;    The left and right values are converted to strings if they are
;    not strings already. This operator should only be used if
;    string comparisons need to be case sensitive.
; <> Tests if two values are not equal. Case insensitive	when used
;    with strings. To do a case sensitive not equal comparison use
;    Not ("string1" == "string2")
;

#cs
	;**********************************************************************
	History:

	1.0.0.0 - 1.0.0.23
	-	Old Code

	1.0.0.24 (25.01.2021)
	-	New Code
	-	Strip down the code to only execute a given program with local
		environment by using an ini-filename
	-	File-Creation removed from code.
	-	File-Creation for ini-config-file, when not existent

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
	-	The cleanupProc() was disabled, due to double execution of some
		functions in the main program and twice on exit() by cleanupProc().

	1.0.0.27 (18.01.2022)
	-	Added registry-key creation and deletion.
		Look at "doc\StartCon.txt" for details.
	-	Added logging to eventlog.

	1.0.0.28 (17.03.2022)
	-	The cleanupProc()-function must be enabled, because it is necessary
		when user aborts program by selecting Exit on Tray-Menu. Removed
		duplicated code from runController().
	-	Added boolean-value "Eventlog" into "Main Prefs"-section of INI-file.
		Set "Eventlog" to "true" enables writing to the eventlog, "false"
		disables writing to the eventlog.
	-	Fixed error:
		Now running $launchapp after writing registry-keys in order to
		have a correct environment.

	;**********************************************************************
#ce

#include <File.au3>
#include <String.au3>
#include <Constants.au3>
#include <StringConstants.au3>
#include <GuiConstants.au3>
#include <GUIConstantsEx.au3>
#include <FileConstants.au3>
#include <WinAPI.au3>
#include <Misc.au3>
#include <Date.au3>
#include <EventLog.au3>

; product name
Global $prod_name = "StartCon"

; generate dynamic name-instance from filename
Global $app_name = $prod_name
; retrieve short version of @ScriptName
Global $scriptname_short = StringTrimRight(@ScriptName, 4) ; Remove the 4 rightmost characters from the string.
If Not (StringLen($scriptname_short) = 0) Then
	$app_name = $scriptname_short
EndIf

Global $app_version = "1.0.0.28"
Global $app_copy = "Copyright 2017-2022 Veit Berwig"
; Global $appname = $prod_name & " " & $app_version
Global $appname = $app_name & " " & $app_version
Global $appGUID = $app_name & "-888f6427-5ef6-4678-87b3-722cedf676d7"


Local $PATHENVCLEAN
Global $sEnvPATH = EnvGet("PATH")
Global $pidController = 0
Global $pidController2 = 0

Global $ComSpec, $ComSpec_loc
Global $sControllerpath, $sControllerpath_, $PrgWorkDir, $PrgWorkDirloc, $EnvUpdate_bool, $Eventlog_bool
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

; write to eventlog
Global $_EventError = 1
Global $_EventWarning = 2
Global $_EventInfo = 4

; ###################################################################
; RegWrite()
; Format:			RegWrite ( "keyname" [, "valuename", "type", data] )
;					Key must begin with ...
;					"HKEY_LOCAL_MACHINE" ("HKLM"),
;					"HKEY_USERS" ("HKU"),
;					"HKEY_CURRENT_USER" ("HKCU"),
;					"HKEY_CLASSES_ROOT" ("HKCR"), or
;					"HKEY_CURRENT_CONFIG" ("HKCC")
; Parameters:		"keyname"				name of key
; 					"valuename"	[optional]	name of value
;					"type"		[optional]	type of key:
;						"REG_SZ",
;						"REG_MULTI_SZ",
;						"REG_EXPAND_SZ",
;						"REG_DWORD",
;						"REG_QWORD" or
;						"REG_BINARY"
;					"data" 	[optional]	data in valuename
; Default_Value:	""
; Return values:	1 success
;					0 Error:	- when creation raised an error
;								- set @error neq 0
; 					@error: 1  key could not be opened
; 					@error: 2  main-key not available
; 					@error: 3  no remote-access to registry possible
; 					@error: -1 value could not be opened
; 					@error: -2 type of value not supported
; ###################################################################
Global $reg_write_key
Global $reg_write_key0, $reg_write_key1, $reg_write_key2, $reg_write_key3, $reg_write_key4
Global $reg_write_key5, $reg_write_key6, $reg_write_key7, $reg_write_key8, $reg_write_key9
Global $reg_write_key10, $reg_write_key11, $reg_write_key12, $reg_write_key13, $reg_write_key14
Global $reg_write_key15, $reg_write_key16, $reg_write_key17, $reg_write_key18, $reg_write_key19

Global $reg_write_vname
Global $reg_write_vname0, $reg_write_vname1, $reg_write_vname2, $reg_write_vname3, $reg_write_vname4
Global $reg_write_vname5, $reg_write_vname6, $reg_write_vname7, $reg_write_vname8, $reg_write_vname9
Global $reg_write_vname10, $reg_write_vname11, $reg_write_vname12, $reg_write_vname13, $reg_write_vname14
Global $reg_write_vname15, $reg_write_vname16, $reg_write_vname17, $reg_write_vname18, $reg_write_vname19

Global $reg_write_type
Global $reg_write_type0, $reg_write_type1, $reg_write_type2, $reg_write_type3, $reg_write_type4
Global $reg_write_type5, $reg_write_type6, $reg_write_type7, $reg_write_type8, $reg_write_type9
Global $reg_write_type10, $reg_write_type11, $reg_write_type12, $reg_write_type13, $reg_write_type14
Global $reg_write_type15, $reg_write_type16, $reg_write_type17, $reg_write_type18, $reg_write_type19

Global $reg_write_data
Global $a_reg_write_data ; Array for entries in "REG_MULTI_SZ" in "# Write key with data #" below
Global $reg_write_data0, $reg_write_data1, $reg_write_data2, $reg_write_data3, $reg_write_data4
Global $reg_write_data5, $reg_write_data6, $reg_write_data7, $reg_write_data8, $reg_write_data9
Global $reg_write_data10, $reg_write_data11, $reg_write_data12, $reg_write_data13, $reg_write_data14
Global $reg_write_data15, $reg_write_data16, $reg_write_data17, $reg_write_data18, $reg_write_data19

; ###################################################################
; RegDelete()
; Format:			RegDelete ( "keyname" [, "valuename"] )
;					Key must begin with ...
;					"HKEY_LOCAL_MACHINE" ("HKLM"),
;					"HKEY_USERS" ("HKU"),
;					"HKEY_CURRENT_USER" ("HKCU"),
;					"HKEY_CLASSES_ROOT" ("HKCR"), or
;					"HKEY_CURRENT_CONFIG" ("HKCC")
; Default_Value:	""
; Return values:	1 success
;					0 key / value not existent.
;					2 Error:	- when deletion raised an error
;								- set @error neq 0
; 					@error: 1  key could not be opened
; 					@error: 2  main-key not available
; 					@error: 3  no remote-access to registry possible
; 					@error: -1 value could not be deleted
; 					@error: -2 key / value coud not be deleted
; ###################################################################
Global $reg_del_key
Global $reg_del_key0, $reg_del_key1, $reg_del_key2, $reg_del_key3, $reg_del_key4
Global $reg_del_key5, $reg_del_key6, $reg_del_key7, $reg_del_key8, $reg_del_key9
Global $reg_del_key10, $reg_del_key11, $reg_del_key12, $reg_del_key13, $reg_del_key14
Global $reg_del_key15, $reg_del_key16, $reg_del_key17, $reg_del_key18, $reg_del_key19

Global $reg_del_vname
Global $reg_del_vname0, $reg_del_vname1, $reg_del_vname2, $reg_del_vname3, $reg_del_vname4
Global $reg_del_vname5, $reg_del_vname6, $reg_del_vname7, $reg_del_vname8, $reg_del_vname9
Global $reg_del_vname10, $reg_del_vname11, $reg_del_vname12, $reg_del_vname13, $reg_del_vname14
Global $reg_del_vname15, $reg_del_vname16, $reg_del_vname17, $reg_del_vname18, $reg_del_vname19


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

; PATH of local execution with normal separator (\)
EnvSet("CONTROLLERPATH", $sControllerpath_)

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
	IniWrite($Config_File, "Main Prefs", "Eventlog", "false")

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

	; Write default entries for Registry key- or value creation
	IniWrite($Config_File, "RegWrite", "KEYN0", "")
	IniWrite($Config_File, "RegWrite", "VALN0", "")
	IniWrite($Config_File, "RegWrite", "TYPE0", "")
	IniWrite($Config_File, "RegWrite", "DATA0", "")

	IniWrite($Config_File, "RegWrite", "KEYN1", "")
	IniWrite($Config_File, "RegWrite", "VALN1", "")
	IniWrite($Config_File, "RegWrite", "TYPE1", "")
	IniWrite($Config_File, "RegWrite", "DATA1", "")

	IniWrite($Config_File, "RegWrite", "KEYN2", "")
	IniWrite($Config_File, "RegWrite", "VALN2", "")
	IniWrite($Config_File, "RegWrite", "TYPE2", "")
	IniWrite($Config_File, "RegWrite", "DATA2", "")

	IniWrite($Config_File, "RegWrite", "KEYN3", "")
	IniWrite($Config_File, "RegWrite", "VALN3", "")
	IniWrite($Config_File, "RegWrite", "TYPE3", "")
	IniWrite($Config_File, "RegWrite", "DATA3", "")

	IniWrite($Config_File, "RegWrite", "KEYN4", "")
	IniWrite($Config_File, "RegWrite", "VALN4", "")
	IniWrite($Config_File, "RegWrite", "TYPE4", "")
	IniWrite($Config_File, "RegWrite", "DATA4", "")

	IniWrite($Config_File, "RegWrite", "KEYN5", "")
	IniWrite($Config_File, "RegWrite", "VALN5", "")
	IniWrite($Config_File, "RegWrite", "TYPE5", "")
	IniWrite($Config_File, "RegWrite", "DATA5", "")

	IniWrite($Config_File, "RegWrite", "KEYN6", "")
	IniWrite($Config_File, "RegWrite", "VALN6", "")
	IniWrite($Config_File, "RegWrite", "TYPE6", "")
	IniWrite($Config_File, "RegWrite", "DATA6", "")

	IniWrite($Config_File, "RegWrite", "KEYN7", "")
	IniWrite($Config_File, "RegWrite", "VALN7", "")
	IniWrite($Config_File, "RegWrite", "TYPE7", "")
	IniWrite($Config_File, "RegWrite", "DATA7", "")

	IniWrite($Config_File, "RegWrite", "KEYN8", "")
	IniWrite($Config_File, "RegWrite", "VALN8", "")
	IniWrite($Config_File, "RegWrite", "TYPE8", "")
	IniWrite($Config_File, "RegWrite", "DATA8", "")

	IniWrite($Config_File, "RegWrite", "KEYN9", "")
	IniWrite($Config_File, "RegWrite", "VALN9", "")
	IniWrite($Config_File, "RegWrite", "TYPE9", "")
	IniWrite($Config_File, "RegWrite", "DATA9", "")

	IniWrite($Config_File, "RegWrite", "KEYN10", "")
	IniWrite($Config_File, "RegWrite", "VALN10", "")
	IniWrite($Config_File, "RegWrite", "TYPE10", "")
	IniWrite($Config_File, "RegWrite", "DATA10", "")

	IniWrite($Config_File, "RegWrite", "KEYN11", "")
	IniWrite($Config_File, "RegWrite", "VALN11", "")
	IniWrite($Config_File, "RegWrite", "TYPE11", "")
	IniWrite($Config_File, "RegWrite", "DATA11", "")

	IniWrite($Config_File, "RegWrite", "KEYN12", "")
	IniWrite($Config_File, "RegWrite", "VALN12", "")
	IniWrite($Config_File, "RegWrite", "TYPE12", "")
	IniWrite($Config_File, "RegWrite", "DATA12", "")

	IniWrite($Config_File, "RegWrite", "KEYN13", "")
	IniWrite($Config_File, "RegWrite", "VALN13", "")
	IniWrite($Config_File, "RegWrite", "TYPE13", "")
	IniWrite($Config_File, "RegWrite", "DATA13", "")

	IniWrite($Config_File, "RegWrite", "KEYN14", "")
	IniWrite($Config_File, "RegWrite", "VALN14", "")
	IniWrite($Config_File, "RegWrite", "TYPE14", "")
	IniWrite($Config_File, "RegWrite", "DATA14", "")

	IniWrite($Config_File, "RegWrite", "KEYN15", "")
	IniWrite($Config_File, "RegWrite", "VALN15", "")
	IniWrite($Config_File, "RegWrite", "TYPE15", "")
	IniWrite($Config_File, "RegWrite", "DATA15", "")

	IniWrite($Config_File, "RegWrite", "KEYN16", "")
	IniWrite($Config_File, "RegWrite", "VALN16", "")
	IniWrite($Config_File, "RegWrite", "TYPE16", "")
	IniWrite($Config_File, "RegWrite", "DATA16", "")

	IniWrite($Config_File, "RegWrite", "KEYN17", "")
	IniWrite($Config_File, "RegWrite", "VALN17", "")
	IniWrite($Config_File, "RegWrite", "TYPE17", "")
	IniWrite($Config_File, "RegWrite", "DATA17", "")

	IniWrite($Config_File, "RegWrite", "KEYN18", "")
	IniWrite($Config_File, "RegWrite", "VALN18", "")
	IniWrite($Config_File, "RegWrite", "TYPE18", "")
	IniWrite($Config_File, "RegWrite", "DATA18", "")

	IniWrite($Config_File, "RegWrite", "KEYN19", "")
	IniWrite($Config_File, "RegWrite", "VALN19", "")
	IniWrite($Config_File, "RegWrite", "TYPE19", "")
	IniWrite($Config_File, "RegWrite", "DATA19", "")

	; Write default entries for Registry key- or value deletion
	IniWrite($Config_File, "RegDelete", "KEYN0", "")
	IniWrite($Config_File, "RegDelete", "VALN0", "")

	IniWrite($Config_File, "RegDelete", "KEYN1", "")
	IniWrite($Config_File, "RegDelete", "VALN1", "")

	IniWrite($Config_File, "RegDelete", "KEYN2", "")
	IniWrite($Config_File, "RegDelete", "VALN2", "")

	IniWrite($Config_File, "RegDelete", "KEYN3", "")
	IniWrite($Config_File, "RegDelete", "VALN3", "")

	IniWrite($Config_File, "RegDelete", "KEYN4", "")
	IniWrite($Config_File, "RegDelete", "VALN4", "")

	IniWrite($Config_File, "RegDelete", "KEYN5", "")
	IniWrite($Config_File, "RegDelete", "VALN5", "")

	IniWrite($Config_File, "RegDelete", "KEYN6", "")
	IniWrite($Config_File, "RegDelete", "VALN6", "")

	IniWrite($Config_File, "RegDelete", "KEYN7", "")
	IniWrite($Config_File, "RegDelete", "VALN7", "")

	IniWrite($Config_File, "RegDelete", "KEYN8", "")
	IniWrite($Config_File, "RegDelete", "VALN8", "")

	IniWrite($Config_File, "RegDelete", "KEYN9", "")
	IniWrite($Config_File, "RegDelete", "VALN9", "")

	IniWrite($Config_File, "RegDelete", "KEYN10", "")
	IniWrite($Config_File, "RegDelete", "VALN10", "")

	IniWrite($Config_File, "RegDelete", "KEYN11", "")
	IniWrite($Config_File, "RegDelete", "VALN11", "")

	IniWrite($Config_File, "RegDelete", "KEYN12", "")
	IniWrite($Config_File, "RegDelete", "VALN12", "")

	IniWrite($Config_File, "RegDelete", "KEYN13", "")
	IniWrite($Config_File, "RegDelete", "VALN13", "")

	IniWrite($Config_File, "RegDelete", "KEYN14", "")
	IniWrite($Config_File, "RegDelete", "VALN14", "")

	IniWrite($Config_File, "RegDelete", "KEYN15", "")
	IniWrite($Config_File, "RegDelete", "VALN15", "")

	IniWrite($Config_File, "RegDelete", "KEYN16", "")
	IniWrite($Config_File, "RegDelete", "VALN16", "")

	IniWrite($Config_File, "RegDelete", "KEYN17", "")
	IniWrite($Config_File, "RegDelete", "VALN17", "")

	IniWrite($Config_File, "RegDelete", "KEYN18", "")
	IniWrite($Config_File, "RegDelete", "VALN18", "")

	IniWrite($Config_File, "RegDelete", "KEYN19", "")
	IniWrite($Config_File, "RegDelete", "VALN19", "")

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

; Check for wrtiting into EventLog of the OS
$Eventlog_bool = StringLower(IniRead($Config_File, "Main Prefs", "Eventlog", "false"))
If $Eventlog_bool <> "true" Then
	$Eventlog_bool = "false"
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

; Read objects to remove from filesystem
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

; Read data for Registry key- or value creation
$reg_write_key0 = IniRead($Config_File, "RegWrite", "KEYN0", "")
$reg_write_vname0 = IniRead($Config_File, "RegWrite", "VALN0", "")
$reg_write_type0 = IniRead($Config_File, "RegWrite", "TYPE0", "")
$reg_write_data0 = IniRead($Config_File, "RegWrite", "DATA0", "")

$reg_write_key1 = IniRead($Config_File, "RegWrite", "KEYN1", "")
$reg_write_vname1 = IniRead($Config_File, "RegWrite", "VALN1", "")
$reg_write_type1 = IniRead($Config_File, "RegWrite", "TYPE1", "")
$reg_write_data1 = IniRead($Config_File, "RegWrite", "DATA1", "")

$reg_write_key2 = IniRead($Config_File, "RegWrite", "KEYN2", "")
$reg_write_vname2 = IniRead($Config_File, "RegWrite", "VALN2", "")
$reg_write_type2 = IniRead($Config_File, "RegWrite", "TYPE2", "")
$reg_write_data2 = IniRead($Config_File, "RegWrite", "DATA2", "")

$reg_write_key3 = IniRead($Config_File, "RegWrite", "KEYN3", "")
$reg_write_vname3 = IniRead($Config_File, "RegWrite", "VALN3", "")
$reg_write_type3 = IniRead($Config_File, "RegWrite", "TYPE3", "")
$reg_write_data3 = IniRead($Config_File, "RegWrite", "DATA3", "")

$reg_write_key4 = IniRead($Config_File, "RegWrite", "KEYN4", "")
$reg_write_vname4 = IniRead($Config_File, "RegWrite", "VALN4", "")
$reg_write_type4 = IniRead($Config_File, "RegWrite", "TYPE4", "")
$reg_write_data4 = IniRead($Config_File, "RegWrite", "DATA4", "")

$reg_write_key5 = IniRead($Config_File, "RegWrite", "KEYN5", "")
$reg_write_vname5 = IniRead($Config_File, "RegWrite", "VALN5", "")
$reg_write_type5 = IniRead($Config_File, "RegWrite", "TYPE5", "")
$reg_write_data5 = IniRead($Config_File, "RegWrite", "DATA5", "")

$reg_write_key6 = IniRead($Config_File, "RegWrite", "KEYN6", "")
$reg_write_vname6 = IniRead($Config_File, "RegWrite", "VALN6", "")
$reg_write_type6 = IniRead($Config_File, "RegWrite", "TYPE6", "")
$reg_write_data6 = IniRead($Config_File, "RegWrite", "DATA6", "")

$reg_write_key7 = IniRead($Config_File, "RegWrite", "KEYN7", "")
$reg_write_vname7 = IniRead($Config_File, "RegWrite", "VALN7", "")
$reg_write_type7 = IniRead($Config_File, "RegWrite", "TYPE7", "")
$reg_write_data7 = IniRead($Config_File, "RegWrite", "DATA7", "")

$reg_write_key8 = IniRead($Config_File, "RegWrite", "KEYN8", "")
$reg_write_vname8 = IniRead($Config_File, "RegWrite", "VALN8", "")
$reg_write_type8 = IniRead($Config_File, "RegWrite", "TYPE8", "")
$reg_write_data8 = IniRead($Config_File, "RegWrite", "DATA8", "")

$reg_write_key9 = IniRead($Config_File, "RegWrite", "KEYN9", "")
$reg_write_vname9 = IniRead($Config_File, "RegWrite", "VALN9", "")
$reg_write_type9 = IniRead($Config_File, "RegWrite", "TYPE9", "")
$reg_write_data9 = IniRead($Config_File, "RegWrite", "DATA9", "")

$reg_write_key10 = IniRead($Config_File, "RegWrite", "KEYN10", "")
$reg_write_vname10 = IniRead($Config_File, "RegWrite", "VALN10", "")
$reg_write_type10 = IniRead($Config_File, "RegWrite", "TYPE10", "")
$reg_write_data10 = IniRead($Config_File, "RegWrite", "DATA10", "")

$reg_write_key11 = IniRead($Config_File, "RegWrite", "KEYN11", "")
$reg_write_vname11 = IniRead($Config_File, "RegWrite", "VALN11", "")
$reg_write_type11 = IniRead($Config_File, "RegWrite", "TYPE11", "")
$reg_write_data11 = IniRead($Config_File, "RegWrite", "DATA11", "")

$reg_write_key12 = IniRead($Config_File, "RegWrite", "KEYN12", "")
$reg_write_vname12 = IniRead($Config_File, "RegWrite", "VALN12", "")
$reg_write_type12 = IniRead($Config_File, "RegWrite", "TYPE12", "")
$reg_write_data12 = IniRead($Config_File, "RegWrite", "DATA12", "")

$reg_write_key13 = IniRead($Config_File, "RegWrite", "KEYN13", "")
$reg_write_vname13 = IniRead($Config_File, "RegWrite", "VALN13", "")
$reg_write_type13 = IniRead($Config_File, "RegWrite", "TYPE13", "")
$reg_write_data13 = IniRead($Config_File, "RegWrite", "DATA13", "")

$reg_write_key14 = IniRead($Config_File, "RegWrite", "KEYN14", "")
$reg_write_vname14 = IniRead($Config_File, "RegWrite", "VALN14", "")
$reg_write_type14 = IniRead($Config_File, "RegWrite", "TYPE14", "")
$reg_write_data14 = IniRead($Config_File, "RegWrite", "DATA14", "")

$reg_write_key15 = IniRead($Config_File, "RegWrite", "KEYN15", "")
$reg_write_vname15 = IniRead($Config_File, "RegWrite", "VALN15", "")
$reg_write_type15 = IniRead($Config_File, "RegWrite", "TYPE15", "")
$reg_write_data15 = IniRead($Config_File, "RegWrite", "DATA15", "")

$reg_write_key16 = IniRead($Config_File, "RegWrite", "KEYN16", "")
$reg_write_vname16 = IniRead($Config_File, "RegWrite", "VALN16", "")
$reg_write_type16 = IniRead($Config_File, "RegWrite", "TYPE16", "")
$reg_write_data16 = IniRead($Config_File, "RegWrite", "DATA16", "")

$reg_write_key17 = IniRead($Config_File, "RegWrite", "KEYN17", "")
$reg_write_vname17 = IniRead($Config_File, "RegWrite", "VALN17", "")
$reg_write_type17 = IniRead($Config_File, "RegWrite", "TYPE17", "")
$reg_write_data17 = IniRead($Config_File, "RegWrite", "DATA17", "")

$reg_write_key18 = IniRead($Config_File, "RegWrite", "KEYN18", "")
$reg_write_vname18 = IniRead($Config_File, "RegWrite", "VALN18", "")
$reg_write_type18 = IniRead($Config_File, "RegWrite", "TYPE18", "")
$reg_write_data18 = IniRead($Config_File, "RegWrite", "DATA18", "")

$reg_write_key19 = IniRead($Config_File, "RegWrite", "KEYN19", "")
$reg_write_vname19 = IniRead($Config_File, "RegWrite", "VALN19", "")
$reg_write_type19 = IniRead($Config_File, "RegWrite", "TYPE19", "")
$reg_write_data19 = IniRead($Config_File, "RegWrite", "DATA19", "")

; Read data for Registry key- or value deletion
$reg_del_key0 = IniRead($Config_File, "RegDelete", "KEYN0", "")
$reg_del_vname0 = IniRead($Config_File, "RegDelete", "VALN0", "")

$reg_del_key1 = IniRead($Config_File, "RegDelete", "KEYN1", "")
$reg_del_vname1 = IniRead($Config_File, "RegDelete", "VALN1", "")

$reg_del_key2 = IniRead($Config_File, "RegDelete", "KEYN2", "")
$reg_del_vname2 = IniRead($Config_File, "RegDelete", "VALN2", "")

$reg_del_key3 = IniRead($Config_File, "RegDelete", "KEYN3", "")
$reg_del_vname3 = IniRead($Config_File, "RegDelete", "VALN3", "")

$reg_del_key4 = IniRead($Config_File, "RegDelete", "KEYN4", "")
$reg_del_vname4 = IniRead($Config_File, "RegDelete", "VALN4", "")

$reg_del_key5 = IniRead($Config_File, "RegDelete", "KEYN5", "")
$reg_del_vname5 = IniRead($Config_File, "RegDelete", "VALN5", "")

$reg_del_key6 = IniRead($Config_File, "RegDelete", "KEYN6", "")
$reg_del_vname6 = IniRead($Config_File, "RegDelete", "VALN6", "")

$reg_del_key7 = IniRead($Config_File, "RegDelete", "KEYN7", "")
$reg_del_vname7 = IniRead($Config_File, "RegDelete", "VALN7", "")

$reg_del_key8 = IniRead($Config_File, "RegDelete", "KEYN8", "")
$reg_del_vname8 = IniRead($Config_File, "RegDelete", "VALN8", "")

$reg_del_key9 = IniRead($Config_File, "RegDelete", "KEYN9", "")
$reg_del_vname9 = IniRead($Config_File, "RegDelete", "VALN9", "")

$reg_del_key10 = IniRead($Config_File, "RegDelete", "KEYN10", "")
$reg_del_vname10 = IniRead($Config_File, "RegDelete", "VALN10", "")

$reg_del_key11 = IniRead($Config_File, "RegDelete", "KEYN11", "")
$reg_del_vname11 = IniRead($Config_File, "RegDelete", "VALN11", "")

$reg_del_key12 = IniRead($Config_File, "RegDelete", "KEYN12", "")
$reg_del_vname12 = IniRead($Config_File, "RegDelete", "VALN12", "")

$reg_del_key13 = IniRead($Config_File, "RegDelete", "KEYN13", "")
$reg_del_vname13 = IniRead($Config_File, "RegDelete", "VALN13", "")

$reg_del_key14 = IniRead($Config_File, "RegDelete", "KEYN14", "")
$reg_del_vname14 = IniRead($Config_File, "RegDelete", "VALN14", "")

$reg_del_key15 = IniRead($Config_File, "RegDelete", "KEYN15", "")
$reg_del_vname15 = IniRead($Config_File, "RegDelete", "VALN15", "")

$reg_del_key16 = IniRead($Config_File, "RegDelete", "KEYN16", "")
$reg_del_vname16 = IniRead($Config_File, "RegDelete", "VALN16", "")

$reg_del_key17 = IniRead($Config_File, "RegDelete", "KEYN17", "")
$reg_del_vname17 = IniRead($Config_File, "RegDelete", "VALN17", "")

$reg_del_key18 = IniRead($Config_File, "RegDelete", "KEYN18", "")
$reg_del_vname18 = IniRead($Config_File, "RegDelete", "VALN18", "")

$reg_del_key19 = IniRead($Config_File, "RegDelete", "KEYN19", "")
$reg_del_vname19 = IniRead($Config_File, "RegDelete", "VALN19", "")


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

; #######################################################
; # Check formats of registry creation- and removal-entries
; #######################################################
; # Regulatories for string and data values
; #######################################################
; $reg_write_key    0-19
;   - FQN of key
;   - MUST BEGIN WITH "HKLM" or "HKU" "HKCU" "HKCR" "HKCC" or
;     "HKLM64" or "HKU64" "HKCU64" "HKCR64" "HKCC64"
;   - MUST NOT BEGIN WITH "\\" (Network access prevention)
; $reg_write_vname  0-19
; $reg_write_type   0-19
;   - MUST CONTAIN "REG_BINARY" or "REG_SZ" or "REG_MULTI_SZ"
;     or "REG_EXPAND_SZ" or "REG_QWORD" or "REG_DWORD"
; $reg_write_data   0-19
; $reg_del_key      0-19
;   - FQN of key
;   - MUST BEGIN WITH "HKLM" or "HKU" "HKCU" "HKCR" "HKCC" or
;     "HKLM64" or "HKU64" "HKCU64" "HKCR64" "HKCC64"
;   - MUST NOT BEGIN WITH "\\" (Network access prevention)
; $reg_del_vname    0-19
; #######################################################

; Check format of $reg_xxx_xxx0-$reg_xxx_xxx19 vars
For $i = 0 To 19 Step 1
	$reg_write_key = Eval("reg_write_key" & $i)
	$reg_write_vname = Eval("reg_write_vname" & $i)
	$reg_write_type = Eval("reg_write_type" & $i)
	$reg_write_data = Eval("reg_write_data" & $i)
	$reg_del_key = Eval("reg_del_key" & $i)
	$reg_del_vname = Eval("reg_del_vname" & $i)

	; ########################
	; # Check $reg_write_key
	; ########################
	If $reg_write_key <> "" Then
		If StringLen($reg_write_key) > 256 Then
			MsgBox(64, $appname, "Eine KEYN-Variable in der Sektion " & """" & "[RegWrite]" & """" & ":" & @CRLF & @CRLF & "KEYN0-KEYN19" & @CRLF & @CRLF & "ist grösser als 256 Zeichen !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
			Exit
		EndIf

		If StringLen($reg_write_key) < 5 Then
			MsgBox(64, $appname, "Eine KEYN-Variable in der Sektion " & """" & "[RegWrite]" & """" & ":" & @CRLF & @CRLF & "KEYN0-KEYN19" & @CRLF & @CRLF & "ist kleiner als 5 Zeichen !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
			Exit
		EndIf

		If Not StringInStr(StringLeft($reg_write_key, 4), "HKLM", $STR_CASESENSE, 1) > 0 Then
			If Not StringInStr(StringLeft($reg_write_key, 4), "HKCU", $STR_CASESENSE, 1) > 0 Then
				If Not StringInStr(StringLeft($reg_write_key, 4), "HKCR", $STR_CASESENSE, 1) > 0 Then
					If Not StringInStr(StringLeft($reg_write_key, 4), "HKCC", $STR_CASESENSE, 1) > 0 Then
						If Not StringInStr(StringLeft($reg_write_key, 4), "HKU", $STR_CASESENSE, 1) > 0 Then
							MsgBox(64, $appname, "Eine KEYN-Variable in der Sektion " & """" & "[RegWrite]" & """" & ":" & @CRLF & @CRLF & "KEYN0-KEYN19" & @CRLF & @CRLF & "beginnt nicht mit der Zeichenfolge (GROSS):" & @CRLF & "HKLM, HKCU, HKCR, HKCC oder HKU !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
							Exit
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf

		; ########################
		; # Check $reg_write_vname
		; ########################
		If $reg_write_vname <> "" Then
			If StringLen($reg_write_vname) > 256 Then
				MsgBox(64, $appname, "Eine VALN-Variable in der Sektion " & """" & "[RegWrite]" & """" & ":" & @CRLF & @CRLF & "VALN0-VALN19" & @CRLF & @CRLF & "ist grösser als 256 Zeichen !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
				Exit
			EndIf
			; Else
			; Write default value
		EndIf

		; ########################
		; # Check $reg_write_type
		; ########################

		; Not necessary to check lower limit here ...
		; If StringLen($reg_write_type) < 6 Then
		; 	MsgBox(64, $appname, "Eine TYPE-Variable in der Sektion " & """" & "[RegWrite]" & """" & ":" & @CRLF & @CRLF & "KEYN0-KEYN19" & @CRLF & @CRLF & "ist kleiner als 6 Zeichen !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
		; 	Exit
		; EndIf

		If $reg_write_type <> "" Then
			If StringLen($reg_write_type) > 256 Then
				MsgBox(64, $appname, "Eine TYPE-Variable in der Sektion " & """" & "[RegWrite]" & """" & ":" & @CRLF & @CRLF & "TYPE0-TYPE19" & @CRLF & @CRLF & "ist grösser als 256 Zeichen !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
				Exit
			EndIf
			If StringCompare($reg_write_type, "REG_BINARY", $STR_CASESENSE) <> 0 Then
				If StringCompare($reg_write_type, "REG_SZ", $STR_CASESENSE) <> 0 Then
					If StringCompare($reg_write_type, "REG_MULTI_SZ", $STR_CASESENSE) <> 0 Then
						If StringCompare($reg_write_type, "REG_EXPAND_SZ", $STR_CASESENSE) <> 0 Then
							If StringCompare($reg_write_type, "REG_QWORD", $STR_CASESENSE) <> 0 Then
								If StringCompare($reg_write_type, "REG_DWORD", $STR_CASESENSE) <> 0 Then
									MsgBox(64, $appname, "Eine TYPE-Variable in der Sektion " & """" & "[RegWrite]" & """" & ":" & @CRLF & @CRLF & "TYPE0-TYPE19" & @CRLF & @CRLF & "enthält nicht die Zeichenfolge:" & @CRLF & "REG_BINARY, REG_SZ, REG_MULTI_SZ, REG_EXPAND_SZ, REG_QWORD oder REG_DWORD !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
								EndIf
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf

		; ########################
		; # Check $reg_write_data
		; ########################

		; ##########################################################################################
		; # ToDo: $reg_write_data not checked yet, because of binary and multi-string complexity !!!
		; ##########################################################################################

	EndIf

	; ########################
	; # Check $reg_del_key
	; ########################
	If $reg_del_key <> "" Then
		If StringLen($reg_del_key) > 256 Then
			MsgBox(64, $appname, "Eine KEYN-Variable in der Sektion " & """" & "[RegDelete]" & """" & ":" & @CRLF & @CRLF & "KEYN0-KEYN19" & @CRLF & @CRLF & "ist grösser als 256 Zeichen !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
			Exit
		EndIf

		If StringLen($reg_del_key) < 5 Then
			MsgBox(64, $appname, "Eine KEYN-Variable in der Sektion " & """" & "[RegWrite]" & """" & ":" & @CRLF & @CRLF & "KEYN0-KEYN19" & @CRLF & @CRLF & "ist kleiner als 5 Zeichen !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
			Exit
		EndIf

		If Not StringInStr(StringLeft($reg_del_key, 4), "HKLM", $STR_CASESENSE, 1) > 0 Then
			If Not StringInStr(StringLeft($reg_del_key, 4), "HKCU", $STR_CASESENSE, 1) > 0 Then
				If Not StringInStr(StringLeft($reg_del_key, 4), "HKCR", $STR_CASESENSE, 1) > 0 Then
					If Not StringInStr(StringLeft($reg_del_key, 4), "HKCC", $STR_CASESENSE, 1) > 0 Then
						If Not StringInStr(StringLeft($reg_del_key, 4), "HKU", $STR_CASESENSE, 1) > 0 Then
							MsgBox(64, $appname, "Eine KEYN-Variable in der Sektion " & """" & "[RegDelete]" & """" & ":" & @CRLF & @CRLF & "KEYN0-KEYN19" & @CRLF & @CRLF & "beginnt nicht mit der Zeichenfolge:" & @CRLF & "HKLM, HKCU, HKCR, HKCC oder HKU !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
							Exit
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf


		; ########################
		; # Check $reg_del_vname
		; ########################
		If $reg_del_vname <> "" Then
			If StringLen($reg_del_vname) > 256 Then
				MsgBox(64, $appname, "Eine VALN-Variable in der Sektion " & """" & "[RegDelete]" & """" & ":" & @CRLF & @CRLF & "VALN0-VALN19" & @CRLF & @CRLF & "ist grösser als 256 Zeichen !" & @CRLF & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 20)
				Exit
			EndIf
		EndIf

	EndIf
Next

; ------------ CHECK FILES

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


Func EventWrite($type = 4, $GHeader = $app_name, $GMessage = "   ")
	; #include <EventLog.au3>

	; Local $hEventLog, $aData = [354, 0x4A, 0x65, 0x64, 0x65, 0x73, 0x20, 0x43, 0x6F, 0x6D, 0x70, 0x75, 0x74, 0x65, 0x72, 0x70, 0x72, 0x6F, 0x67, 0x72, 0x61, 0x6D, 0x6D, 0x20, 0x62, 0x65, 0x73, 0x69, 0x74, 0x7A, 0x74, 0x20, 0x28, 0x6D, 0x69, 0x6E, 0x64, 0x65, 0x73, 0x74, 0x65, 0x6E, 0x73, 0x29, 0x20, 0x7A, 0x77, 0x65, 0x69, 0x20, 0x5A, 0x77, 0x65, 0x63, 0x6B, 0x65, 0x3A, 0x20, 0x45, 0x69, 0x6E, 0x65, 0x6E, 0x20, 0x66, 0x75, 0x65, 0x72, 0x20, 0x64, 0x65, 0x6E, 0x20, 0x65, 0x73, 0x20, 0x67, 0x65, 0x73, 0x63, 0x68, 0x72, 0x69, 0x65, 0x62, 0x65, 0x6E, 0x20, 0x77, 0x75, 0x72, 0x64, 0x65, 0x20, 0x75, 0x6E, 0x64, 0x20, 0x65, 0x69, 0x6E, 0x65, 0x6E, 0x20, 0x61, 0x6E, 0x64, 0x65, 0x72, 0x65, 0x6E, 0x2C, 0x20, 0x66, 0x75, 0x65, 0x72, 0x20, 0x64, 0x65, 0x6E, 0x20, 0x65, 0x73, 0x20, 0x6E, 0x69, 0x63, 0x68, 0x74, 0x20, 0x67, 0x65, 0x73, 0x63, 0x68, 0x72, 0x69, 0x65, 0x62, 0x65, 0x6E, 0x20, 0x77, 0x75, 0x72, 0x64, 0x65, 0x2E, 0x20, 0x28, 0x41, 0x6C, 0x61, 0x6E, 0x20, 0x4A, 0x2E, 0x20, 0x50, 0x65, 0x72, 0x6C, 0x69, 0x73, 0x20, 0x2F, 0x20, 0x45, 0x70, 0x69, 0x67, 0x72, 0x61, 0x6D, 0x73, 0x20, 0x69, 0x6E, 0x20, 0x50, 0x72, 0x6F, 0x67, 0x72, 0x61, 0x6D, 0x6D, 0x69, 0x6E, 0x67, 0x20, 0x23, 0x31, 0x36, 0x2E, 0x29, 0x2C, 0x20, 0x68, 0x74, 0x74, 0x70, 0x73, 0x3A, 0x2F, 0x2F, 0x64, 0x65, 0x2E, 0x77, 0x69, 0x6B, 0x69, 0x70, 0x65, 0x64, 0x69, 0x61, 0x2E, 0x6F, 0x72, 0x67, 0x2F, 0x77, 0x69, 0x6B, 0x69, 0x2F, 0x41, 0x6C, 0x61, 0x6E, 0x5F, 0x4A, 0x2E, 0x5F, 0x50, 0x65, 0x72, 0x6C, 0x69, 0x73, 0x2C, 0x20, 0x68, 0x74, 0x74, 0x70, 0x3A, 0x2F, 0x2F, 0x63, 0x70, 0x73, 0x63, 0x2E, 0x79, 0x61, 0x6C, 0x65, 0x2E, 0x65, 0x64, 0x75, 0x2F, 0x65, 0x70, 0x69, 0x67, 0x72, 0x61, 0x6D, 0x73, 0x2D, 0x70, 0x72, 0x6F, 0x67, 0x72, 0x61, 0x6D, 0x6D, 0x69, 0x6E, 0x67, 0x2C, 0x20, 0x68, 0x74, 0x74, 0x70, 0x3A, 0x2F, 0x2F, 0x77, 0x77, 0x77, 0x2E, 0x63, 0x73, 0x2E, 0x79, 0x61, 0x6C, 0x65, 0x2E, 0x65, 0x64, 0x75, 0x2F, 0x68, 0x6F, 0x6D, 0x65, 0x73, 0x2F, 0x70, 0x65, 0x72, 0x6C, 0x69, 0x73, 0x2D, 0x61, 0x6C, 0x61, 0x6E, 0x2F, 0x71, 0x75, 0x6F, 0x74, 0x65, 0x73, 0x2E, 0x68, 0x74, 0x6D, 0x6C, 0x20, 0x28, 0x46, 0x75, 0x63, 0x6B, 0x20, 0x57, 0x69, 0x6E, 0x64, 0x6F, 0x77, 0x73, 0x21, 0x29]
	Local $hEventLog, $aData = [9, 0x43, 0x6F, 0x76, 0x65, 0x72, 0x20, 0x6D, 0x65, 0x21]
	$hEventLog = _EventLog__Open("", $GHeader)

	; _EventLog__Report(HANDLE, TYPE, CATEGORY, EVENTID, USERNAME, DESCRIPTION/MESSAGE, DATA)
	;     TYPE: $_EventError = 1 , $_EventWarning = 2 , $_EventInfo = 4 ,
	; CATEGORY: 0 - None , 1 - Devices , 2 - Disk , 3 - Printers ,
	;           4 - Services , 5 - Shell , 6 - System , 7 - Network

	; Using an "EventID" of "65535" (MAXVAL of 16-bit WORD) in "Cathegory" "0"
	; (None) will prevent us from a false interpretation of an already registered
	; "EventID", so Microsoft Windows will do its f@#*ing s#*t of messages like:
	; "The description for event ID 65535 from source ... could not be found ..."
	; ignore this stupid stuff ..."
	_EventLog__Report($hEventLog, $type, 0, 65535, "", $GMessage, $aData)
	_EventLog__Close($hEventLog)
EndFunc   ;==>EventWrite

Func runController()

	If $dontcheckpath = "false" Then
		If Not FileExists($launchapp) Then
			MsgBox(64, $appname, "In dem Verzeichnis:" & @CRLF & $sControllerpath_ & @CRLF & "konnte die Datei:" & @CRLF & @CRLF & '"' & $launchapp & '"' & @CRLF & @CRLF & "nicht gefunden werden !" & @CRLF & "Bitte bearbeiten Sie die INI-Datei ...     ", 10)
			Exit
		EndIf
	EndIf

	; Write Registry-Keys here, if supplied BEFORE LAUNCHING ...
	For $i = 0 To 19 Step 1
		$reg_write_key = Eval("reg_write_key" & $i)
		$reg_write_vname = Eval("reg_write_vname" & $i)
		$reg_write_type = Eval("reg_write_type" & $i)
		$reg_write_data = Eval("reg_write_data" & $i)

		If $reg_write_key <> "" Then
			If $reg_write_vname <> "" Then
				; ###################################################
				; RegWrite ( "keyname" [, "valuename", "type", value] )
				; Success:		1
				; Error: 		0
				;				Deletion raises an error with @error <> 0:
				;				@error: 1 = cannot open key
				;				@error: 2 = no access to main-key (rights ?)
				;				@error: 3 = no remote access to registry
				;				@error:-1 = value could not be deleted
				;				@error:-2 = key or value could not be deleted
				; ###################################################
				If $reg_write_type <> "" Then
					If $reg_write_data <> "" Then
						; #####################
						; # Write key with data
						; #####################
						; When string contains @LF AND is "REG_MULTI_SZ"
						If StringInStr($reg_write_data, "@LF", $STR_CASESENSE, 1) > 0 And StringCompare($reg_write_type, "REG_MULTI_SZ", $STR_CASESENSE) = 0 Then
							; Split string into array-elements
							$aArray = StringSplit($reg_write_data, '@LF', $STR_ENTIRESPLIT)
							For $i = 1 To $aArray[0]
								$a_reg_write_data &= $aArray[$i] & @LF
							Next
							; Remove last @LF from string, if existent
							; https://www.autoitscript.com/forum/topic/144770-does-filereadtoarray-function-correctly/?tab=comments#comment-1021605
							If StringRight($a_reg_write_data, 1) = @LF Then
								$a_reg_write_data = StringTrimRight($a_reg_write_data, 1)
							EndIf
							; # DEBUG #
							; MsgBox($MB_SYSTEMMODAL, "Info", "@LF AND REG_MULTI_SZ string detected !" & @CRLF & "Writing value in ..." & @CRLF & $reg_write_key & @CRLF & """" & $a_reg_write_data & """", 10)
							Local $i_RegWrite = RegWrite($reg_write_key, $reg_write_vname, $reg_write_type, $a_reg_write_data)
							If $i_RegWrite <> 1 Then
								If $Eventlog_bool <> "false" Then EventWrite($_EventError, $app_name, "FEHLER beim Schreiben des Wertes:" & @CRLF & """" & $reg_write_vname & """" & @CRLF & "... unter dem Schlüssel ..." & @CRLF & """" & $reg_write_key & """" & @CRLF & "... bitte INI-Datei prüfen (Rechte ?) !")
							Else
								If $Eventlog_bool <> "false" Then EventWrite($_EventInfo, $app_name, "Der Wert:" & @CRLF & """" & $reg_write_vname & """" & @CRLF & "... unter dem Schlüssel ..." & @CRLF & """" & $reg_write_key & """" & @CRLF & "... wurde geschrieben !")
							EndIf
							; EndIf
						Else
							; # DEBUG #
							; MsgBox($MB_SYSTEMMODAL, "Info", "NO @LF or NO REG_MULTI_SZ string detected !" & @CRLF & "Writing value in ..." & @CRLF & $reg_write_key & @CRLF & "... without LINEFEED separations.", 10)
							Local $i_RegWrite = RegWrite($reg_write_key, $reg_write_vname, $reg_write_type, $reg_write_data)
							If $i_RegWrite <> 1 Then
								If $Eventlog_bool <> "false" Then EventWrite($_EventError, $app_name, "FEHLER beim Schreiben des Wertes:" & @CRLF & """" & $reg_write_vname & """" & @CRLF & "... unter dem Schlüssel ..." & @CRLF & """" & $reg_write_key & """" & @CRLF & "... bitte INI-Datei prüfen (Rechte ?) !")
							Else
								If $Eventlog_bool <> "false" Then EventWrite($_EventInfo, $app_name, "Der Wert:" & @CRLF & """" & $reg_write_vname & """" & @CRLF & "... unter dem Schlüssel ..." & @CRLF & """" & $reg_write_key & """" & @CRLF & "... wurde geschrieben !")
							EndIf
						EndIf
					EndIf
				EndIf
			Else
				; #####################
				; # Write Default Value
				; #####################
				If $reg_write_type <> "" Then
					If $reg_write_data <> "" Then
						Local $i_RegWrite = RegWrite($reg_write_key, "", $reg_write_type, $reg_write_data)
						If $i_RegWrite <> 1 Then
							If $Eventlog_bool <> "false" Then EventWrite($_EventError, $app_name, "FEHLER beim Schreiben des (Standard)-Wertes ..." & @CRLF & "... unter dem Schlüssel ..." & @CRLF & """" & $reg_write_key & """" & @CRLF & "... bitte INI-Datei prüfen (Rechte ?) !")
						Else
							If $Eventlog_bool <> "false" Then EventWrite($_EventInfo, $app_name, "Der (Standard)-Wert ..." & @CRLF & "... unter dem Schlüssel ..." & @CRLF & """" & $reg_write_key & """" & @CRLF & "... wurde geschrieben !")
						EndIf
					EndIf
				Else
					If Not $reg_write_data <> "" Then
						; ################
						; # Write only key
						; ################
						Local $i_RegWrite = RegWrite($reg_write_key)
						If $i_RegWrite <> 1 Then
							If $Eventlog_bool <> "false" Then EventWrite($_EventError, $app_name, "FEHLER beim Schreiben des Schlüssels ..." & @CRLF & """" & $reg_write_key & """" & @CRLF & "... bitte INI-Datei prüfen (Rechte ?) !")
						Else
							If $Eventlog_bool <> "false" Then EventWrite($_EventInfo, $app_name, "Der Schlüssel ..." & @CRLF & """" & $reg_write_key & """" & @CRLF & "... wurde geschrieben !")
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	Next

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

EndFunc   ;==>runController

; When Exit is selected in Tray-Menu, the cleanup-code above will never
; be used, because script aborts. So we have to use this function
; by "OnAutoItExitRegister" above.
Func cleanupProc()

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

	; Delete Registry-Keys here, if supplied ...
	For $i = 0 To 19 Step 1
		$reg_del_key = Eval("reg_del_key" & $i)
		$reg_del_vname = Eval("reg_del_vname" & $i)

		If $reg_del_key <> "" Then
			If $reg_del_vname <> "" Then
				; ###################################################
				; RegDelete ( "keyname" [, "valuename"] )
				; Success:		1
				; NonExistent:	0
				; Error: 		2
				;				Deletion raises an error with @error <> 0:
				;				@error: 1 = cannot open key
				;				@error: 2 = no access to main-key (rights ?)
				;				@error: 3 = no remote access to registry
				;				@error:-1 = value could not be deleted
				;				@error:-2 = key or value could not be deleted
				; ###################################################
				Local $i_RegDelete = RegDelete($reg_del_key, $reg_del_vname)
				If $i_RegDelete <> 1 Then
					If $Eventlog_bool <> "false" Then EventWrite($_EventInfo, $app_name, "Der Wert:" & @CRLF & """" & $reg_del_vname & """" & @CRLF & "... unter dem Schlüssel ..." & @CRLF & """" & $reg_del_key & """" & @CRLF & "... konnte nicht gelöscht werden (schon gelöscht ?) !")
				Else
					If $Eventlog_bool <> "false" Then EventWrite($_EventInfo, $app_name, "Der Wert:" & @CRLF & """" & $reg_del_vname & """" & @CRLF & "... unter dem Schlüssel ..." & @CRLF & """" & $reg_del_key & """" & @CRLF & "... wurde gelöscht !")
				EndIf
			Else
				Local $i_RegDelete = RegDelete($reg_del_key)
				If $i_RegDelete <> 1 Then
					If $Eventlog_bool <> "false" Then EventWrite($_EventInfo, $app_name, "Der Schlüssel:" & @CRLF & """" & $reg_del_key & """" & @CRLF & "... konnte nicht gelöscht werden (schon gelöscht ?) !")
				Else
					If $Eventlog_bool <> "false" Then EventWrite($_EventInfo, $app_name, "Der Schlüssel:" & @CRLF & """" & $reg_del_key & """" & @CRLF & "... wurde gelöscht !")
				EndIf
			EndIf
		EndIf
	Next

EndFunc   ;==>cleanupProc
