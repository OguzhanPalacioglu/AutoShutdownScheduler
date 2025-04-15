#SingleInstance Force
#Warn

ShutdownTriggered := false   ; Kapatma işlemi tetiklendi mi kontrolü
CountdownValue := 45         ; Geri sayım başlangıç değeri (saniye)
RetryInterval := 45 * 60 * 1000 ; 45 dakika (milisaniye cinsinden)
RetryTimerActive := false    ; Tekrar zamanlayıcı aktif mi kontrolü

; GUI boyutlarını tanımlayın
GuiWidth := 400
GuiHeight := 350  

; Logo boyutlarını manuel olarak ayarlayın
LogoWidth := 80
LogoHeight := 80

; GUI nesnesi oluştur ve tanımla
MyGui := Gui("+AlwaysOnTop")  
MyGui.SetFont("s12", "Arial")

; "ALKEV Bilgi Sistemleri" yazısını logonun üstüne ortala
TitleWidth := 360
TitleX := (GuiWidth - TitleWidth) // 2  
TitleY := 20
MyGui.Add("Text", Format("x{} y{} w{} Center", TitleX, TitleY, TitleWidth), "ALKEV Bilgi Sistemleri")

; Logo ekle ve tam ortala
LogoPath := A_ScriptDir "\logo.png"
LogoX := (GuiWidth - LogoWidth) // 2
LogoY := TitleY + 30  
MyGui.Add("Picture", Format("x{} y{} w{} h{}", LogoX, LogoY, LogoWidth, LogoHeight), LogoPath)

; Açıklama metni ekle ve tam ortala
TextWidth := 360
TextX := (GuiWidth - TextWidth) // 2
TextY := LogoY + LogoHeight + 20
MyGui.Add("Text", Format("x{} y{} w{}", TextX, TextY, TextWidth), 
    "Bilgisayar 45 saniye içinde kapanacak.`n" 
    . "Eğer kapatılmasını istemiyorsanız 'İptal' butonuna basın.")

; Butonları ekle ve tam ortala
ButtonWidth := 100
ButtonHeight := 30
ButtonY := TextY + 60
CancelButtonX := (GuiWidth // 2) - ButtonWidth - 10
ShutdownButtonX := (GuiWidth // 2) + 10
MyGui.Add("Button", Format("x{} y{} w{} h{}", CancelButtonX, ButtonY, ButtonWidth, ButtonHeight), "İptal Et").OnEvent("Click", CancelShutdown)
MyGui.Add("Button", Format("x{} y{} w{} h{}", ShutdownButtonX, ButtonY, ButtonWidth, ButtonHeight), "Şimdi Kapat").OnEvent("Click", ForceShutdown)

; Geri sayım metni ekle ve tam ortala
CountdownTextWidth := 360
CountdownTextX := (GuiWidth - CountdownTextWidth) // 2
CountdownTextY := ButtonY + 50
CountdownText := MyGui.Add("Text", Format("x{} y{} w{}", CountdownTextX, CountdownTextY, CountdownTextWidth), "Kalan Süre: 45 saniye")

; GUI'yi başlat ve göster
MyGui.OnEvent("Close", GuiClose)
StartCheckLoop()
return

; Saat kontrolü ve döngü
StartCheckLoop() {
    global CountdownValue, ShutdownTriggered, RetryTimerActive
    Loop {
        if (RetryTimerActive) {
            Sleep(1000) ; Eğer 45 dakikalık bekleme varsa döngüyü beklet
            continue
        }
        CurrentTime := A_Hour . A_Min
        if ((CurrentTime > "1600" || CurrentTime < "0730") && !ShutdownTriggered) {
            CountdownValue := 45
            ShutdownTriggered := true
            MyGui.Show(Format("w{} h{}", GuiWidth, GuiHeight))
            SetTimer(UpdateCountdown, 1000)
        }
        Sleep(60000) ; Her dakika kontrol et
    }
}

; Geri sayımı güncelle
UpdateCountdown(*) {
    global CountdownValue, CountdownText, ShutdownTriggered
    if (CountdownValue > 0) {
        CountdownValue--
        CountdownText.Value := Format("Kalan Süre: {} saniye", CountdownValue)
    } else {
        ForceShutdown()
    }
}

; Şimdi kapat butonu işlevi
ForceShutdown(*) {
    Run("shutdown -s -f -t 0")
    ExitApp()
}

; İptal butonu işlevi
CancelShutdown(*) {
    global ShutdownTriggered, RetryTimerActive, CountdownValue
    SetTimer(UpdateCountdown, 0)    ; Geri sayımı durdur
    CountdownValue := 45           ; Geri sayımı sıfırla
    MyGui.Hide()                   ; Ana GUI'yi gizle
    
    ; Özel GUI mesaj kutusu oluştur
    TempGui := Gui("+AlwaysOnTop -SysMenu") ; Mesaj için geçici GUI
    TempGui.MarginX := 20
    TempGui.MarginY := 20
    TempGui.Add("Text", "w300", "Kapatma işlemi iptal edildi.`nSistem bu işlemi 45 dakika sonra tekrar deneyecek.")
    TempGui.Show("AutoSize Center") ; Pencereyi otomatik boyutlandır ve ekranın ortasında göster
    TempGui.Title := "Bilgi"        ; Başlığı ayrı bir şekilde ayarla
    SetTimer(() => TempGui.Destroy(), 5000) ; 5 saniye sonra otomatik olarak kapat

    ShutdownTriggered := false     ; Kapatma işlemini durdur
    RetryTimerActive := true
    SetTimer(RetryShutdown, RetryInterval) ; 45 dakika sonra yeniden çalıştır
}



; 45 dakika sonra yeniden başlat
RetryShutdown(*) {
    global RetryTimerActive, ShutdownTriggered
    RetryTimerActive := false
    ShutdownTriggered := false ; İşlem yeniden başlayabilir
}

; Pencereyi kapatma
GuiClose(*) {
    ExitApp()
}
