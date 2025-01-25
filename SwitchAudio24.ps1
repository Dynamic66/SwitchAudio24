# Initium Automata Scripturae
#region requirements
Add-Type -AssemblyName 'System.Windows.Forms'
Install-Module -Name AudioDeviceCmdlets -Force
#endregion

#region UserConfig
$VerbosePreference = 'Continue'
$pIcon = 'C:\Icons\SwitchAudio_107.ico'
$icon = [System.Drawing.icon]::ExtractAssociatedIcon($pIcon)
	
$SizeWidth = 200
$SizeHeigth = 40
$LocationX = [system.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Width - $SizeWidth
$LocationY = [system.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height - $SizeHeigth
	
$pFeedbackSound = 'C:\Windows\Media\Windows Unlock.wav'
$FeedbackSoundPlayer = [System.Media.SoundPlayer]::new()
$FeedbackSoundPlayer.SoundLocation = $pFeedbackSound
$FeedbackSoundPlayer.Load()

$forColor = [System.Drawing.Color]::WhiteSmoke
$backColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
#endregion

#region Functions

Function Set-NextOutput {
    $playback = Get-AudioDevice -Playback
    $list = Get-AudioDevice -List | Where-Object type -EQ 'Playback'
    $newindex = $playback.index

    $newindex++

    if ($newindex -gt $list.index.Count) {
        $newindex = 1
    }

    Set-AudioDevice -Index $newindex 
    $FeedbackSoundPlayer.Play()
    $lCurrentPlayback.Text = (Get-AudioDevice -Playback).name
    Write-Verbose (Get-AudioDevice -Playback).name

    $script:fadeLvl = 0
    $script:delay = 0

    $script:tHideForm.Enabled = $true
    $script:tHideForm.start()
}


function Main {

    $script:tHideForm = [System.Windows.Forms.Timer]::new()
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
                    $script:tHideForm.stop()
                    $script:tHideForm.Enabled = $flase
                }

            }
            else {
                $form.TopMost = $true
                $form.Opacity = 1
            }
        })

    $lCurrentPlayback = [System.Windows.Forms.Label]::new()
    $lCurrentPlayback.Text = (Get-AudioDevice -Playback).name
    $lCurrentPlayback.AutoSize = $false
    $lCurrentPlayback.Dock = 'fill'
    $lCurrentPlayback.TextAlign = 'MiddleLeft'

    $form = [system.windows.forms.form]::new()
    $form.Icon = $Icon
    $form.Size = [System.Drawing.Size]::new($SizeWidth, $SizeHeigth)
    $form.Location = [System.Drawing.Point]::new($LocationX, $LocationY)
    $form.Opacity = $Opacity
    $form.AutoSize = $false
    $form.BackColor = $backColor
    $form.ForeColor = $forcolor
    $form.FormBorderStyle = 'None'
    $form.StartPosition = 'Manual'
    $form.Padding = '10,5,0,5'
    $form.ShowInTaskbar = $false
    $form.Controls.Add($lCurrentPlayback)
    $form.add_closed({
            $trayIcon.Visible = $false
            
        })

    $contextmenue = [System.Windows.Forms.ContextMenuStrip]::new()
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

    $script:tHideForm.Start()
    $form.ShowDialog()

    #cleanup
    $script:tHideForm.Dispose()
}

#endregion

# Invocatio Automata Scripturae
Main
