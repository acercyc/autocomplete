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

NormalKeyList := "a`nb`nc`nd`ne`nf`ng`nh`ni`nj`nk`nl`nm`nn`no`np`nq`nr`ns`nt`nu`nv`nw`nx`ny`nz`n'`n""`n*" ;list of key names separated by `n that make up words in upper and lower case variants
NumberKeyList := "1`n2`n3`n4`n5`n6`n7`n8`n9`n0" ;list of key names separated by `n that make up words as well as their numpad equivalents
ResetKeyList := "Esc`nHome`nPGUP`nPGDN`nEnd`nLeft`nRight`nRButton`nMButton`n,`n.`n/`n[`n]`n;`n\`n-`n="  ;list of key names separated by `n that cause suggestions to reset

CurrentWord := ""
nCurrentWord := 0
LastWord := ""
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
PredList_Update_CurrentWord:
    Gui, PredList:Default
    LV_Modify(1, "select", "", CurrentWord)
return
    
    
PredList_Update:
    Gui, PredList:Default
    GuiControl, -Redraw, hPredList
    LV_Delete()
    LV_Add("select",, CurrentWord)
    if (predictions = 0)
    {
        LV_Add("",, "Connecting...")
        return
    }
    else if (predictions <> "")
    {
        loop, Parse, predictions, |
        {
            if (A_Index >= 2) & (A_LoopField <> "")
                LV_Add("", Mod(A_Index-1, 10), A_LoopField)
        }
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
    nBack := nCurrentWord
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
    CurrentWord := ""
    nCurrentWord := 0
    LastWord := ""
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
    CurrentWord .= SubStr(A_ThisHotkey, 0)
    gosub, KeyPress
return


ShiftedKey:
    if (nCurrentWord = 0)
        initCap := 1
    Char := SubStr(A_ThisHotkey, 3)
    StringUpper, Char, Char
    CurrentWord .= Char
    Gosub, KeyPress
Return

;~ ShiftKey:
    ;~ CurrentWord .= SubStr(A_ThisHotkey, 0)
    ;~ gosub, KeyPress
;~ return

~Space::
    if (nCurrentWord <=0)
        return
    CurrentWord .= " "
    gosub, KeyPress
return


KeyPress:
    nCurrentWord ++
    if (nCurrentWord = 1)
    {   
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
        
        LV_Add("select",, CurrentWord)        
    }
    
    gosub, PredList_Update_CurrentWord
    
    if (nCurrentWord = requestFromNchar)
    {
        SetTimer, requestTimer, -1       
    }
Return


~BackSpace::
    CurrentWord := SubStr(CurrentWord, 1, -1)
    nCurrentWord --
    if (nCurrentWord <= 0)
    {
        gosub, PredList_reset        
    }
    else 
    {
        gosub, PredList_Update_CurrentWord
    }
Return


Up::
    if (CurrentWord = "")
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
    if (CurrentWord = "")
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
        if (nCurrentWord <=0)
            Send, {Tab}
        else
        {
            gosub, PredList_CompleteNextWord
            Send, {BackSpace %nCurrentWord%}
            Send, %CurrentWord%
            nCurrentWord := StrLen(CurrentWord)
        }
    return 
#IfWinNotActive


PredList_CompleteNextWord:
    Gui, PredList:Default
    LV_GetText(firstPrediction, 2, 2)
    CurrentWord := extractNextWord(CurrentWord, firstPrediction)
    gosub, PredList_Update_CurrentWord
return 


extractNextWord(CurrentWord, firstPrediction) {
    CurrentWord_array := StrSplit(CurrentWord, A_Space)
    firstPrediction_array := StrSplit(firstPrediction, A_Space)
    nWord := CurrentWord_array.Length()
    if (CurrentWord_array[nWord] <> firstPrediction_array[nWord])
    {
        CurrentWord := StrJoin(firstPrediction_array, A_Space, nWord)
    }
    else
    {
        CurrentWord := StrJoin(firstPrediction_array, A_Space, nWord+1)
    }
    return CurrentWord
}

StrJoin(StrArray, sep, firstN) {   
    firstN -= 1
    str := StrArray.RemoveAt(1)
    Loop % firstN
        str .= sep . StrArray[A_Index]
    return str
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
        CurrentWord := extractNextWord(CurrentWord, SelectedText)
        gosub, PredList_Update_CurrentWord
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
    if (isSent)    ; check receiving
    {
        try
            isReceived := whr.WaitForResponse(requestTimeout * 1000)
        catch connErrorMsg
            isReceived := 0
        
        if (isReceived = -1)
        {
            predictions := whr.ResponseText
            predictions := getPredList_postProcessing(predictions)
            gosub, PredList_Update
            isSent := 0
            LastWord := CurrentWord
        } 
        else if (isReceived = 0)
        {
            predictions := 0        
            gosub, PredList_Update
        }
    }
    else if ((isSent = 0) & (CurrentWord <> LastWord))       ; Send new request
    {
        URL_pred = http://suggestqueries.google.com/complete/search?q=%CurrentWord%&client=firefox&hl=en
        whr.Open("GET", URL_pred, true)
        whr.Send()
        isSent := 1
        LastWord := CurrentWord
    }
    SetTimer, requestTimer, %requestInterval%
return


getPredList_postProcessing(predictions) {
    predictions := StrReplace(predictions, """", "")
    predictions := StrReplace(predictions, "[", "")
    predictions := StrReplace(predictions, "]", "")
    predictions := StrReplace(predictions, ",", "|")
    predictions := StrReplace(predictions, "\u0027", "'")
    return predictions
}



; ============================================================================ ;
^w::reload
^e::exitapp
^#space::
    Suspend, Toggle
    gosub, PredList_reset
return