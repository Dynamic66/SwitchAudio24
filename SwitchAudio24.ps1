
#region requirements
Add-Type -AssemblyName 'System.Windows.Forms'
Import-Module -Name AudioDeviceCmdlets -Force
if(-not $?){
    Write-Warning -Message "Module AudioDeviceCmdlets needs to be installed and will require Admin rights to do so."
    Install-Module -Name AudioDeviceCmdlets -Force
}
#endregion

#region UserConfig

$VerbosePreference = 'SilentlyContinue' # set to "Continue" for debugging
$pIcon = "$PSScriptRoot\SwitchAudio24.ico" # replace with the path to .ico or .exe
#matching the path to currently used powershell executable
$pFallbackIcon = (Get-ChildItem "$pshome" -File | Where-Object {$_.name -Match '^p\w.*sh\w*.exe$' -and $_.name -inotmatch "ise"}).FullName 
if (-not (Test-Path $pIcon -ErrorAction SilentlyContinue)) {
    $pIcon = $pFallbackIcon
}

$icon = [System.Drawing.icon]::ExtractAssociatedIcon($pIcon)

$SizeWidth = 250
$SizeHeigth = 39

$pFeedbackSound = "$env:windir\Media\Windows Unlock.wav" # feel free to change this into any other .wav file path

#Color Theme
$forColor = [System.Drawing.Color]::WhiteSmoke
$backColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
#endregion

#region Functions

Function Set-NextOutput {
    param(
        [Array]$DeviceList = (Get-AudioDevice -List | Where-Object type -EQ 'Playback')
    )
    $playback = Get-AudioDevice -Playback
    $newindex = $playback.index

    $newindex++

    if ($newindex -gt $DeviceList.index.Count) {
        $newindex = 1
    }

    Set-AudioDevice -Index $newindex 
    $FeedbackSoundPlayer.Play()
    $lCurrentPlayback.Text = (Get-AudioDevice -Playback).name -replace('\(.*\)')
    Write-Verbose (Get-AudioDevice -Playback).name

    $script:fadeLvl = 0
    $script:delay = 0

    $tHideForm.Enabled = $true
    $tHideForm.start()
}


function Show-SwitchAudio24 {

    $FeedbackSoundPlayer = [System.Media.SoundPlayer]::new()
    $FeedbackSoundPlayer.SoundLocation = $pFeedbackSound
    $FeedbackSoundPlayer.Load()

    $tHideForm = [System.Windows.Forms.Timer]::new()
    $tHideForm.Interval = 15
    $tHideForm.add_tick({

            $script:delay = $script:delay + 1

            if ($script:delay -gt 60) {

                $script:fadeLvl = $script:fadeLvl + 1
                if ($script:fadeLvl -lt 100) {
                    $currentFade = (1 - ($script:fadeLvl / 100))
                    $form.Opacity = $currentFade
                }
                else {
                    $form.Opacity = 0
                    $tHideForm.stop()
                    $tHideForm.Enabled = $flase
                }

            }
            else {
                $form.TopMost = $true
                $form.Opacity = 1
            }
        })

    #UI Layout

    $pBox = [System.Windows.Forms.PictureBox]::new()
    $pBox.dock = [System.Windows.Forms.DockStyle]::left
    $pBox.BackgroundImage = $icon
    $pBox.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::Zoom
    $pBox.Width = 30   

    $lCurrentPlayback = [System.Windows.Forms.Label]::new()
    $lCurrentPlayback.Text = (Get-AudioDevice -Playback).name -replace('\(.*\)')
    $lCurrentPlayback.AutoSize = $false
    $lCurrentPlayback.Dock = [System.Windows.Forms.DockStyle]::Fill
    $lCurrentPlayback.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

    $form = [system.windows.forms.form]::new()
    $form.Icon = $Icon
    $form.MaximumSize = [System.Drawing.Size]::new($SizeWidth, $SizeHeigth)
    $LocationX = [system.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Width - $form.Width
    $LocationY = [system.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height - $form.Height
    $form.Location = [System.Drawing.Point]::new($LocationX, $LocationY)
    $form.Opacity = $Opacity
    $form.AutoSize = $false
    $form.BackColor = $backColor
    $form.ForeColor = $forcolor
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
    $form.Padding = [System.Windows.Forms.Padding]::new(10,10,3,10)
    $form.ShowInTaskbar = $false
    $form.Controls.Add($lCurrentPlayback)
    $form.Controls.add($pBox)

    $contextmenue = [System.Windows.Forms.ContextMenuStrip]::new()
    $contextmenue.BackColor = $backColor
    $contextmenue.ForeColor = $forColor
    $contextmenue.ShowImageMargin = $false
    $bExit = $contextmenue.Items.Add('Exit')
    $bExit.add_click({
            $form.Close()
        })

    $trayIcon = [System.Windows.Forms.NotifyIcon]::new()
    $trayIcon.Icon = $Icon
    $trayIcon.Text = 'Double click to switch to next output'
    $trayIcon.ContextMenuStrip = $contextmenue
    $trayIcon.Visible = $true
    $trayIcon.add_doubleclick({
            Set-NextOutput
        })

    #starting UI
    $tHideForm.Start()
    [System.Windows.Forms.Application]::Run($form)

    #cleanup
    $tHideForm.Dispose()
    $FeedbackSoundPlayer.Dispose()
    $trayIcon.Visible = $false
}

#endregion

Show-SwitchAudio24
