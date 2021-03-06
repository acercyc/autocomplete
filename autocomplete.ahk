; ============================================================================ ;
;                                     Init                                     ;
; ============================================================================ ;
#NoEnv
#WinActivateForce
#MaxThreadsBuffer On
;~ #MaxThreads 255
#UseHook
SetBatchLines 20ms
SetWinDelay, 20
SendMode Input
CoordMode, Caret, Screen
CoordMode, Mouse, Screen
; SetTitleMatchMode , 2


PredListWin_w := 360
PredListWin_shift_Y := 35

requestInterval := 100
requestTimeout := 400
requestFromNchar := 2
isSent := 0


searchEng := ""
nWord2Google := 2
nWordFromGoogle := 2

nWord2Netspeak:= 2
nWordFromNetspeak := *
nTopRequestFromNetspeak := 20

GCS_key := "AIzaSyAAWoyB6S856pIvL33IP6gRl7B1PgUaaE8"
GCS_ID := "013753396245911790896:9bszyfkdl14"
GCS_isUseDidYouMean := 1


NormalKeyList := "a`nb`nc`nd`ne`nf`ng`nh`ni`nj`nk`nl`nm`nn`no`np`nq`nr`ns`nt`nu`nv`nw`nx`ny`nz`n'`n""`n*" ;list of key names separated by `n that make up words in upper and lower case variants
NumberKeyList := "1`n2`n3`n4`n5`n6`n7`n8`n9`n0" ;list of key names separated by `n that make up words as well as their numpad equivalents
ResetKeyList := "Esc`nHome`nPGUP`nPGDN`nEnd`nLeft`nRight`nRButton`nMButton`n,`n.`n/`n[`n]`n;`n\`n-`n="  ;list of key names separated by `n that cause suggestions to reset

CurrentChar := ""
nCurrentWord := 0
LastChar := ""
predictions := ""

SelectedRow := 1
SelectedText := ""
requesting := 0
initCap := 0

Gui, PredList:new, -MinimizeBox -MaximizeBox -SysMenu -Caption -AlwaysOnTop -0xC40000 +HwndhPredListWin 
Gui, Add, ListView, x0 y0 w%PredListWin_w% r11 -Hdr -Multi AltSubmit +ReadOnly hwndhPredList viPredList, Index|Prediction
Gui, Add, Button, Hidden Default gPredList_OK, OK
Gui, Margin, -0, -0
Gui, Show, AutoSize Hide, PredList

; Get win size
WinGetPos,,, win_w_orig, win_h_orig, ahk_id %hPredListWin%


; =================================== get scroll bar initial value
;~ ScrollBar_min := 0
;~ ScrollBar_max := 0
;~ ScrollBar_max_orig := 0
;~ DllCall("GetScrollRange", "UInt", hPredList, "Int", 0, "Int*", ScrollBar_min, "Int*", ScrollBar_max)
;~ DllCall("GetScrollRange", "UInt", hPredList, "Int", 0, "Int*", ScrollBar_min, "Int*", ScrollBar_max_orig)
;~ ScrollBar_h_offset := ScrollBar_max - PredListWin_w
;~ ScrollBar_max_orig := ScrollBar_max


SetHotkeys(NormalKeyList, NumberKeyList, ResetKeyList)
whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")

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
    else if (predictions[1] <> "")
    {
        for key, val in predictions
        {
            if (nonRequest = "")
                LV_Add("", key, val)
            else
                LV_Add("", key, nonRequest . " " . val)
        }
        
        
        LV_ModifyCol(1, "Right")
        LV_ModifyCol()
        
                    ;~ Gui, Show, AutoSize, PredList
                    
                    ;~ CurrentWidth := getListViewWidth(hPredList)
                    ;~ if (CurrentWidth != -1) {
                        ;~ GuiControl, Move, hPredList, w%CurrentWidth%
                        ;~ WinSet, Region, w%CurrentWidth%, PredList
                        ;~ Gui, Show, w%CurrentWidth%, PredList
                    ;~ }
                        ;~ Gui, Show, Autosize        
        
    }
    GuiControl, +Redraw, hPredList
    
    ; ============================================================================ Change window size if sentence is too long 
    ;~ DllCall("GetScrollRange", "UInt", hLVItems, "Int", 0, "Int*", ScrollBar_min, "Int*", ScrollBar_max)
    ;~ if (ScrollBar_max > ScrollBar_max_orig) 
    ;~ {
        ;~ GuiControl, Move, LVItems, % "w" . (ScrollBar_max - ScrollBar_h_offset)
        ;~ win_w_new := ScrollBar_max - ScrollBar_max_orig + win_w_orig
        ;~ WinMove, ahk_id %hPredList%, PredList,,, %win_w_new%
    ;~ }    
return


getListViewWidth(hPredList) {
    SendMessage, 4125, 0, 0,, ahk_id %hPredList%
    w1 := ErrorLevel
    
    SendMessage, 4125, 1, 0,, ahk_id %hPredList%
    w2 := ErrorLevel    
    
    if((w1 <> FAIL) & (w2 <> FAIL))
        return (w1+w2)
    else
        return -1
}


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
    
    if (InStr(SelectedText, CurrentChar))
    {
        SendText := SubStr(SelectedText, StrLen(CurrentChar)+1)
        nBack := 0
    }
    else
    {
        SendText := SelectedText
        nBack := StrLen(CurrentChar)
    }
    
    gosub, PredList_reset
    WinActivate, ahk_id %WorkingWin%
    
    Send, {BackSpace %nBack%}
    SendInput, %SendText%
return



PredList_ShowGUI:
    WinShow, ahk_id %hPredListWin%
    WinSet, AlwaysOnTop, on, ahk_id %hPredListWin%
    WinSet, Style, -0xC00000, ahk_id %hPredListWin%
    WinGetPos,,, win_w, win_h, ahk_id %hPredListWin%

    SysGet, VirtualWidth, 78
    ; SysGet, VirtualHeight, 79
    ; SysGet, VirtualHeight, 17
    VirtualHeight := A_ScreenHeight
    
    if (A_CaretX = "")
    {
        ; ======= show on edge of the window ======= ;
        ;~ WinPosi_X := A_ScreenWidth - win_w
        ;~ WinPosi_Y := A_ScreenHeight - win_h - 30
        
        ; ======= follow mouse position ======= ;
        MouseGetPos, mx, my
        WinPosi_X := mx
        WinPosi_Y := my + PredListWin_shift_Y
        if ((mx + win_w) > VirtualWidth)
            WinPosi_X := VirtualWidth - win_w
        
        ;~ if ((my + win_h) > (VirtualHeight))
            ;~ WinPosi_Y := VirtualHeight - win_h           
        
    }            
    else
    {
        WinPosi_X := A_CaretX
        WinPosi_Y := A_CaretY + PredListWin_shift_Y
        if ((A_CaretX + win_w) > VirtualWidth)
            WinPosi_X := VirtualWidth-win_w
        
        if ((A_CaretY + win_h + PredListWin_shift_Y) > (VirtualHeight))
            WinPosi_Y := A_CaretY - win_h - PredListWin_shift_Y
    }
    WinMove, ahk_id %hPredListWin%,, WinPosi_X, WinPosi_Y
return

; ============================================================================ ;
;                                     Reset                                    ;
; ============================================================================ ;
PredList_reset_para:
    SetTimer, requestTimer, Delete
    SelectedRow := 1
    predictions := ""
    CurrentChar := ""
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
    WinActivate, ahk_id %WorkingWin% ;modify 2019/05/08 08:38
    WorkingWin := ""
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
        Hotkey, ~*^%A_LoopField%, PredList_reset, UseErrorLevel
        Hotkey, ~*!%A_LoopField%, PredList_reset, UseErrorLevel
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
    if (StrLen(CurrentChar) = 0)
        initCap := 1
    Char := SubStr(A_ThisHotkey, 3)
    StringUpper, Char, Char
    CurrentChar .= Char
    Gosub, KeyPress
Return

~Space::
    if (StrLen(CurrentChar) <=0)
        return
    else if ((StrLen(CurrentChar) >=2) & (SubStr(CurrentChar, 0) = A_Space))
    {
        Send, {BackSpace}
        gosub, PredList_reset
    }
    else
    {
        if (isSent)
        {
            whr.Abort()
            isSent := 0
        }
        SetTimer, requestTimer, -1
        CurrentChar .= " "
        gosub, KeyPress
    }
return


KeyPress:
    if (StrLen(CurrentChar) = 1) {   
    ; if it's first word, open the window
        WinGet, WorkingWin, ID, A
        Gui, PredList:Default
        LV_Add("select","", CurrentChar)
        LV_ModifyCol()
    }
    else
    {
        gosub, PredList_Update_CurrentChar
        ;~ if (!WinActive("ahk_id" . WorkingWin))
            ;~ WinActivate, ahk_id %WorkingWin%
    }
    
    if (StrLen(CurrentChar) = requestFromNchar)
    {
        gosub, PredList_ShowGUI
        SetTimer, requestTimer, -1       
    }
Return



~BackSpace::
    CurrentChar := SubStr(CurrentChar, 1, -1)
    if (StrLen(CurrentChar) <= 0)
    {
        gosub, PredList_reset        
    }
    else 
    {
        gosub, PredList_Update_CurrentChar
    }
return


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




; =========================== Common Reseting Keys =========================== ;
~*^BackSpace::
    ;~ WinGet, WinState, Style, ahk_id %hPredListWin%
    ;~ if (WinState & 0x10000000)  ; 0x10000000 is WS_VISIBLE
    if (CurrentChar != "")
        gosub, PredList_reset
return


~*LButton::
    ;~ WinGet, WinState, Style, ahk_id %hPredListWin%
    ;~ if (WinState & 0x10000000)  ; 0x10000000 is WS_VISIBLE
    if (CurrentChar != "")
        gosub, PredList_reset
return


; ========================== Not in Prediction List ========================== ;
#IfWinNotActive PredList
    ~Enter::gosub, PredList_reset
    
    `::WinActivate, ahk_id %hPredListWin%
    
    Tab::
        if (StrLen(CurrentChar) <=0)
            Send, {Tab}
        else
        {
            Gui, PredList:Default
            LV_GetText(firstPrediction, 2, 2)
            extractNextWord(CurrentChar, firstPrediction, CurrentChar, lastWord, nDel)
            gosub, PredList_Update_CurrentChar
            Send, {BackSpace %nDel%}
            Send, %lastWord%
        }
    return 
#IfWinNotActive


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
        if (SelectedRow = 1)
            SelectedRow := 2
            gosub, PredList_MoveSelectedRow
        gosub, PredList_ExtractSelection
        extractNextWord(CurrentChar, SelectedText, CurrentChar, lastWord, nDel)
        gosub, PredList_Update_CurrentChar
        WinActivate, ahk_id %WorkingWin%
        Send, {BackSpace %nDel%}
        Clipboard := CurrentChar
        Send, %lastWord%
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
    ;~ ListVars
    if ((isSent = 0) & (CurrentChar <> LastChar)) {  
        ; Send new request
            if (SubStr(CurrentChar, 0) = " ") {
            ; is not typing a word
                ; search by netspeak
                StrSplitByLastNword(CurrentChar, nWord2Netspeak, nonRequest, strRequist)
                StringLower, strRequist, strRequist
                URL_pred = http://api.netspeak.org/netspeak3/search?query=%strRequist%*&topk=%nTopRequestFromNetspeak%
                engine := "netspeak"
            }
            else {
            ; is typing a word
                ; search by google
                StrSplitByLastNword(CurrentChar, nWord2Google, nonRequest, strRequist)
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
            predictions := whr.ResponseText
        }
        catch connErrorMsg
            isReceived := 0
        
        if (isReceived = -1) {
        ; Receive data successfully 
            if (engine = "netspeak")
                predictions := getPredList_postProcessing_netspeak(predictions)
            else if (engine = "google")
                predictions := getPredList_postProcessing_google(predictions)
            
            
            ; === Did you mean ===
            if (GCS_isUseDidYouMean & (predictions.Length() <= 1))
            {
                DYM_str := ""
                DYM_str := DidYouMeanRequest(GCS_ID, GCS_key, strRequist, requestTimeout)
                if (DYM_str <> "")
                    predictions.InsertAt(1, DYM_str)
            }
            
            
            gosub, PredList_Update
            isSent := 0
            isReceived := 0
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



DidYouMeanRequest(GCS_ID, GCS_key, strRequist, requestTimeout) {
    whr_DYM := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    URL_pred := "https://content.googleapis.com/customsearch/v1?cx=" . GCS_ID . "&lr=lang_en&q=" . strRequist . "&fields=spelling&prettyPrint=false&key=" . GCS_key
    whr_DYM.Open("GET", URL_pred, true)
    whr_DYM.Send()
    whr_DYM.WaitForResponse(requestTimeout * 1000)
    DYM_str := whr_DYM.ResponseText
    if (DYM_str = "{}")
        DYM_str := ""
    else
    {
        RegExMatch(DYM_str, "OU)correctedQuery"":""(.+)"",", DYM_str)
        DYM_str := DYM_str.Value[1]
    }
    return DYM_str
}


getPredList_postProcessing_google(predictions) {
    predictions := StrReplace(predictions, """", "")
    predictions := StrReplace(predictions, "[", "")
    predictions := StrReplace(predictions, "]", "")
    predictions := StrReplace(predictions, "\u0027", "'")
    predictions := StrSplit(predictions, ",")
    predictions := arrayRetrive(predictions, 2, 0)
    return predictions
}

getPredList_postProcessing_netspeak(predictions) {
    predictions := RegExReplace(predictions, "\d+\t")
    predictions_temp := StrSplit(predictions, "`n", "`r")
    predictions := []
    for key, val in predictions_temp {
        if (key=1)
            continue
        if (RegExMatch(val, "[^a-zA-Z0-9 ']"))
            continue
        else
            predictions.Push(val)
    }
    return predictions
}


; ============================================================================ ;
;                               String Processing                              ;
; ============================================================================ ;
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


extractNextWord(CurrentChar, PredictionChar, ByRef newCurrentChar, ByRef lastWord, ByRef nDel) {
    if (SubStr(CurrentChar, 0) = " ")
    {
        endSpace := " "
        hasEndSpace := 1
    }
    else
    {
        endSpace := ""
        hasEndSpace := 0
    }

    CurrentChar_t := Trim(CurrentChar)
    CurrentChar_array := StrSplit(CurrentChar_t, A_Space)
    nCurrentWord := CurrentChar_array.Length()
    
    PredictionChar_t := Trim(PredictionChar)
    PredictionChar_array := StrSplit(PredictionChar_t, A_Space)
    nPredictionWord := PredictionChar_array.Length()
    
    if (CurrentChar = PredictionChar)
    {
        newCurrentChar := CurrentChar
        lastWord := endSpace
        nDel := 0
    } 
    else if (CurrentChar_array[nCurrentWord] <> PredictionChar_array[nCurrentWord])
    {   
        lastWord := PredictionChar_array[nCurrentWord]
        nDel := Strlen(CurrentChar_array[nCurrentWord]) + hasEndSpace
        newCurrentChar := strArrayJoin(arrayRetrive(PredictionChar_array, 1, nCurrentWord), A_Space)
    }
    else
    {
        lastWord := " " . PredictionChar_array[nCurrentWord+1]
        nDel := hasEndSpace
        newCurrentChar := strArrayJoin(arrayRetrive(PredictionChar_array, 1, nCurrentWord+1), A_Space)
    }
    return
}


; ============================================================================ ;
^#w::reload
^#e::exitapp
^#space::
    Suspend, Toggle
    gosub, PredList_reset
return