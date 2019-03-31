; 0.1 - Acer 2019/03/22 03:43
; 0.2 - Acer 2019/03/27 09:35

; script slower <file onset>
; ============================
; SetBatchLines, 1 ; set for lines of execution within one delay
; SetTimer, sleepLabel, 5
; ============================



; script slower <file offset>
; ============================
; sleepLabel:
; sleep 100 ; set for line delay time
; return
; ============================


; ListVars
; Pause

; SetWorkingDir, DirName

; SetWinDelay
; SetKeyDelay [, Delay, PressDuration, Play]
; SetMouseDelay
; SetDefaultMouseSpeed, Speed
 
; #Include
; #Persistent
; #NoTrayIcon

; ============================================================================ ;
;                                     Init                                     ;
; ============================================================================ ;
#WinActivateForce
SendMode Input
CoordMode, Caret, Screen
; SetTitleMatchMode , 2

PredListWin_shift_Y := 35

requestInterval := 100
requestTimeout := 400
requestFromNchar := 2
isSent := 0


searchEng := ""
nWord2Google := 3
nWordFromGoogle := 2

nWord2Netspeak:= 3
nWordFromNetspeak := *


NormalKeyList := "a`nb`nc`nd`ne`nf`ng`nh`ni`nj`nk`nl`nm`nn`no`np`nq`nr`ns`nt`nu`nv`nw`nx`ny`nz`n'`n""`n*" ;list of key names separated by `n that make up words in upper and lower case variants
NumberKeyList := "1`n2`n3`n4`n5`n6`n7`n8`n9`n0" ;list of key names separated by `n that make up words as well as their numpad equivalents
ResetKeyList := "Esc`nHome`nPGUP`nPGDN`nEnd`nLeft`nRight`nRButton`nMButton`n,`n.`n/`n[`n]`n;`n\`n-`n="  ;list of key names separated by `n that cause suggestions to reset

CurrentChar := ""
nCurrentChar := 0
nCurrentWord := 0
LastChar := ""
predictions := ""

SelectedRow := 1
SelectedText := ""
requesting := 0
initCap := 0

Gui, PredList:new, -MinimizeBox -MaximizeBox -SysMenu -Caption -AlwaysOnTop -0xC40000 +HwndhPredListWin 
Gui, Add, ListView, x0 y0 w350 r11 -Hdr -Multi AltSubmit hwndhPredList viPredList, Index|Prediction
Gui, Add, Button, Hidden Default gPredList_OK, OK
Gui, Show, AutoSize Hide, PredList

SetHotkeys(NormalKeyList, NumberKeyList, ResetKeyList)
whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
; ============================================================================ ;

; ============================================================================ ;
;                               Prediction List                                ;
; ============================================================================ ;
PredList_Update_CurrentChar:
    Gui, PredList:Default
    LV_Modify(1, "select", "", CurrentChar)
return
    
    
PredList_Update:
    Gui, PredList:Default
    GuiControl, -Redraw, hPredList
    LV_Delete()
    LV_Add("select",, CurrentChar)
    if (predictions = 0)
    {
        LV_Add("",, "Connecting...")
        return
    }
    else if (predictions <> "")
    {
        for key, val in predictions
        {
            if (nonRequest = "")
                LV_Add("", Mod(key, 10), val)
            else
                LV_Add("", Mod(key, 10), nonRequest . " " . val)
        }
            
        ;~ loop, Parse, predictions, |
        ;~ {
            ;~ if (A_Index >= 2) & (A_LoopField <> "")
                ;~ LV_Add("", Mod(A_Index-1, 10), A_LoopField)
        ;~ }
        LV_ModifyCol()
    }
    GuiControl, +Redraw, hPredList
return


PredList_MoveSelectedRow:
    Gui, PredList:Default
    LV_Modify(SelectedRow, "Select")
return


PredList_ExtractSelection:
    Gui, PredList:Default
    iSelection := LV_GetNext(0)
    LV_GetText(SelectedText, iSelection, 2)
return


PredList_OK:
    gosub, PredList_ExtractSelection
    if (initCap)
    {
        initc := SubStr(SelectedText, 1, 1)
        StringUpper, initc, initc
        SelectedText := initc . SubStr(SelectedText, 2)
    }
        
    Clipboard := SelectedText
    nBack := nCurrentChar
    gosub, PredList_reset
    Send, {BackSpace %nBack%}
    Send, ^v
return


; ============================================================================ ;
;                                     Reset                                    ;
; ============================================================================ ;
PredList_reset_para:
    SetTimer, requestTimer, Delete
    SelectedRow := 1
    CurrentChar := ""
    nCurrentChar := 0
    LastChar := ""
    SelectedText := "" 
    isSent := 0
    initCap := 0
return

PredList_reset_win:
    Gui, PredList:Default
    LV_Delete()
    WinSet, AlwaysOnTop, Off, ahk_id %hPredListWin%
    WinHide, ahk_id %hPredListWin%
    ;~ WinActivate, ahk_id %WorkingWin%
return

PredList_reset:
    gosub, PredList_reset_para
    gosub, PredList_reset_win
return

; ============================================================================ ;
;                                    Key in                                    ;
; ============================================================================ ;

SetHotkeys(NormalKeyList, NumberKeyList, ResetKeyList)
{
    Loop, Parse, NormalKeyList, `n
    {
        Hotkey, ~%A_LoopField%, NormalKey, UseErrorLevel
        Hotkey, ~+%A_LoopField%, ShiftedKey, UseErrorLevel
    }

    Loop, Parse, NumberKeyList, `n
    {
        Hotkey, ~%A_LoopField%, NormalKey, UseErrorLevel
        Hotkey, ~+%A_LoopField%, PredList_reset, UseErrorLevel
    }

    ;~ Loop, Parse, OtherKeyList, `n
        ;~ Hotkey, ~%A_LoopField%, Key, UseErrorLevel

    Loop, Parse, ResetKeyList, `n
        Hotkey, ~*%A_LoopField%, PredList_reset, UseErrorLevel
        Hotkey, ~*+%A_LoopField%, PredList_reset, UseErrorLevel

    ;~ Hotkey, IfWinExist, AutoComplete ahk_class AutoHotkeyGUI
    ;~ Loop, Parse, TriggerKeyList, `n
        ;~ Hotkey, %A_LoopField%, CompleteWord, UseErrorLevel
}


NormalKey:
    CurrentChar .= SubStr(A_ThisHotkey, 0)
    gosub, KeyPress
return


ShiftedKey:
    if (nCurrentChar = 0)
        initCap := 1
    Char := SubStr(A_ThisHotkey, 3)
    StringUpper, Char, Char
    CurrentChar .= Char
    Gosub, KeyPress
Return

;~ ShiftKey:
    ;~ CurrentChar .= SubStr(A_ThisHotkey, 0)
    ;~ gosub, KeyPress
;~ return

~Space::
    if (nCurrentChar <=0)
        return
    CurrentChar .= " "
    gosub, KeyPress
return


KeyPress:
    nCurrentChar ++
    if (nCurrentChar = 1) {   
    ; if it's first word, open the window
        WorkingWin := A
        WinShow, ahk_id %hPredListWin%
        WinSet, AlwaysOnTop, on, ahk_id %hPredListWin%
        WinSet, Style, -0xC00000, ahk_id %hPredListWin%
        WinGetPos,,, win_w, win_h, ahk_id %hPredListWin%
        if (A_CaretX = "")
        {
            WinPosi_X := A_ScreenWidth - win_w
            WinPosi_Y := A_ScreenHeight - win_h - 30
        }            
        else
        {
            WinPosi_X := A_CaretX
            WinPosi_Y := A_CaretY + PredListWin_shift_Y
            if ((A_CaretX + win_w) > A_ScreenWidth)
                WinPosi_X := A_ScreenWidth-win_w
            
            if ((A_CaretY + win_h + PredListWin_shift_Y) > (A_ScreenHeight))
                WinPosi_Y := A_CaretY - win_h - PredListWin_shift_Y
        }
        WinMove, ahk_id %hPredListWin%,, WinPosi_X, WinPosi_Y
        
        LV_Add("select",, CurrentChar)        
    }
    
    gosub, PredList_Update_CurrentChar
    
    if (nCurrentChar = requestFromNchar)
    {
        SetTimer, requestTimer, -1       
    }
Return


~BackSpace::
    CurrentChar := SubStr(CurrentChar, 1, -1)
    nCurrentChar --
    if (nCurrentChar <= 0)
    {
        gosub, PredList_reset        
    }
    else 
    {
        gosub, PredList_Update_CurrentChar
    }
Return


Up::
    if (CurrentChar = "")
    {
        Send, {Up}
    }
    else
    {
        WinActivate, ahk_id %hPredListWin%
        SelectedRow -= 1
        if (SelectedRow <= 0)
            SelectedRow := 11
        gosub, PredList_MoveSelectedRow
    }
return

Down::
    if (CurrentChar = "")
    {
        Send, {Down}
    }
    else
    {
        WinActivate, ahk_id %hPredListWin%
        SelectedRow += 1
        if (SelectedRow > 11)
            SelectedRow := 1
        gosub, PredList_MoveSelectedRow
    }
return



; ========================== Not in Prediction List ========================== ;
#IfWinNotActive PredList
    ~Enter::gosub, PredList_reset
    
    `::WinActivate, ahk_id %hPredListWin%
    
    Tab::
        if (nCurrentChar <=0)
            Send, {Tab}
        else
        {
            gosub, PredList_CompleteNextWord
            Send, {BackSpace %nCurrentChar%}
            Send, %CurrentChar%
            nCurrentChar := StrLen(CurrentChar)
        }
    return 
#IfWinNotActive


PredList_CompleteNextWord:
    Gui, PredList:Default
    LV_GetText(firstPrediction, 2, 2)
    CurrentChar := extractNextWord(CurrentChar, firstPrediction)
    gosub, PredList_Update_CurrentChar
return 


extractNextWord(CurrentChar, firstPrediction) {
    CurrentChar_array := StrSplit(CurrentChar, A_Space)
    firstPrediction_array := StrSplit(firstPrediction, A_Space)
    nWord := CurrentChar_array.Length()
    if (CurrentChar_array[nWord] <> firstPrediction_array[nWord])
    {
        CurrentChar := strArrayJoin(arrayRetrive(firstPrediction_array, 1, nWord), A_Space)
    }
    else
    {
        CurrentChar := strArrayJoin(arrayRetrive(firstPrediction_array, 1, nWord+1), A_Space)
    }
    return CurrentChar
}


; ============================ In Prediction List ============================ ;
#IfWinActive PredList
    1::gosub, PredList_numSelection
    2::gosub, PredList_numSelection
    3::gosub, PredList_numSelection
    4::gosub, PredList_numSelection
    5::gosub, PredList_numSelection
    6::gosub, PredList_numSelection
    7::gosub, PredList_numSelection
    8::gosub, PredList_numSelection
    9::gosub, PredList_numSelection
    0::gosub, PredList_numSelection
    
    Tab::
        gosub, PredList_ExtractSelection
        ;~ Gui, PredList:Default
        CurrentChar := extractNextWord(CurrentChar, SelectedText)
        gosub, PredList_Update_CurrentChar
        SelectedRow := 1
    return
    
    `::
        SelectedRow := 1
        gosub, PredList_MoveSelectedRow
        gosub, PredList_OK
    return 
#IfWinActive


PredList_numSelection:
    SelectedRow := A_ThisHotkey+1
    gosub, PredList_MoveSelectedRow
    gosub, PredList_OK
return



; ============================================================================ ;
;                                 Prediction IO                                ;
; ============================================================================ ;
requestTimer:
    if ((isSent = 0) & (CurrentChar <> LastChar)) {  
        ; Send new request
            
            if (SubStr(CurrentChar, 0, 1) = " ") {
            ; is not typing a word
                ; search by netspeak
                StrSplitByLastNword(CurrentChar, nWord2Netspeak, nonRequest, strRequist)
                ; strRequist := strArrayJoin(extractLastNword(CurrentChar, nWord2Netspeak), "+")
                StringLower, strRequist, strRequist
                URL_pred = http://api.netspeak.org/netspeak3/search?query=%strRequist%*&topk=20
                engine := "netspeak"
            }
            else {
            ; is typing a word
                ; search by google
                StrSplitByLastNword(CurrentChar, nWord2Google, nonRequest, strRequist)
                ; strRequist := strArrayJoin(extractLastNword(CurrentChar, nWord2Google), "+")      
                URL_pred = http://suggestqueries.google.com/complete/search?q=%strRequist%&client=firefox&hl=en
                engine := "google"
            }
                      
            
            ; Send
            whr.Open("GET", URL_pred, true)
            whr.Send()
            
            isSent := 1
            LastChar := CurrentChar
    }
    else if (isSent) {         
    ; check receiving
        
        try
        {   
            isReceived := whr.WaitForResponse(requestTimeout * 1000)                      
        }
        catch connErrorMsg
            isReceived := 0
        
        if (isReceived = -1) {
        ; Receive data successfully 
            predictions := whr.ResponseText
            if (engine = "netspeak")
                predictions := getPredList_postProcessing_nenetspeak(predictions)
            else if (engine = "google")
                predictions := getPredList_postProcessing_google(predictions)
            
            gosub, PredList_Update
            isSent := 0
            LastChar := CurrentChar
        } 
        else if (isReceived = 0) {
        ; Receive data unsuccessfully, give 0 code
            predictions := 0        
            gosub, PredList_Update
        }
    }
    
    ; set timer for the next check timing 
    SetTimer, requestTimer, %requestInterval%
return


getPredList_postProcessing_google(predictions) {
    predictions := StrReplace(predictions, """", "")
    predictions := StrReplace(predictions, "[", "")
    predictions := StrReplace(predictions, "]", "")
    predictions := StrReplace(predictions, "\u0027", "'")
    predictions := StrSplit(predictions, ",")
    predictions := arrayRetrive(predictions, 2, 0)
    return predictions
}

getPredList_postProcessing_nenetspeak(predictions) {
    predictions := RegExReplace(predictions, "\d+\t")
    predictions := StrSplit(predictions, "`n", "`r")
    predictions := arrayRetrive(predictions, 2, 0)
    return predictions
}

wordCounter(str, ByRef word_array, ByRef nWord) {
    word_array := StrSplit(str, A_Space) 
    nWord := word_array.Length()
}

; ============================================================================ ;
;                               String Processing                              ;
; ============================================================================ ;


;~ extractLastNword(str, n, ByRef p1, ByRef p2) {
    ;~ str := Trim(str)
    ;~ wordCounter(str, word_array, nWord) 
    ;~ if (n >= nWord)
    ;~ {
        ;~ p1 := ""
        ;~ p2 := word_array
    ;~ }
    ;~ else
    ;~ {
        ;~ p1 = []
        ;~ p2 = []
        ;~ Loop, nWord
        ;~ {
            ;~ if (A_Index <= (nWord-n)
                ;~ p1.Push(nWord[A_Index])
            ;~ else
                ;~ p2.Push(nWord[A_Index])
        ;~ }
    ;~ }
;~ }

;~ StrJoin(StrArray, sep, firstN) {   
    ;~ firstN -= 1
    ;~ str := StrArray.RemoveAt(1)
    ;~ Loop % firstN
        ;~ str .= sep . StrArray[A_Index]
    ;~ return str
;~ }

;~ StrSplitm(str, d) {
    ;~ strArray := StrSplit(str, d)
    ;~ if (strArray
;~ }


extractLastNword(str, n) {
    str := Trim(str)
    strArray := StrSplit(str, A_Space)
	if ((1-n) + strArray.Length()) < 0
		n := 0
    strArray := arrayRetrive(strArray, 1-n, 0)
    return strArray
}

StrSplitByLastNword(str, n, ByRef p1, ByRef p2) {
    str := Trim(str)
    strArray := StrSplit(str, A_Space)
    nWord := strArray.Length()
    if (nWord < n)
    {
        p1 := ""
        p2 := str
        return 
    }
        
    p1 := []
    p2 := []
    for key, val in strArray
    {
        if (key <= (nWord-n))
            p1.Push(val)
        else
            p2.Push(val)    
    }
    p1 := strArrayJoin(p1, " ")
    p2 := strArrayJoin(p2, " ")
}

arrayRetrive(a, pos1, pos2) {    
	if (pos1 <= 0)
		pos1 += a.Length()
	
	if (pos2 <= 0)
		pos2 += a.Length()
	
    a2 := []
    for key, val in a 
	{
        if ((key >= pos1) & (key <= pos2))
            a2.Push(val)
    }
    
    return a2
}

strArrayJoin(a, sep) { 
	strArray := a.Clone()
	str := strArray[1]
	strArray.Remove(1)
    for key, val in strArray 
	{
		str .= sep . val
    }
    return str
}
; ============================================================================ ;
^w::reload
^e::exitapp
^#space::
    Suspend, Toggle
    gosub, PredList_reset
return