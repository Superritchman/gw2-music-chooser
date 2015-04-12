;**************************************************************************************************
; Music-Chooser by Superritchman
; Version: 1.0.2
; min AHK-Version: 1.1
;
; # How to use?
;
; 1) Choose 'Windowed Fullscreen' as display resolution
; 2) Equip your instrument
; 3) Press Ctrl+1 and choose a music script
; 4) If you're not already playing, then click somewhere in the Guild Wars window
; 5) Rock like hell \(^o^)/
;
;
; # Hotkeys
;
; Ctrl + 1: Open a dialog to chose a music script to play
; Ctrl + 2: Show/Hide GUI	(work not very well while music is playing)
; Numpad +: Pause your music script
; Numpad -: Abort active music script
; ESC: Close this script (and stop music)
;
; # Some extra infos
; - This script can automatically set your instrument to the middle-octave (does also work for instruments with only two octaves)
; - Once you choose a file, the 'Guild Wars 2' window have to become active to do any further actions.
;
; # GUI settings (feel free to change)
GUIShown := True	; GUI visible at start?		- Default: True
MidOctave := True	; Reset to middle octave	- Default: True
FontSize := 14		; Font-Size of music title 	- Default: 14
SColor := "C94545"	; Font-Color while pausing 	- Default: C94545 (7F7F7F = invisible font)
PColor := "009E5A"	; Font-Color while playing 	- Default: 009E5A (7F7F7F = invisible font)
;
; Code below must not be changed!
;***************************************************************************************************
; Some global settings
#NoEnv
#SingleInstance ignore
DetectHiddenWindows, On
SetTitleMatchMode, 2

; Proof user settings
if (GUIShown = "" || GUIShown is not boolean) 	
	GUIShown := True
if (MidOctave = "" || MidOctave is not boolean) 	
	MidOctave := True	
if (FontSize = "" || FontSize is not integer || FontSize < 1)	
	FontSize := 14	
if (SColor = "" || SColor is not xdigit)	
	SColor := "C94545"	
if (PColor = "" || PColor is not xdigit)
	PColor := "009E5A"

; Draw GUI at the beginning
UpdateGui("", True, GUIShown)

; Ctrl + 1: Open a file chooser to chose your favorite music script
^1::
	FileSelectFile, SelectedFile, 3, , Open a music script (Visit https://gw2mb.com to discover more music scripts), AHK Scripts (*.ahk)
	if SelectedFile <> 
	{
		; Title of the Window, where the music should be played
		WindowTitle := "Guild Wars 2"
		
		SplitPath, SelectedFile, Filename,,, Songname    
		UpdateGui(Songname, MusicPaused := True, GUIShown)	; UpdateGUI (Paused while waiting for start)

		WinWaitActive, %WindowTitle%
		
		; reset to middle octave
		if(MidOctave)
		{
			SendInput {Numpad9}
			Sleep 550
			SendInput {Numpad9}
			Sleep 550
			SendInput {Numpad0} 
			Sleep 500
		}
		
		; Lets rock!
		Run %SelectedFile%,,, MusicPID

		UpdateGui(Songname, MusicPaused := False, GUIShown)	; UpdateGUI (now its playing)

		; Check focus, while playing
		Loop
		{	
			; Music finished playing (or got terminated)
			Process, Exist, %MusicPID%
			if(MusicPID <> ErrorLevel)
			{
				; clear all vars
				SelectedFile := Filename := Songname := MusicPID := ""
				UpdateGui(Songname, MusicPaused, GUIShown)	; UpdateGUI
				return		
			}
					
			; Window lost focus
			IfWinNotActive, %WindowTitle%
			{
				MusicPaused := PauseScript(Filename, True)
				UpdateGui(Songname, MusicPaused, GUIShown)	; UpdateGUI
				WinWaitActive, %WindowTitle%	; Hotkeys stopped until GW 2 is back in focus!
			}
		}
	}
	; redraw the GUI otherwise it will disappear
	UpdateGui("", True, GUIShown)
return

; Ctrl+2 to show GUI
^2::
	GUIShown := !GUIShown
	UpdateGui(Songname, MusicPaused, GUIShown)
return

; (Num +) Plus on numpad: Pause/Resume music
NumpadAdd::	
	if(MusicPID > 0)
	{   	  
	  MusicPaused := PauseScript(Filename, !MusicPaused)
	  UpdateGui(Songname, MusicPaused, GUIShown)	; UpdateGUI
	}
return

; (Num -) Minus on numpad: Terminate music script (to stop playing and/or playing another masterpiece)
NumpadSub::
	if(MusicPID > 0)
	{
		StopMusic(MusicPID)
		SelectedFile := Filename := Songname := MusicPID := ""
		UpdateGui(Songname, MusicPaused, GUIShown)	; UpdateGUI
	}
return

; ESC: Stop the music and close this script
Esc::
	if(MusicPID > 0)
		StopMusic(MusicPID)
	ExitApp
return

; Updating the GUI
UpdateGui(MusicTitle, isPaused, show)
{	
	; Destroy old window (to handle resizing)
	IfWinExist, TransSplashTextWindow	
		Gui, Music:Destroy	
	
	; Update shown window
	if(show) 
	{
		global PColor, SColor, FontSize	
		
		Title := MusicTitle?MusicTitle:"Nothing to play"
		Icon := (isPaused||!MusicTitle)?Chr(59):Chr(52)		
		Color := ((isPaused||!MusicTitle)?SColor:PColor)
		
		; Play/Pause symbol
		Gui, Music:Font, s%FontSize% cBlack norm, Webdings
		Gui, Music:Add, Text, x0 y12, %Icon%
		; Text
		Gui, Music:Font, s%FontSize% c%Color% bold, Comic Sans MS		
		Gui, Music:Add, Text, x18 y10 BackgroundTrans, %Title%

		; Transparent window
		Gui, Music:Color, 7F7F7F
		Gui, Music:+LastFound -Caption +AlwaysOnTop +ToolWindow
		WinSet, TransColor, 7F7F7F
		Gui, Music:Show, xCenter y0 AutoSize NoActivate, TransSplashTextWindow
	}	
}

; Close the music-script
StopMusic(PID)
{
	Process, Exist, %PID%	
	if(PID = ErrorLevel)	
		WinClose, ahk_pid %PID%	
}

; Thanks to RHCP
; http://www.autohotkey.com/board/topic/102235-script-to-deactivateactivate-another-script/?p=634811
PauseScript(ScriptTitle, pauseIt)
{
	if (script_id := WinExist(ScriptTitle " ahk_class AutoHotkey"))
	{
		; Force the script to update its Pause checkmarks.
		SendMessage, 0x211,,,, ahk_id %script_id%  ; WM_ENTERMENULOOP
		SendMessage, 0x212,,,, ahk_id %script_id%  ; WM_EXITMENULOOP		
		; Get script status from its main menu.
		mainMenu := DllCall("GetMenu", "uint", script_id)
		fileMenu := DllCall("GetSubMenu", "uint", mainMenu, "int", 0)
		isPaused := DllCall("GetMenuState", "uint", fileMenu, "uint", 4, "uint", 0x400) >> 3 & 1		
		DllCall("CloseHandle", "uint", fileMenu)
		DllCall("CloseHandle", "uint", mainMenu)
		if (pauseIt && !isPaused) || (!pauseIt && isPaused)
			PostMessage, 0x111, 65403,,, ahk_id %script_id% ; this toggles the current pause state.
	}
	return pauseIt
}