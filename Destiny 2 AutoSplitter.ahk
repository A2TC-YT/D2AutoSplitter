#SingleInstance, Force
#NoEnv
#KeyHistory 0
ListLines Off
Process, Priority, , A
SetBatchLines, -1
SetWinDelay, -1
SetControlDelay, -1
SendMode Input
#Include %A_ScriptDir%/Gdip_all.ahk
SetWorkingDir, %A_ScriptDir%
CoordMode, Mouse
CoordMode, Pixel

WinTitle := "LiveSplit"

; check for folders and settings files
    IfNotExist, %A_ScriptDir%\Dependencies
    {
        FileCreateDir, %A_ScriptDir%\Dependencies
        FileAppend,, %A_ScriptDir%\Dependencies\settings.txt
    }
    IfNotExist, %A_ScriptDir%\Split_Files
    {
        FileCreateDir, %A_ScriptDir%\Split_Files
    }
    IfNotExist, %A_ScriptDir%\Split_Images
    {
        FileCreateDir, %A_ScriptDir%\Split_Images
        FileAppend, 0x000000&0x000000&0|0|1|1, %A_ScriptDir%\Split_Images\image_info.txt
    }

    global hotkeySettingsString = 
    global hotKeySettingsArray := []
    FileRead, hotkeySettingsString, %A_ScriptDir%\Dependencies\settings.txt
    hotKeySettingsArray := StrSplit(hotkeySettingsString, "&")
    loop, 4 
    {
        Hotkey%A_Index% := hotKeySettingsArray[A_Index]
    }
; ===================================================

; global declarations for main autosplitter
    global currentSplit =
    global currentlyLoadedSplits := []
    global currentlyLoadedSplitIndex := 1
    global breakLoop := 0
    global bossHpHelper := 0
    global makeWhite := 0
    global makeBlack := 0
    global makeTotal := 0
    global makex := 0
    global makey := 0
    global makew := 0
    global makeh := 0
    global waitingForNextSplit := 0
    global timerText := 0
    global nLoops := 0        
    global findFunc =
    global threshold =
    global doubleCheck =
    global currentSplitImageInfo =
    global breakLoopLF := 0
    global PercCorrectForGui:= 0
    global WhiteCorrectForGui:= 0
    global BlackCorrectForGui:= 0
; ===================================================

; global declarations for split image maker
    global realImage
    global BnWImage

    scshot = %A_ScriptDir%\Dependencies\fullScreenshot.png
    realImage = %A_ScriptDir%\Dependencies\real_image.png
    BnWImage = %A_ScriptDir%\Dependencies\BnW.png
    tmpImage = %A_WorkingDir%\Dependencies\tmp.png

    pToken := Gdip_Startup()
    pToken1 := Gdip_Startup()
    pBitmap := Gdip_BitmapFromScreen("0|0|1|1")
    Gdip_SaveBitmapToFile(pBitmap, realImage)
    Gdip_SaveBitmapToFile(pBitmap, BnWImage)
    Gdip_DisposeImage(pBitmap)
    Gdip_Shutdown(pToken)

    x1 := 0
    y1 := 0
    x2 := 0
    y2 := 0
    global w =
    global h =
    global total = 0
    global imageCoords := "0|0|1|1"

    imageInfoString =
    FileRead, imageInfoString, %A_ScriptDir%\Split_Images\image_info.txt

    imageDataArray := StrSplit(imageInfoString, "&")
    HPBarDarkColor := imageDataArray[1]
    HPBarLightColor := imageDataArray[2]
    global bossHealthBarHashTable := findAllColorsBetween(imageDataArray[1], imageDataArray[2])
; ===================================================

; global declarations for split manager
    global splitManagerIndex := 0
    global isSplitManagerOpen := 0
; ===================================================

; GUI for main autosplitter (includes several declarations)
    FileInstall, 31048.ico, %A_ScriptDir%\31048.ico, 1
    Menu,Tray, Icon, %A_ScriptDir%\31048.ico
    Gui, Autosplitter: Color, 0x37383B
    if (FileExist("backgroundimage.png"))
        Gui, Autosplitter: Add, Picture, x0 y0 w721 h510, %A_ScriptDir%\backgroundimage.png
    Gui, Autosplitter: Font, s6 CWhite
    Gui, Autosplitter: Add, Text, x5 y497 w55 h15 +0x200, Made By A2TC
    Gui, Autosplitter: Font, s9, Segoe UI
    Gui, Autosplitter: Add, GroupBox, x8 y0 w169 h282
    Gui, Autosplitter: Add, GroupBox, x218 y288 w305 h210, Hotkeys
    Gui, Autosplitter: Add, GroupBox, x530 y288 w177 h210, Controls

    tmpVar1 := hotKeySettingsArray[1]
    if (tmpVar1 != "")
        Hotkey, $%tmpVar1%, StartKeyPressed
    Gui, Autosplitter: Add, Hotkey, x306 y320 w120 h21 vHotKey1, %tmpVar1%
    tmpVar1 := hotKeySettingsArray[2]
    if (tmpVar1 != "")
        Hotkey, $%tmpVar1%, ResetAutoSplitter
    Gui, Autosplitter: Add, Hotkey, x306 y368 w120 h21 vHotKey2, %tmpVar1%
    tmpVar1 := hotKeySettingsArray[3]
    if (tmpVar1 != "")
        Hotkey, $%tmpVar1%, SkipSplit
    Gui, Autosplitter: Add, Hotkey, x306 y464 w120 h21 vHotKey3, %tmpVar1%
    tmpVar1 := hotKeySettingsArray[4]
    if (tmpVar1 != "")
        Hotkey, $%tmpVar1%, UndoSplit
    Gui, Autosplitter: Add, Hotkey, x306 y416 w120 h21 vHotKey4, %tmpVar1%
    splitButton := hotKeySettingsArray[1]
    resetButton := hotKeySettingsArray[2]
    skipButton := hotKeySettingsArray[3] 
    undoButton := hotKeySettingsArray[4]

    Gui, Autosplitter: Add, Text, x234 y320 w59 h23 +0x200, Start/Split
    Gui, Autosplitter: Add, Text, x234 y368 w59 h23 +0x200, Reset
    Gui, Autosplitter: Add, Text, x234 y464 w59 h23 +0x200, Skip Split
    Gui, Autosplitter: Add, Text, x234 y416 w59 h23 +0x200, Undo Split
    Gui, Autosplitter: Add, Button, x442 y320 w58 h23 gSethotkeys, Set
    Gui, Autosplitter: Add, Button, x442 y368 w58 h23 gSethotkeys, Set
    Gui, Autosplitter: Add, Button, x442 y416 w58 h23 gSethotkeys, Set
    Gui, Autosplitter: Add, Button, x442 y464 w58 h23 gSethotkeys, Set
    Gui, Autosplitter: Add, Button, x546 y432 w145 h56 gStartAutoSplitter, Start AutoSplitter
    Gui, Autosplitter: Add, Button, x546 y368 w145 h56 gStopOnlyAutoSplitter, Reset AutoSplitter
    Gui, Autosplitter: Add, Button, x618 y304 w79 h56 gSkipOnlyAutoSplitter, Skip Current`nSplit Image
    Gui, Autosplitter: Add, Button, x538 y304 w79 h56 gUndoOnlyAutoSplitter, Undo Current`nSplit Image
    Gui, Autosplitter: Add, Text, x184 y8 w313 h255 +0x200 +Center +Border vtimerText
    Gui, Autosplitter: Add, Picture, x184 y8 w313 h255 +Border vCurrentSplitImage
    Gui, Autosplitter: Add, Text, x200 y267 w122 h19 +0x200 vcurrerntlyLookingForText, Currently Looking For:
    Gui, Autosplitter: Add, Button, x16 y200 w153 h73 gOpenSplitImageMaker, Open Split Image Maker
    Gui, Autosplitter: Add, Text, x16 y64 w153 h23 +0x200 +Center, Currently Loaded Splits:
    Gui, Autosplitter: Add, Button, x16 y152 w153 h42 gOpenSplitManager, Edit/Make New Splits
    Gui, Autosplitter: Add, Text, x16 y88 w153 h23 +0x200 +Center vNameOfLoadedSplits
    Gui, Autosplitter: Add, Button, x16 y16 w153 h42 gLoadSplitsToUse, Load Splits
    Gui, Autosplitter: Add, Text, x328 y267 w166 h20 +0x200 vsplitImageNameForGui
    Gui, Autosplitter: Add, Button, x20 y450 w176 h40 gopenInfoTab, Info and how to use the Autosplitter

    Gui, Autosplitter: Add, GroupBox, x504 y30 w209 h213, Splits
    Gui, Autosplitter: Add, Text, x512 y70 w193 h16 +0x200, ________________________________________________
    Gui, Autosplitter: Add, Text, x512 y110 w193 h16 +0x200, ________________________________________________
    Gui, Autosplitter: Add, Text, x512 y150 w193 h16 +0x200, ________________________________________________
    Gui, Autosplitter: Add, Text, x512 y190 w193 h16 +0x200, ________________________________________________
    Gui, Autosplitter: Add, Text, x512 y54 w193 h25 vPrev2
    Gui, Autosplitter: Add, Text, x512 y94 w193 h25 vPrev, previous split
    Gui, Autosplitter: Add, Text, x512 y134 w193 h25 vCurr, current split
    Gui, Autosplitter: Add, Text, x512 y174 w193 h25 vNext, next split
    Gui, Autosplitter: Add, Text, x512 y214 w193 h25 vNext2

    Gui, Autosplitter: Add, GroupBox, x8 y288 w200 h210
    Gui, Autosplitter: Add, Text, x13 y310 w153 h23 +0x200, Current Comparison FPS:
    Gui, Autosplitter: Add, Text, x150 y310 w53 h23 +0x200 +Center +Border vloopCount, 0
    Gui, Autosplitter: Add, Text, x10 y340 w196 h23 +0x200 +Center, Current Match Percent
    Gui, Autosplitter: Add, Text, x79 y364 w58 h23 +0x200 +Center +Border vpCorrectForGui, 0
    Gui, Autosplitter: Add, Text, x10 y390 w97 h23 +0x200 +Center, `% White Correct
    Gui, Autosplitter: Add, Text, x109 y390 w97 h23 +0x200 +Center, `% Black Correct
    Gui, Autosplitter: Add, Text, x29 y415 w59 h23 +0x200 +Center +Border vwCorrectForGui, 0
    Gui, Autosplitter: Add, Text, x129 y415 w59 h23 +0x200 +Center +Border vbCorrectForGui, 0

; ===================================================

; GUI for split image maker
    Gui, imageMaker: Add, GroupBox, x12 y-1 w140 h540 , Settings

        Gui, imageMaker: Add, Button, x22 y15 w120 h50 gCapture vCapture, Freeze Screen
        Gui, imageMaker: Add, Button, x22 y15 w120 h50 gUncapture vUncapture +Hidden, Unfreeze Screen
        tmpVar1 := hotKeySettingsArray[5]
        if (tmpVar1 != "")
            Hotkey, $%tmpVar1%, Capture
        Gui, imageMaker: Add, Hotkey, x27 y70 w110 h20 vCaptureHotkey, %tmpVar1%
        Gui, imageMaker: Add, Button, x52 y92 w60 h23 gSethotkeys, Set
        Gui, imageMaker: Add, Button, x22 y115 w120 h50 gPicture, Select Area
        Gui, imageMaker: Add, Button, x22 y165 w120 h50 gSave, Save Current Image
        Gui, imageMaker: Add, Button, x22 y480 w120 h50 gOpenHPFinder, Open Boss HP Bar Color Finder

        Gui, imageMaker: Add, Text, x70 y219 w80 h20 , Top
        Gui, imageMaker: Add, Text, x63 y242 w38 h15 vTopNum +Border +Center, 0
        Gui, imageMaker: Add, Button, x21 y239 w21 h20 g10TopDec, -10
        Gui, imageMaker: Add, Button, x122 y239 w24 h20 g10TopInc, +10
        Gui, imageMaker: Add, Button, x42 y239 w20 h20 gTopDec, -1
        Gui, imageMaker: Add, Button, x102 y239 w20 h20 gTopInc, +1

        Gui, imageMaker: Add, Text, x65 y289 w80 h20 , Bottom
        Gui, imageMaker: Add, Text, x63 y312 w38 h15 vBotNum +Border +Center, 0
        Gui, imageMaker: Add, Button, x21 y309 w21 h20 g10BotDec, -10
        Gui, imageMaker: Add, Button, x122 y309 w24 h20 g10BotInc, +10
        Gui, imageMaker: Add, Button, x42 y309 w20 h20 gBotDec, -1
        Gui, imageMaker: Add, Button, x102 y309 w20 h20 gBotInc, +1

        Gui, imageMaker: Add, Text, x70 y359 w80 h20 , Left
        Gui, imageMaker: Add, Text, x63 y382 w38 h15 vLeftNum +Border +Center, 0
        Gui, imageMaker: Add, Button, x21 y379 w21 h20 g10LeftDec, -10
        Gui, imageMaker: Add, Button, x122 y379 w24 h20 g10LeftInc, +10
        Gui, imageMaker: Add, Button, x42 y379 w20 h20 gLeftDec, -1
        Gui, imageMaker: Add, Button, x102 y379 w20 h20 gLeftInc, +1

        Gui, imageMaker: Add, Text, x67 y429 w80 h20 , Right
        Gui, imageMaker: Add, Text, x63 y452 w38 h15 vRightNum +Border +Center, 0
        Gui, imageMaker: Add, Button, x21 y449 w21 h20 g10RightDec, -10
        Gui, imageMaker: Add, Button, x122 y449 w24 h20 g10RightInc, +10
        Gui, imageMaker: Add, Button, x42 y449 w20 h20 gRightDec, -1
        Gui, imageMaker: Add, Button, x102 y449 w20 h20 gRightInc, +1

        Gui, imageMaker: Add, GroupBox, x162 y-1 w530 h510 , Black and White Pixels
        Gui, imageMaker: Add, GroupBox, x702 y-1 w530 h510 , Actual Image
        Gui, imageMaker: Add, Picture, x712 y19 w510 h480 vReal_Pic, %A_ScriptDir%\Dependencies\real_image.png
        Gui, imageMaker: Add, Picture, x172 y19 w510 h480 vBnW_Pic, %A_ScriptDir%\Dependencies\BnW.png
        Gui, imageMaker: Add, Text, x270 y520 w100 h20 , Percentage White:
        Gui, imageMaker: Add, Text, x360 y520 w50 h20 vPW, 0
        Gui, imageMaker: Add, Text, x520 y520 w100 h20 , Total Pixels:
        Gui, imageMaker: Add, Text, x580 y520 w50 h20 vTP, 0
        Gui, imageMaker: Font, S6 , Verdana
        Gui, imageMaker: Add, Text, x2 y538 w120 h10, Made by A2TC

    Gui, HPbarColor: +AlwaysOnTop
        Gui, HPbarColor: Add, Button, x8 y8 w57 h128 gSaveHPBarColors, Save Colors
        Gui, HPbarColor: Add, Button, x8 y146 w57 h56 gSetBarLocation, Set Bar Location
        Gui, HPbarColor: Add, Button, x72 y168 w149 h46 gSetDarkColor, Find Dark Color
        Gui, HPbarColor: Add, Button, x224 y168 w149 h46 gSetLightColor, Find Light Color
        Gui, HPbarColor: Add, Text, x72 y137 w149 h28 +0x200 +Center, Dark Color
        Gui, HPbarColor: Add, Text, x224 y136 w149 h28 +0x200 +Center, Light Color

        imageInfoString =
        FileRead, imageInfoString, %A_ScriptDir%\Split_Images\image_info.txt

        imageDataArray := StrSplit(imageInfoString, "&")
        HPBarDarkColor := imageDataArray[1]
        HPBarLightColor := imageDataArray[2]

        pGlobalBitmap := Gdip_CreateBitmap(149, 129)
        setBitmapColor(pGlobalBitmap, HPBarDarkColor)
        Gdip_SaveBitmapToFile(pGlobalBitmap, tmpImage)
        Gui, HPbarColor: Add, Picture, x72 y8 w149 h129 vdarkHPColor, %tmpImage%
        Gdip_DisposeImage(pGlobalBitmap)
        pGlobalBitmap := Gdip_CreateBitmap(149, 129)
        setBitmapColor(pGlobalBitmap, HPBarLightColor)
        Gdip_SaveBitmapToFile(pGlobalBitmap, tmpImage)
        Gui, HPbarColor: Add, Picture, x224 y8 w149 h129 vlightHPColor, %tmpImage%
        Gdip_DisposeImage(pGlobalBitmap)

    ; Create the "selection rectangle" GUIs (one for each edge).
        Loop 4 {
            Gui, %A_Index%: -Caption +ToolWindow +AlwaysOnTop
            Gui, %A_Index%: Color, Red
        }
; ===================================================

; GUI for split manager
    Gui, SplitManager: Font, s9, Segoe UI
    Gui, SplitManager: Add, GroupBox, x8 y8 w129 h194, GroupBox
    Gui, SplitManager: Add, Button, x24 y32 w97 h41 gLoadSplitFile, Load Splits
    Gui, SplitManager: Add, Button, x24 y80 w97 h41 gSaveSplitFile, Save Current Splits as
    Gui, SplitManager: Add, Button, x24 y128 w97 h25 gRemoveSplit, Remove Split
    Gui, SplitManager: Add, Button, x24 y160 w97 h25 gAddSplit, Add Split
    Gui, SplitManager: Add, Text, x162 y16 w121 h23 +0x200 +Center, Split Name
    Gui, SplitManager: Add, Text, x290 y16 w121 h23 +0x200 +Center, Image to Find
    Gui, SplitManager: Add, Text, x415 y16 w100 h23 +0x200 +Center, Dummy Split
    Gui, SplitManager: Add, Text, x515 y16 w60 h23 +0x200 +Left, Threshold
    Gui, SplitManager: Add, Text, x586 y16 w121 h23 +0x200 +Left, Delay (s)

    loop 50
    {
        offset := A_Index*32
        Gui, SplitManager: Add, Text, % "x" 145 " y" 21+offset " w" 20 " h" 23, %A_Index%.
        Gui, SplitManager: Add, Edit, % "x" 162 " y" 16+offset " w" 120 " h" 24 " vsplitName"A_Index,
        Gui, SplitManager: Add, DropDownList, % " x" 290 " y" 16+offset " w" 120 " vsplitImage"A_Index, %imageNamesForSplitManager%
        Gui, SplitManager: Add, CheckBox, % "x" 458 " y" 16+offset " w" 17 " h" 24 " vsplitDummyOrNot"A_Index
        Gui, SplitManager: Add, Edit, % "x" 514 " y" 16+offset " w" 57 " h" 24 " number +Center" " vsplitThreshold"A_Index, 0.90
        Gui, SplitManager: Add, Edit, % "x" 580 " y" 16+offset " w" 57 " h" 24 " number +Center" " vsplitDelay"A_Index, 7
        GuiControl SplitManager: Hide, splitName%A_Index%
        GuiControl SplitManager: Hide, splitImage%A_Index%
        GuiControl SplitManager: Hide, splitDummyOrNot%A_Index%
        GuiControl SplitManager: Hide, splitThreshold%A_Index%
        GuiControl SplitManager: Hide, splitDelay%A_Index%
    }
    makeNewSplit(splitManagerIndex+1)
; ===================================================

Gui, Autosplitter: Show, w721 h510, Destiny 2 AutoSplitter
Return

; main autosplitter functionality
    Sethotkeys:
        Gui, Autosplitter: Submit, NoHide
        Gui, imageMaker: Submit, NoHide
        
        if (Hotkey1 != "")
        {
            if (hotKeySettingsArray[1] != "")
                Hotkey, % hotKeySettingsArray[1], off
            hotKeySettingsArray[1] := HotKey1
            Hotkey, $%HotKey1%, StartKeyPressed
        }
        if (Hotkey2 != "")
        {
            if (hotKeySettingsArray[2] != "")
                Hotkey, % hotKeySettingsArray[2], off
            hotKeySettingsArray[2] := HotKey2
            Hotkey, $%HotKey2%, ResetAutoSplitter
        }
        if (Hotkey3 != "")
        {
            if (hotKeySettingsArray[3] != "")
                Hotkey, % hotKeySettingsArray[3], off
            hotKeySettingsArray[3] := HotKey3
            Hotkey, $%HotKey3%, SkipSplit
        }
        if (Hotkey4 != "") 
        {
            if (hotKeySettingsArray[4] != "")
                Hotkey, % hotKeySettingsArray[4], off
            hotKeySettingsArray[4] := HotKey4
            Hotkey, $%HotKey4%, UndoSplit
        }
        if (CaptureHotkey != "") 
        {
            if (hotKeySettingsArray[5] != "")
                Hotkey, % hotKeySettingsArray[5], off
            hotKeySettingsArray[5] := CaptureHotkey
            Hotkey, $%CaptureHotkey%, Capture
        }
        hotkeySettingsString := hotKeySettingsArray[1]"&"hotKeySettingsArray[2]"&"hotKeySettingsArray[3]"&"hotKeySettingsArray[4]"&"hotKeySettingsArray[5]
        FileDelete, %A_ScriptDir%\Dependencies\settings.txt
        FileAppend, %hotkeySettingsString%, %A_ScriptDir%\Dependencies\settings.txt
        splitButton := hotKeySettingsArray[1]
        resetButton := hotKeySettingsArray[2]
        skipButton := hotKeySettingsArray[3] 
        undoButton := hotKeySettingsArray[4]
    return

    OpenSplitImageMaker:
        Gui, Autosplitter: +Disabled
        Gui, imageMaker: Show, Center h550 w1244, Split Image Maker
        WinWaitClose, Split Image Maker
        Gui, Autosplitter: -Disabled 
        Gui, Screenshot: Cancel,
        Gui, Autosplitter: Show,
    Return

    OpenSplitManager:
        Gui, Autosplitter: +Disabled
        clearSplitManager()
        checkForDeletedImages()
        FileRead, imageInfoString, %A_ScriptDir%\Split_Images\image_info.txt
        imageDataArray := StrSplit(imageInfoString, "&")
        imageNamesForSplitManager := "|None||Boss Healthbar|Boss Death"
        loop, % (imageDataArray.MaxIndex() - 3)
        {
            temporaryImageName := StrSplit(imageDataArray[A_Index+3], ",")
            temporaryImageName := temporaryImageName[1]
            imageNamesForSplitManager = %imageNamesForSplitManager%|%temporaryImageName%
        }
        loop, 50
        {
            GuiControl SplitManager: , splitImage%A_Index%, %imageNamesForSplitManager%
        }
        Gui, SplitManager: Show, Center h205, Split Manager
        isSplitManagerOpen := 1
        WinWaitClose, Split Manager
        isSplitManagerOpen := 0
        Gui, Autosplitter: -Disabled
        Gui, Autosplitter: Show,
    Return

    countLoops:
        GuiControl AutoSplitter:, loopCount, %nLoops%
        global nLoops := 0
    return

    updateCorrectStats:
        GuiControl AutoSplitter:, pCorrectForGui, %PercCorrectForGui%
        GuiControl AutoSplitter:, wCorrectForGui, %WhiteCorrectForGui%
        GuiControl AutoSplitter:, bCorrectForGui, %BlackCorrectForGui%
        PercCorrectForGui := 0
        WhiteCorrectForGui := 0
        BlackCorrectForGui := 0
    Return

    StartKeyPressed:
        Send, {%splitButton%}
    StartAutoSplitter:
        if (currentlyLoadedSplits[1] == "")
        {
            MsgBox, Select a split file first please
            return
        }
        global currentlyLoadedSplitIndex := 1
        GUIupdate()
        global breakLoop := 0
        global nLoops := 0
        SetTimer, countLoops, 1000
        Hotkey, %splitButton%, Off
        loop
        {
            GuiControl AutoSplitter:, timerText, 
            previousSplitWasBossDeath := 0
            currentSplit := StrSplit(currentlyLoadedSplits[currentlyLoadedSplitIndex], ",")
            if (currentlyLoadedSplitIndex > 1)
            {
                previousSplit := StrSplit(currentlyLoadedSplits[currentlyLoadedSplitIndex-1], ",")
                if (previousSplit[2] == "Boss Death")
                    previousSplitWasBossDeath := 1
            }
            currentSplitImageName := currentSplit[2]
            GuiControl AutoSplitter:, currerntlyLookingForText, Currently Looking For:
            GuiControl Autosplitter:, currentSplitImage, %A_ScriptDir%\Dependencies\real_image.png
            GuiControl Autosplitter:, currentSplitImage,
            GuiControl Autosplitter:, currentSplitImage, %A_WorkingDir%\Split_Images\%currentSplitImageName%.png
            GuiControl Autosplitter: Move, currentSplitImage, x184 y8 w313 h255
            GuiControl Autosplitter:, splitImageNameForGui, %currentSplitImageName%

            imageInfoString =
            FileRead, imageInfoString, %A_ScriptDir%\Split_Images\image_info.txt
            imageDataArray := StrSplit(imageInfoString, "&")
            for i, imageData in imageDataArray
            {
                currentSplitImageInfo := StrSplit(imageData, ",")
                if (currentSplitImageInfo[1] == currentSplitImageName)
                {
                    break
                }
            }

            if (currentSplitImageName == "None") 
            {
                MsgBox, no image selected for split %currentlyLoadedSplitIndex%
                GoTo, StopOnlyAutoSplitter
            }
            findFunc := "findNormal"
            currentSplitPixelString := makePixelArrayString(currentSplitImageName)
            currentSplitPixelArray := StrSplit(currentSplitPixelString, ",")
            if (currentSplitImageName == "Boss Death")
            {
                currentSplitPixelArray :=
                findFunc := "findBossDeath"
                GuiControl AutoSplitter:, CurrentSplitImage
            }
            if (currentSplitImageName == "Boss Healthbar")
            {
                currentSplitPixelArray :=
                findFunc := "findBossThere"
                GuiControl AutoSplitter:, CurrentSplitImage
            }

            currentSplitImageInfo[3] := currentSplitPixelArray

            lookingFor(findFunc, currentSplit[4], previousSplitWasBossDeath, currentSplitImageInfo)
            if (currentlyLoadedSplitIndex > currentlyLoadedSplits.MaxIndex() || currentlyLoadedSplitIndex < 1)
            {
                break
            }
        }
        Hotkey, %splitButton%, On
        GoSub, StopOnlyAutoSplitter
    return

    doLoop:
        global bossHpHelper
        if (breakLoop)
        {
            global breakLoopLF := 1
            global breakLoop := 1
            SetTimer, doLoop, Off
            SetTimer, updateCorrectStats, Off
            GoSub, updateCorrectStats
        }
        pCorrect := %findFunc%(currentSplitImageInfo)
        if (pCorrect >= threshold)
        {
            global breakLoopLF := 1
            global breakLoop := 1
            SetTimer, doLoop, Off
            SetTimer, updateCorrectStats, Off
            GoSub, updateCorrectStats
            handleSplit(pCorrect)
        }
        if (doubleCheck)
        {
            findBossThere(1)
            if (bossHpHelper >= 60)
            {
                global breakLoopLF := 1
                bossHpHelper := 0
                global breakLoop := 1
                SetTimer, doLoop, Off
                SetTimer, updateCorrectStats, Off
                GoTo, UndoSplit
            }
        }
        nLoops += 1
    return

    lookingFor(var1, var2, var3, var4)
    {
        global breakLoop := 0
        global breakLoopLF := 0
        Sleep, 500
        global findFunc := var1
        global threshold := var2
        global doubleCheck := var3
        global currentSplitImageInfo := var4
        GUIupdate()
        SetTimer, doLoop, 10
        SetTimer, updateCorrectStats, 50
        loop 
        {
            if (breakLoopLF)
                break 
            Sleep, 10
        }
        return
    } 

    handleSplit(pCorrect)
    {
        if (!(currentSplit[3]))
        {
            splitButton := hotKeySettingsArray[1]
            Send, {%splitButton%}
        }
        
        timerText := currentSplit[5] * 1000
        if(currentSplit[2] == "Boss Death")
            timerText := 0
        currentlyLoadedSplitIndex += 1
        waitingForNextSplit := 1 
        GuiControl AutoSplitter:, currerntlyLookingForText, Image Found
        global breakLoop := 0
        SetTimer, waitForNextSplit, 100
        loop, 
        {
            if (!(waitingForNextSplit))
                break 
            Sleep, 10
        }
        SetTimer, waitForNextSplit, Off
        return
    }

    waitForNextSplit:
        if (breakLoop)
        {
            timerText := 0
        }
        timerText -= 100
        timeLeft := Round((timerText/1000), 1)
        GuiControl AutoSplitter:, timerText, %timeleft%
        if (timerText <= 0)
            waitingForNextSplit := 0
    Return

    findNormal(currentSplitImageInfo)
    {
        imageCoordinates := currentSplitImageInfo[2]
        pBitmap := Gdip_BitmapFromScreen(imageCoordinates)
        array := currentSplitImageInfo[3]
        pCorrect := colorCheck(pBitmap, array)
        Gdip_DisposeImage(pBitmap)
        return pCorrect
    }

    findBossDeath(currentSplitImageInfo)
    {
        global imageDataArray
        bossHPCoords := imageDataArray[3]
        pBitmap4 := Gdip_BitmapFromScreen(bossHPCoords)
        isDead := bossHPCheck(pBitmap4, 40, 10)
        if (isDead)
        {
            global bossHpHelper += 1
        }
        pCorrect := round((bossHpHelper/4), 2)
        Gdip_DisposeImage(pBitmap4)
        return pCorrect
    }

    findBossThere(currentSplitImageInfo)
    {
        global imageDataArray
        bossHPCoords := imageDataArray[3]
        pBitmap4 := Gdip_BitmapFromScreen(bossHPCoords)
        isThere := bossHPShowingUp(pBitmap4, 40, 10)
        if (isThere)
        {
            global bossHpHelper += 1
        }
        pCorrect := round((bossHpHelper/6), 2)
        Gdip_DisposeImage(pBitmap)
        return pCorrect
    }

    ResetAutoSplitter:
        Send, {%resetButton%}
        global breakLoop := 1
        global breakLoopLF := 1
        global currentlyLoadedSplitIndex := 999
        global bossHpHelper := 0
        GUIupdate()
        GuiControl Autosplitter:, splitImageNameForGui,
        GuiControl AutoSplitter:, CurrentSplitImage,
        GuiControl AutoSplitter:, timerText, 
        GoSub, updateCorrectStats
        GoSub, updateCorrectStats
    return 

    StopOnlyAutoSplitter:
        global breakLoop := 1
        global breakLoopLF := 1
        global currentlyLoadedSplitIndex := 999
        global bossHpHelper := 0
        GUIupdate()
        GuiControl Autosplitter:, splitImageNameForGui,
        GuiControl AutoSplitter:, CurrentSplitImage,
        GuiControl AutoSplitter:, timerText, 
        GoSub, updateCorrectStats
        GoSub, updateCorrectStats
    Return

    SkipSplit:
        Send, {%skipButton%}
        global breakLoop := 1    
        global breakLoopLF := 1    
        global currentlyLoadedSplitIndex += 1
        GUIupdate()
    return 

    SkipOnlyAutoSplitter:
        global breakLoop := 1
        global breakLoopLF := 1
        global currentlyLoadedSplitIndex += 1
        GUIupdate()
    Return

    UndoSplit:
        Send, {%undoButton%}
        global breakLoop := 1
        global breakLoopLF := 1
        global currentlyLoadedSplitIndex -= 1
        GUIupdate()
    return

    UndoOnlyAutoSplitter:
        global breakLoop := 1
        global breakLoopLF := 1
        global currentlyLoadedSplitIndex -= 1
        GUIupdate()
    Return

    LoadSplitsToUse:
        Gui, Autosplitter: +Disabled
        FileSelectFile, SelectedFile, 3, %A_WorkingDir%\Split_Files\, Open a file, Text Documents (*.txt; *.doc)
        if (!(SelectedFile == ""))
        {
            FileRead, splitFileDataString, %SelectedFile%
            currentlyLoadedSplits := StrSplit(splitFileDataString, "&")
            SelectedFile := StrSplit(SelectedFile, "\")
            SelectedFile := SelectedFile[SelectedFile.MaxIndex()]
            GuiControl Autosplitter:, NameOfLoadedSplits, %SelectedFile%
        }
        Gui, Autosplitter: -Disabled
        Gui, Autosplitter: Show,
    Return

    makePixelArrayString(imageName)
    {
        imageFilePath = %A_WorkingDir%\Split_Images\%imageName%.png
        pBitmap1 := Gdip_CreateBitmapFromFile(imageFilePath)
        makex := 0
        makey := 0
        makeWhite := 0
        makeBlack := 0
        makeTotal := 0
        pixelArrayString =
        Gdip_GetDimensions(pBitmap1, makew, makeh)
        loop %makeh%
        {
            loop %makew%
            {
                if (makey != 0 || makex != 0)
                {
                    pixelArrayString = %pixelArrayString%,
                }
                color := (Gdip_GetPixel(pBitmap1, makex, makey) & 0x00F0F0F0)
                if (color == 0xF0F0F0)
                {
                    makeWhite += 1
                    pixelArrayString = %pixelArrayString%1
                }
                Else
                {
                    makeBlack += 1
                    pixelArrayString = %pixelArrayString%0
                }
                makex += 1
                makeTotal += 1
            }
            makex := 0
            makey += 1
        }
        Gdip_DisposeImage(pBitmap1)
        return pixelArrayString
    }

    colorCheck(pBitmap, Array)
    {
        x := 0
        y := 0
        bCorrect := 0
        wCorrect := 0
        nWrong := 0
        index := 1
        loop %makeh%
        {
            loop %makew%
            {
                color := (Gdip_GetPixel(pBitmap, x, y) & 0x00F0F0F0)
                if (color == 0xF0F0F0)
                {
                    if (Array[index] == "1")
                    {
                        wCorrect += 1
                    }
                    Else
                    {
                        nWrong += 1
                    }
                }
                else 
                {
                    if (Array[index] == "0")
                    {
                        bCorrect += 1
                    }
                    Else
                    {
                        nWrong += 1
                    }
                }
                ; if ((nWrong/(nBlack+nWhite)) >= (1-currentSplit[4]))
                ; {
                ;     break 2
                ; }
                x+= 1
                index += 1
            }
            x := 0
            y += 1
        }
        pCorrect := Round((((bCorrect/makeBlack) + (wCorrect/makeWhite))/2), 2)
        PercCorrectForGui := Round((pCorrect*100), 0)
        WhiteCorrectForGui := Round((wCorrect/makeWhite*100), 0)
        BlackCorrectForGui := Round((bCorrect/makeBlack*100), 0)
        return pCorrect
    }

    bossHPCheck(pBitmap3, hpw, hph)
    {
        isDead := 1
        makex := 0
        makey := 0
        loop %hph%
        {
            loop %hpw%
            {
                pixelColor := Gdip_GetPixel(pBitmap3, makex, makey)
                if (bossHealthBarHashTable.HasKey(pixelColor))
                {
                    isDead := 0
                    break 2
                }
                makex+= 1
            }
            makex := 0
            makey += 1
        }
        if (!isDead)
        {
            global bossHpHelper := 0
        }

        return isDead
    }

    bossHPShowingUp(pBitmap3, hpw, hph)
    {
        isThere := 0
        makex := 0
        makey := 0
        loop %hph%
        {
            loop %hpw%
            {
                pixelColor := Gdip_GetPixel(pBitmap3, makex, makey)
                if (bossHealthBarHashTable.HasKey(pixelColor))
                {
                    isThere := 1
                    break 2
                }
                makex+= 1
            }
            makex := 0
            makey += 1
        }
        if (!isThere)
        {
            global bossHpHelper := 0
        }
        return isThere
    }

    GUIupdate()
    {
        tempGuiVar := StrSplit(currentlyLoadedSplits[currentlyLoadedSplitIndex-2], ",")
        hPrev2 := tempGuiVar[1]
        tempGuiVar := StrSplit(currentlyLoadedSplits[currentlyLoadedSplitIndex-1], ",")
        hPrev := tempGuiVar[1]
        tempGuiVar := StrSplit(currentlyLoadedSplits[currentlyLoadedSplitIndex], ",")
        hCurr := tempGuiVar[1]
        tempGuiVar := StrSplit(currentlyLoadedSplits[currentlyLoadedSplitIndex+1], ",")
        hNext := tempGuiVar[1]
        tempGuiVar := StrSplit(currentlyLoadedSplits[currentlyLoadedSplitIndex+2], ",")
        hNext2 := tempGuiVar[1]
        GuiControl AutoSplitter:, Prev2, %hPrev2%
        GuiControl AutoSplitter:, Prev, Previous: %hPrev%
        GuiControl AutoSplitter:, Curr, Current: %hCurr%
        GuiControl AutoSplitter:, Next, Next: %hNext%
        GuiControl AutoSplitter:, Next2, %hNext2%
        return
    }

    openInfoTab:
        Run, chrome.exe "https://www.youtube.com/@A2TC" " --new-window "
    Return
; ===================================================

; split image maker functionality
    SetDarkColor:
        KeyWait, LButton, D
        MouseGetPos, X, Y 
        PixelGetColor, HPBarDarkColor, %X%, %Y%, RGB
        pGlobalBitmap := Gdip_CreateBitmap(149, 129)
        setBitmapColor(pGlobalBitmap, HPBarDarkColor)
        Gdip_SaveBitmapToFile(pGlobalBitmap, tmpImage)
        GuiControl, HPbarColor:, darkHPColor, %tmpImage%
        Gdip_DisposeImage(pGlobalBitmap)
    Return

    SetLightColor:
        KeyWait, LButton, D
        MouseGetPos, X, Y 
        PixelGetColor, HPBarLightColor, %X%, %Y%, RGB
        pGlobalBitmap := Gdip_CreateBitmap(149, 129)
        setBitmapColor(pGlobalBitmap, HPBarLightColor)
        Gdip_SaveBitmapToFile(pGlobalBitmap, tmpImage)
        GuiControl, HPbarColor:, lightHPColor, %tmpImage%
        Gdip_DisposeImage(pGlobalBitmap)
    Return

    SaveHPBarColors:
        FileRead, imageInfoString, %A_ScriptDir%\Split_Images\image_info.txt
        imageDataArray := StrSplit(imageInfoString, "&")
        imageInfoString = %HPBarDarkColor%&%HPBarLightColor%
        tempIndex := 3
        loop % (imageDataArray.MaxIndex()-2)
        {
            data := imageDataArray[tempIndex]
            imageInfoString = %imageInfoString%&%data%
            tempIndex++
        }
        FileDelete, %A_ScriptDir%\Split_Images\image_info.txt
        FileAppend, %imageInfoString%,%A_ScriptDir%\Split_Images\image_info.txt
        bossHealthBarHashTable := findAllColorsBetween(HPBarDarkColor, HPBarLightColor)
    Return 

    SetBarLocation:
        KeyWait, LButton, D
        MouseGetPos, X, Y
        otherX := X+40
        otherY := Y+10
        updateRect(X, Y, otherX, otherY)
        FileRead, imageInfoString, %A_ScriptDir%\Split_Images\image_info.txt
        imageDataArray := StrSplit(imageInfoString, "&")
        imageInfoString = %HPBarDarkColor%&%HPBarLightColor%&%X%|%Y%|40|10
        tempIndex := 4
        loop % (imageDataArray.MaxIndex()-3)
        {
            data := imageDataArray[tempIndex]
            imageInfoString = %imageInfoString%&%data%
            tempIndex++
        }
        FileDelete, %A_ScriptDir%\Split_Images\image_info.txt
        FileAppend, %imageInfoString%,%A_ScriptDir%\Split_Images\image_info.txt
    Return

    Capture:
        IfWinNotExist, Split Image Maker
            return
        Gui, Screenshot: Cancel,
        temp = 0|0|%A_ScreenWidth%|%A_ScreenHeight%
        pBitmap := Gdip_BitmapFromScreen(temp)
        Gdip_SaveBitmapToFile(pBitmap, scshot)
        Gdip_DisposeImage(pBitmap)
        Gui, Screenshot: -Caption
        Gui, Screenshot: Add, Picture, x0 y0, %A_ScriptDir%\Dependencies\fullScreenshot.png
        Gui, Screenshot: show, h%A_ScreenHeight% w%A_ScreenWidth% x0 y0
        GuiControl imageMaker: +Hidden, Capture
        GuiControl imageMaker: -Hidden, Uncapture 
        Gui, imageMaker: Show
    Return

    Picture:
        LetUserSelectRect(x1, y1, x2, y2)
        setImages(x1, y1, x2, y2)
    Return

    ; adjust image size

        TopDec:
            global y1 := y1 - 1
            updateRect(x1, y1, x2, y2) 
            setImages(x1, y1, x2, y2)
        Return

        10TopDec:
            global y1 := y1 - 10
            updateRect(x1, y1, x2, y2) 
            setImages(x1, y1, x2, y2)
        Return

        TopInc:
            global y1 := y1 + 1
            updateRect(x1, y1, x2, y2) 
            setImages(x1, y1, x2, y2)
        Return

        10TopInc:
            global y1 := y1 + 10
            updateRect(x1, y1, x2, y2) 
            setImages(x1, y1, x2, y2)
        Return

        BotDec:
            global y2 := y2 - 1
            updateRect(x1, y1, x2, y2) 
            setImages(x1, y1, x2, y2)
        Return

        10BotDec:
            global y2 := y2 - 10
            updateRect(x1, y1, x2, y2) 
            setImages(x1, y1, x2, y2)
        Return

        BotInc:
            global y2 := y2 + 1
            updateRect(x1, y1, x2, y2) 
            setImages(x1, y1, x2, y2)
        Return

        10BotInc:
            global y2 := y2 + 10
            updateRect(x1, y1, x2, y2) 
            setImages(x1, y1, x2, y2)
        Return

        LeftDec:
            global x1 := x1 - 1
            updateRect(x1, y1, x2, y2) 
            setImages(x1, y1, x2, y2)
        Return

        10LeftDec:
            global x1 := x1 - 10
            updateRect(x1, y1, x2, y2) 
            setImages(x1, y1, x2, y2)
        Return

        LeftInc:
            global x1 := x1 + 1
            updateRect(x1, y1, x2, y2) 
            setImages(x1, y1, x2, y2)
        Return

        10LeftInc:
            global x1 := x1 + 10
            updateRect(x1, y1, x2, y2) 
            setImages(x1, y1, x2, y2)
        Return

        RightDec:
            global x2 := x2 - 1
            updateRect(x1, y1, x2, y2) 
            setImages(x1, y1, x2, y2)
        Return

        10RightDec:
            global x2 := x2 - 10
            updateRect(x1, y1, x2, y2) 
            setImages(x1, y1, x2, y2)
        Return

        RightInc:
            global x2 := x2 + 1
            updateRect(x1, y1, x2, y2) 
            setImages(x1, y1, x2, y2)
        Return

        10RightInc:
            global x2 := x2 + 10
            updateRect(x1, y1, x2, y2) 
            setImages(x1, y1, x2, y2)
        Return

    Uncapture:
        Gui, Screenshot: Cancel,
        GuiControl imageMaker: +Hidden, Uncapture 
        GuiControl imageMaker: -Hidden, Capture
    Return

    Save:
        Gui, imageMaker: +Disabled
        if (imageCoords == "0|0|1|1") 
        {
            MsgBox, It seems you haven't selected an image.
            Gui, imageMaker: -Disabled
            Gui, imageMaker: Show,
            Return
        }
        if (total >= 1500 || total <= 500)
        {
            MsgBox, Try to keep the total number of pixels between 500 and 1500 to help with performance and accuracy.`nCurrently there are %total% pixels in the selected area
        }

        inputtingImageName:
        InputBox, tempImageName,, What would you like to name this image
        if (!ErrorLevel)
        {
            FileRead, imageInfoString, %A_ScriptDir%\Split_Images\image_info.txt
            imageDataArray := StrSplit(imageInfoString, "&")
            for i, existingImageData in imageDataArray
            {
                temporaryArray := StrSplit(existingImageData, ",")
                if (temporaryArray[1] == tempImageName)
                {
                    MsgBox, 4,, An image with this name already exists.`nWould you like to overwrite it?
                    IfMsgBox No
                        Goto, inputtingImageName
                    Else 
                    {
                        imageDataArray.RemoveAt(i)
                        darkColor := imageDataArray[1]
                        lightColor := imageDataArray[2]
                        imageInfoString = %darkColor%&%lightColor%
                        tempIndex := 3
                        loop % (imageDataArray.MaxIndex()-2)
                        {
                            data := imageDataArray[tempIndex]
                            imageInfoString = %imageInfoString%&%data%
                            tempIndex++
                        }
                    }
                    break
                }
            }
            imageInfoString = %imageInfoString%&%tempImageName%,%imageCoords%
            FileDelete, %A_ScriptDir%\Split_Images\image_info.txt
            FileAppend, %imageInfoString%,%A_ScriptDir%\Split_Images\image_info.txt
            pBitmap := Gdip_CreateBitmapFromFile(realImage)
            filePath = %A_ScriptDir%\Split_Images\%tempImageName%.png
            Gdip_SaveBitmapToFile(pBitmap, filePath)
            Gdip_DisposeImage(pBitmap)
        }
        Gui, imageMaker: -Disabled
        Gui, imageMaker: Show,
    Return

    OpenHPFinder:
        Gui, imageMaker: +Disabled
        Gui, HPbarColor: Show,, Boss HP Bar Color Finder
        SetTimer, colorUnderMouse, 10
        WinWaitClose, Boss HP Bar Color Finder
        SetTimer, colorUnderMouse, Off
        ToolTip
        Gui, imageMaker: -Disabled
        Gui, imageMaker: Show
    Return

    setImages(x1, y1, x2, y2)
    {
        global string = 
        w := x2-x1 
        h := y2-y1 
        GuiControl, imageMaker:, TopNum, %y1%
        GuiControl, imageMaker:, BotNum, %y2%
        GuiControl, imageMaker:, LeftNum, %x1%
        GuiControl, imageMaker:, RightNum, %x2%
        imageCoords = %x1%|%y1%|%w%|%h%
        pBitmap1 := Gdip_BitmapFromScreen(imageCoords)
        pBitmap2 := Gdip_CreateBitmap(w, h)
        x := 0
        y := 0
        nWhite := 0
        nBlack := 0
        total := 0
        loop %h%
        {
            loop %w%
            {
                if (y != 0 || x != 0)
                {
                    string = %string%,
                }
                color := (Gdip_GetPixel(pBitmap1, x, y) & 0x00F0F0F0)
                if (color == 0xF0F0F0)
                {
                    Gdip_SetPixel(pBitmap2, x, y, 0xFFFFFFFF)
                    nWhite += 1
                }
                Else
                {
                    Gdip_SetPixel(pBitmap2, x, y, 0xFF000000)
                    nBlack += 1
                }
                x += 1
                total += 1
            }
            x := 0
            y += 1
        }
        Gdip_SaveBitmapToFile(pBitmap1, realImage)
        Gdip_DisposeImage(pBitmap1)
        Gdip_SaveBitmapToFile(pBitmap2, BnWImage)
        Gdip_DisposeImage(pBitmap2)
        GuiControl, imageMaker:, Real_Pic,
        GuiControl, imageMaker:, BnW_Pic,
        GuiControl, imageMaker:, Real_Pic, %A_ScriptDir%\Dependencies\real_image.png
        GuiControl, imageMaker:, BnW_Pic, %A_ScriptDir%\Dependencies\BnW.png
        GuiControl, imageMaker: Move, Real_Pic, x712 y19 w510 h480
        GuiControl, imageMaker: Move, BnW_Pic, x172 y19 w510 h480
        pWhite := Round(((nWhite/(nBlack + nWhite)) * 100), 2)
        GuiControl, imageMaker:, PW, %pWhite%`%
        GuiControl, imageMaker:, TP, %total%
        return
    }

    setBitmapColor(bitmap, color) 
    {
        x := 0
        y := 0
        Gdip_GetImageDimensions(bitmap, bitmapWidth, bitmapHeight)
        loop %bitmapHeight%
        {
            loop %bitmapWidth%
            {
                argbColor := "0xFF" . SubStr(color, 3)  ; Create ARGB color value
                Gdip_SetPixel(bitmap, x, y, argbColor)
                x += 1
            }
            x := 0
            y += 1
        }
    }

    LetUserSelectRect(ByRef X1, ByRef Y1, ByRef X2, ByRef Y2)
    {

        ; Disable LButton.
        Hotkey, *LButton, lusr_return, On
        ; Wait for user to press LButton.
        KeyWait, LButton, D
        ; Get initial coordinates.
        MouseGetPos, xorigin, yorigin
        ; Set timer for updating the selection rectangle.
        SetTimer, lusr_update, 10
        ; Wait for user to release LButton.
        KeyWait, LButton
        ; Re-enable LButton.
        Hotkey, *LButton, Off
        ; Disable timer.
        SetTimer, lusr_update, Off
        return

        lusr_update:
            MouseGetPos, x, y
            if (x = xlast && y = ylast)
                ; Mouse hasn't moved so there's nothing to do.
                return
            if (x < xorigin)
                    x1 := x, x2 := xorigin
            else x2 := x, x1 := xorigin
            if (y < yorigin)
                    y1 := y, y2 := yorigin
            else y2 := y, y1 := yorigin
            ; Update the "selection rectangle".
            updateRect(x1, y1, x2, y2) 
        lusr_return:
        return
    }

    updateRect(x1, y1, x2, y2, r=2) 
    {
        SetTimer, closeRect, Off
        Gui, 1:Show, % "NA X" x1-r " Y" y1-r " W" x2-x1+r+r " H" r
        Gui, 2:Show, % "NA X" x1 " Y" y2 " W" x2-x1+r " H" r
        Gui, 3:Show, % "NA X" x1-r " Y" y1 " W" r " H" y2-y1+r
        Gui, 4:Show, % "NA X" x2 " Y" y1 " W" r " H" y2-y1+r
        SetTimer, closeRect, 8000
    }

    closeRect:
        Loop 4
            Gui, %A_Index%: Hide
        SetTimer, closeRect, Off
    return

    findAllColorsBetween(darkColor, LightColor)
    {
        darkArray := convertToRGB(darkColor) 
        lightArray := convertToRGB(lightColor) 
        returnHashTable := {}
        redDifference := lightArray[1] - darkArray[1] + 1
        greenDifference := lightArray[2] - darkArray[2] + 1
        blueDifference := lightArray[3] - darkArray[3] + 1
        redIndex := 0
        greenIndex := 0
        blueIndex := 0
        loop, %redDifference%
        {
            loop, %greenDifference%
            {
                loop, %blueDifference%
                {
                    tempColorArray := [(darkArray[1]+redIndex), (darkArray[2]+greenIndex), (darkArray[3]+blueIndex)]
                    tempColor := format("{:s}", convertToHex(tempColorArray))
                    returnHashTable[tempColor] := 1
                    blueIndex++
                }
                blueIndex := 0
                greenIndex++
            }
            greenIndex := 0
            redIndex++
        }
        return returnHashTable
    }

    colorUndermouse:
        MouseGetPos, VarX, VarY
        PixelGetColor, mouseColor, VarX, VarY
        ToolTip, % mouseColor
    return

    convertToHex(array)
    {
        return format("0xff{:02x}{:02x}{:02x}", array*) 
    }

    convertToRGB(color) 
    {
        red := "0x" . SubStr(color, 3, 2)
        green := "0x" . SubStr(color, 5, 2)
        blue := "0x" . SubStr(color, 7, 2)
        array := [format("{:d}", red), format("{:d}", green), format("{:d}", blue)]
        convertToHex(array)
        return array
    }
; ===================================================

; split manager functionality
    RemoveSplit:
        Gui, SplitManager: +Disabled
        InputBox, OutputVar, Remove Split, Which split would you like to remove`n(Leave the input blank to remove the final split)
        if (!ErrorLevel)
        {
            if (OutputVar <= splitManagerIndex)
                removeSplit(OutputVar)
            Else 
                removeSplit(splitManagerIndex)
        }
        Gui, SplitManager: -Disabled
        Gui, SplitManager: Show,
    Return

    AddSplit:
        Gui, SplitManager: +Disabled
        InputBox, OutputVar, Add Split, Where would you like to insert a new split`nSplits at or below that position will be shifted down`n(Leave the input blank to add one at the end)
        if (!ErrorLevel)
        {
            if (OutputVar <= splitManagerIndex)
                makeNewSplit(OutputVar)
            Else 
                makeNewSplit(splitManagerIndex+1)
        }
        Gui, SplitManager: -Disabled
        Gui, SplitManager: Show,
    Return

    LoadSplitFile:
        Gui, SplitManager: +Disabled
        FileSelectFile, SelectedFile, 3, %A_WorkingDir%\Split_Files\, Open a file, Text Documents (*.txt; *.doc)
        if (!(SelectedFile == ""))
        {
            clearSplitManager()
            FileRead, splitFileDataString, %SelectedFile%
            splitFileDataArray := StrSplit(splitFileDataString, "&")
            for i, splitData in splitFileDataArray
            {
                splitDataArray := StrSplit(splitData, ",")
                tempVar1 := splitDataArray[1]
                tempVar2 := splitDataArray[2]
                tempVar3 := splitDataArray[3]
                tempVar4 := splitDataArray[4]
                tempVar5 := splitDataArray[5]
                makeNewSplit(splitManagerIndex, tempVar1, tempVar2, tempVar3, tempVar4, tempVar5)
            }
        }
        Gui, SplitManager: -Disabled
        Gui, SplitManager: Show,
    Return

    SaveSplitFile:
        Gui, SplitManager: +Disabled
        Gui, SplitManager: Submit, NoHide

        inputtingSplitFileName:
        InputBox, tempSplitFileName,, What would you like to name this set of splits
        if (!ErrorLevel)
        {
            tempSplitFileName = %tempSplitFileName%.txt
            splitFilePath = %A_WorkingDir%\Split_Files\%tempSplitFileName%
            if (FileExist(splitFilePath))
            {
                MsgBox, 4,, A split file with this name already exists.`nWould you like to overwrite it?
                IfMsgBox No
                    Goto, inputtingSplitFileName
            }
            stringToSaveToFile := ""
            loop, 
            {
                if (splitName%A_Index% == "" || splitName%A_Index% == " ")
                    break
                cName := splitName%A_Index%
                cImage := splitImage%A_Index%
                cDummy := splitDummyOrNot%A_Index%
                cThresh := splitThreshold%A_Index%
                cDelay := splitDelay%A_Index%
                if (A_index > 1)
                    stringToSaveToFile = %stringToSaveToFile%&%cName%,%cImage%,%cDummy%,%cThresh%,%cDelay%
                Else 
                    stringToSaveToFile = %cName%,%cImage%,%cDummy%,%cThresh%,%cDelay%
            }
            FileDelete, %splitFilePath%
            FileAppend, %stringToSaveToFile%, %splitFilePath%
        }
        Gui, SplitManager: -Disabled
        Gui, SplitManager: Show,
    Return

    clearSplitManager() 
    {
        loop, %splitManagerIndex%
        {
            removeSplit(splitManagerIndex)
        }
        makeNewSplit(1)
    }

    removeSplit(removalIndex)
    {
        global 
        GuiControl SplitManager: Hide, splitName%splitManagerIndex%
        GuiControl SplitManager: Hide, splitImage%splitManagerIndex%
        GuiControl SplitManager: Hide, splitDummyOrNot%splitManagerIndex%
        GuiControl SplitManager: Hide, splitThreshold%splitManagerIndex%
        GuiControl SplitManager: Hide, splitDelay%splitManagerIndex%
        difference := splitManagerIndex - removalIndex
        Gui, SplitManager: Submit, NoHide
        loop, % (difference)
        {
            currentSplitNumber := removalIndex+A_Index
            previousSplitNumber := removalIndex+A_Index-1
            GuiControl SplitManager:, splitName%previousSplitNumber%, % splitName%currentSplitNumber%
            GuiControl SplitManager: ChooseString, splitImage%previousSplitNumber%, % splitImage%currentSplitNumber%
            GuiControl SplitManager:, splitDummyOrNot%previousSplitNumber%, % splitDummyOrNot%currentSplitNumber%
            GuiControl SplitManager:, splitThreshold%previousSplitNumber%, % splitThreshold%currentSplitNumber%
            GuiControl SplitManager:, splitDelay%previousSplitNumber%, % splitDelay%currentSplitNumber%
        } 
        GuiControl SplitManager:, splitName%splitManagerIndex%, 
        GuiControl SplitManager: ChooseString, splitImage%splitManagerIndex%, None
        GuiControl SplitManager:, splitDummyOrNot%splitManagerIndex%, 0
        GuiControl SplitManager:, splitThreshold%splitManagerIndex%, 0.90
        GuiControl SplitManager:, splitDelay%splitManagerIndex%, 7
        splitManagerIndex -= 1
        offset := splitManagerIndex*32
        if (isSplitManagerOpen)
        {
            if (splitManagerIndex > 5)
                Gui, SplitManager: Show, % "h" 45+offset, Split Manager
            else 
                Gui, SplitManager: Show,, Split Manager
        }
    }

    makeNewSplit(insertionIndex, name="", image="None", dummy=0, thresh=0.90, delay=7)
    {
        global 
        splitManagerIndex += 1

        GuiControl SplitManager: Show, splitName%splitManagerIndex%
        GuiControl SplitManager: Show, splitImage%splitManagerIndex%
        GuiControl SplitManager: Show, splitDummyOrNot%splitManagerIndex%
        GuiControl SplitManager: Show, splitThreshold%splitManagerIndex%
        GuiControl SplitManager: Show, splitDelay%splitManagerIndex%

        difference := splitManagerIndex - insertionIndex
        Gui, SplitManager: Submit, NoHide
        loop, % (difference)
        {
            currentSplitNumber := splitManagerIndex-A_Index+1
            previousSplitNumber := splitManagerIndex-A_Index
            GuiControl SplitManager:, splitName%currentSplitNumber%, % splitName%previousSplitNumber%
            GuiControl SplitManager: ChooseString, splitImage%currentSplitNumber%, % splitImage%previousSplitNumber%
            GuiControl SplitManager:, splitDummyOrNot%currentSplitNumber%, % splitDummyOrNot%previousSplitNumber%
            GuiControl SplitManager:, splitThreshold%currentSplitNumber%, % splitThreshold%previousSplitNumber%
            GuiControl SplitManager:, splitDelay%currentSplitNumber%, % splitDelay%previousSplitNumber%
        } 
        GuiControl SplitManager:, splitName%insertionIndex%, %name%
        GuiControl SplitManager: ChooseString, splitImage%insertionIndex%, %image%
        GuiControl SplitManager:, splitDummyOrNot%insertionIndex%, %dummy%
        thresh := Round(thresh, 2)
        GuiControl SplitManager:, splitThreshold%insertionIndex%, %thresh%
        GuiControl SplitManager:, splitDelay%insertionIndex%, %delay%
        offset := splitManagerIndex*32
        if (isSplitManagerOpen)
        {
            if (splitManagerIndex > 5)
                Gui, SplitManager: Show, % "h" 45+offset, Split Manager
            else 
                Gui, SplitManager: Show,, Split Manager
        }
        return
    }

    checkForDeletedImages() 
    {
        FileRead, imageInfoString, %A_ScriptDir%\Split_Images\image_info.txt
        imageDataArray := StrSplit(imageInfoString, "&")
        i := 1
        loop,
        {
            existingImageData := imageDataArray[i]
            if (i == 1)
            {
                data := imageDataArray[i]
                imageInfoString = %data%
            }
            else if (i <= 3)
            {
                data := imageDataArray[i]
                imageInfoString = %imageInfoString%&%data%
            }
            else 
            {
                temporaryArray := StrSplit(existingImageData, ",")
                temporaryImageName := temporaryArray[1]
                temporaryFilePath = %A_ScriptDir%\Split_Images\%temporaryImageName%.png
                if (!(FileExist(temporaryFilePath)))
                {
                    imageDataArray.RemoveAt(i)
                    i--
                }
                else 
                {
                    data := imageDataArray[i]
                    imageInfoString = %imageInfoString%&%data%
                }
            }
            if (i >= imageDataArray.MaxIndex())
                break
            i++
        }
        FileDelete, %A_ScriptDir%\Split_Images\image_info.txt
        FileAppend, %imageInfoString%,%A_ScriptDir%\Split_Images\image_info.txt
    }
; ===================================================

~^F7:: ; Ctrl+F7 to toggle transparency
ToggleScript:
if Activate = 1
{
    Activate = 0
    WinSet, ExStyle, -0x20, %WinTitle%
    WinSet, TransColor, Off, %WinTitle%
}
else
{
    Activate = 1
    WinSet, ExStyle, +0x20, %WinTitle%
    WinSet, TransColor, 0x000000, %WinTitle%
}
return

AutoSplitterGuiClose:    
    Gdip_Shutdown(pToken)
    Gdip_Shutdown(pToken1)
ExitApp

^F4::Reload