
<#
    .NOTES
    --------------------------------------------------------------------------------
     Code generated by:  SAPIEN Technologies, Inc., PowerShell Studio 2024 v5.8.238
     Generated on:       03.03.2024 16:02
     Generated by:       Dynamic66
    --------------------------------------------------------------------------------
    .SYNOPSIS
	 A fast way to switch between audio outputs
	.DESCRIPTION
	 Double Click the Tray Icon or Press alt + s to Switch to the next Audiooutput.
	 Rightclick the Trayicon and select Settings to Configure your experiance.
#>

#region Source: Startup.pss

#----------------------------------------------
#region Import Assemblies
#----------------------------------------------
#endregion Import Assemblies

function Main
{
	Param ([String]$Commandline)
	Add-Type -AssemblyName "System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089"
	Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Keyboard
{
	[DllImport("user32.dll")]
	public static extern short GetAsyncKeyState(int keyCode);
}

"@
	if (Test-Path $configpath)
	{
		Show-SwitchAudio24_psf
	}
	else
	{
		Show-Settings_psf
		Show-SwitchAudio24_psf
	}
	$script:ExitCode = 0
}
#endregion Source: Startup.pss

#region Source: globals.ps1
$script:FeedbackSoundPlayer = New-Object System.Media.SoundPlayer
$script:FeedbackSoundPlayer.SoundLocation = ".\Assets\Beep24.wav"
$script:FeedbackSoundPlayer.Load()

$script:ErrorSoundPlayer = New-Object System.Media.SoundPlayer
$script:ErrorSoundPlayer.SoundLocation = ".\Assets\Boop24.wav"
$script:ErrorSoundPlayer.Load()

$script:configpath = ".\config.conf"
$script:iconpath = ".\Assets\Icon.ico"
$script:iconExite = ".\Assets\Exit.ico"
$script:iconRefresh = ".\Assets\Refresh.ico"
$script:iconSettings = ".\Assets\Settings.ico"

#region functions
function MoveItemsUp
{
	if ($checkedlistbox1.SelectedIndices.Count -eq 0) { return }
	
	if ($checkedlistbox1.selectedindex -gt 0)
	{
		
		$index = $checkedlistbox1.selectedindex
		#switches text
		$checkedListBox1.Items[$index], $checkedListBox1.Items[$index - 1] = $checkedListBox1.Items[$index - 1], $checkedListBox1.Items[$index]
		
		#autoselect new line
		$checkedListBox1.SetSelected($index - 1, $true)
		
		#switches checkmarks around
		$thischeck = $checkedListBox1.GetItemChecked($index)
		$movecheck = $checkedListBox1.GetItemChecked($index - 1)
		$checkedListBox1.SetItemChecked($index - 1, $thischeck)
		$checkedListBox1.SetItemChecked($index, $movecheck)
	}
}

function Load-Audiolist
{
	$combobox1.Items.Clear()
	
	$conf = Get-Content $configpath
	if ($null -ne $conf)
	{
		$script:audiolist = Get-Content $configpath | Select-String "Device=" | ForEach-Object {
			Get-audiodevice -List | Where-Object { $_.type -Like 'playback' } | Where-Object name -Like ($_ -replace "Device=")
		}
		
		$key = (Get-Content -Path $configpath | Select-String "Data=") -replace ("Data=") -replace ' ' -split ','
		$key1 = Invoke-Expression "[system.Windows.Forms.Keys]::$($key[0])"
		$script:key1 = [system.Convert]::toint32($key1)
		$script:key2 = switch ($key[1])
		{
			'Alt' { '0x12' }
			'Shift' { '0x10' }
			'Control' { '0x11' }
			$null { $null }
			default { [system.Convert]::toint32($key2) }
		}
	}
	else
	{
		$script:audiolist = Get-audiodevice -List | Where-Object { $_.type -Like 'playback' }
		$script:key1 = "83"
		$script:key2 = "0x12"
	}
	
	if ($audiolist -eq $null)
	{
		throw "please select a output"
		Show-Settings_psf
	}
	
	$audiolist | ForEach-Object {
		$combobox1.Items.AddRange($_.name)
	}
	
	$combobox1.Text = [string](Get-audiodevice -Playback).name
}

function Invoke-FormFade
{
	param
	(
		[parameter(ParameterSetName = "Fade in")]
		[switch]$FadeIn,
		[parameter(ParameterSetName = "Fade out")]
		[switch]$FadeOut
	)
	
	if ($FadeIn)
	{
		if (-not $formVisible) #stop animation to play when form is already visible
		{
			$formSwitchaudio24.Refresh()
			$formSwitchaudio24.TopMost = $true
			0 .. 10 | ForEach-Object {
				$script:formVisible = $true
				$formSwitchaudio24.Opacity = $_ / 10
				Start-Sleep -Milliseconds 35
			}
			$tTimeout.Enabled = $true
		}
	}
	
	if ($FadeOut)
	{
		$script:formVisible = $false
		10 .. 0 | ForEach-Object {
			if (-not $formVisible)
			{
				$formSwitchaudio24.Opacity = $_ / 10
				Start-Sleep -Milliseconds 10
			}
		}
	}
	
}

function Change-Index
{
	$currentIndex = $comboBox1.SelectedIndex
	
	if ($currentIndex -lt ($comboBox1.Items.Count - 1))
	{
		$comboBox1.SelectedIndex = $currentIndex + 1
	}
	else
	{
		$combobox1.SelectedIndex = 0
	}
}

Function Invoke-Switch
{
	param
	(
		[parameter(Mandatory = $true)]
		[string]$name
	)
	
	if ((Get-audiodevice -playback).name -notlike $name)
	{
		
		$newoutput = ($audiolist | Where-Object name -like $name)
		if ($newoutput.count -eq 1)
		{
			$tTimeout.Enabled = $false
			Set-AudioDevice -InputObject $newoutput
			$script:FeedbackSoundPlayer.Play()
			Invoke-FormFade -FadeIn
			$tTimeout.Enabled = $true
			
		}
		#debug and error info
		elseif ($newoutput.count -gt 1)
		{
			$ErrorSoundPlayer.Play()
			throw "cound not decide between simular named outputs"
			$name | Out-Host
			$audiolist | Out-Host
		}
		elseif ($newoutput.count -le 1)
		{
			$ErrorSoundPlayer.Play()
			throw "did not find matching outputs with the name $name"
			$name | Out-Host
			$audiolist | Out-Host
		}
	}
}
#endregion functions
#endregion Source: globals.ps1

#region Source: Settings.psf
function Show-Settings_psf
{
	#----------------------------------------------
	#region Import the Assemblies
	#----------------------------------------------
	[void][reflection.assembly]::Load('System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.Drawing, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
	#endregion Import Assemblies
	
	#----------------------------------------------
	#region Generated Form Objects
	#----------------------------------------------
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$formsettings = New-Object 'System.Windows.Forms.Form'
	$groupbox2 = New-Object 'System.Windows.Forms.GroupBox'
	$checkedlistbox1 = New-Object 'System.Windows.Forms.CheckedListBox'
	$buttonMoveUp = New-Object 'System.Windows.Forms.Button'
	$groupbox1 = New-Object 'System.Windows.Forms.GroupBox'
	$textbox1 = New-Object 'System.Windows.Forms.TextBox'
	$checkbox1 = New-Object 'System.Windows.Forms.checkbox'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	$groupbox3 = New-Object 'System.Windows.Forms.GroupBox'
	#endregion Generated Form Objects
	
	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
	$formsettings_Load = {
		if (Test-Path $configpath)
		{
			$conf = (Get-Content $configpath | Select-String -pattern "Device=") -replace "Device="
			#load devices from config
			Get-Content $configpath | Select-String "Device=" | ForEach-Object {
				$_ = $_ -replace "Device="
				$checkedlistbox1.Items.Add($_, $true)
			}
			#load all other diabled devices
			Get-audiodevice -List | Where-Object { $_.type -Like 'playback' } | Where-Object { $conf -notcontains $_.name } | ForEach-Object {
				$checkedlistbox1.Items.Add($_.name, $false)
			}
			
			#load startup from config
			$checkbox1.Checked = (Get-Content $configpath | Select-String "Startup=").ToString() -replace "Startup=" -eq $true
			
			#load Hotkey
			$textbox1.Text = Get-Content $configpath | Select-String "data="
			
		}
		else
		{
			#load default
			$textbox1.Text = "Data=S, Alt"
			
			Get-audiodevice -List | Where-Object { $_.type -Like 'playback' } | ForEach-Object {
				$checkedlistbox1.Items.Add($_.name, $true)
			}
			$checkbox1.Checked = $true
		}
	}
	
	$formsettings_FormClosed = [System.Windows.Forms.FormClosedEventHandler]{
		if ([system.Windows.Forms.MessageBox]::Show("Do you want so apply the Changes?", 'Save Changes?', 'yesno', 'question') -eq 'Yes')
		{
			if ($checkedlistbox1.CheckedItems.Count -ne 0)
			{
				Set-Content -path $configpath -Value $null -Encoding UTF8 -Force
				$script:audiolist = $checkedlistbox1.CheckedItems | ForEach-Object {
					"Device=$_" | Out-File -Append -FilePath $configpath -Encoding UTF8 -Force
				}
				($textbox1.Text | Select-String -Pattern "Data=") | Out-File -Append -FilePath $configpath -Encoding UTF8 -Force
				
				Load-Audiolist
			}
			else
			{
				[void][system.Windows.Forms.MessageBox]::Show("No outputs selected, no output changes were made!", 'Error: 0 outputs selected', 'OK', 'Exclamation')
			}
			
			if ($checkbox1.checked)
			{
				try
				{
					$shell = New-Object -ComObject WScript.Shell
					
					$startupFolder = [System.IO.Path]::Combine($env:APPDATA, 'Microsoft\Windows\Start Menu\Programs\Startup')
					$shortcutName = "Switchaudio24.lnk"
					
					$shortcutPath = Join-Path -Path $startupFolder -ChildPath $shortcutName
					
					$scriptPath = $HostInvocation.MyCommand.ToString()
					
					$shortcut = $shell.CreateShortcut($shortcutPath)
					$shortcut.TargetPath = $scriptPath
					$shortcut.WorkingDirectory = [System.IO.Path]::GetDirectoryName($scriptPath)
					$shortcut.Save()
					"Startup=true" | Out-File -Append -FilePath $configpath -Encoding UTF8 -Force
				}
				catch
				{
					[void][system.Windows.Forms.MessageBox]::Show("Something went wronge enabeling Startup!`n$($_.Exception.Message)", 'Error: Startup', 'OK', 'Exclamation')
					"Startup=false" | Out-File -Append -FilePath $configpath -Encoding UTF8 -Force
				}
				
			}
			else
			{
				Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Switchaudio24.lnk"
				"Startup=false" | Out-File -Append -FilePath $configpath -Encoding UTF8 -Force
			}
		}
		
		
	}
	
	$textbox1_KeyDown = [System.Windows.Forms.KeyEventHandler]{
		$_.SuppressKeyPress = $true
		
		if (($_.KeyData -split ',').count -lt 3)
		{
			$textbox1.Text = "Data=$($_.KeyData)"
		}
		
	}
	
	$buttonMoveUp_Click = {
		MoveItemsUp
	}
	# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load =
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$formsettings.WindowState = $InitialFormWindowState
	}
	
	$Form_StoreValues_Closing =
	{
		#Store the control values
		$script:Settings_checkedlistbox1 = $checkedlistbox1.SelectedItems
		$script:Settings_textbox1 = $textbox1.Text
	}
	
	
	$Form_Cleanup_FormClosed =
	{
		#Remove all event handlers from the controls
		try
		{
			$buttonMoveUp.remove_Click($buttonMoveUp_Click)
			$textbox1.remove_KeyDown($textbox1_KeyDown)
			$formsettings.remove_FormClosed($formsettings_FormClosed)
			$formsettings.remove_Load($formsettings_Load)
			$formsettings.remove_Load($Form_StateCorrection_Load)
			$formsettings.remove_Closing($Form_StoreValues_Closing)
			$formsettings.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch { Out-Null <# Prevent PSScriptAnalyzer warning #> }
	}
	#endregion Generated Events
	
	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	$formsettings.SuspendLayout()
	$groupbox1.SuspendLayout()
	$groupbox2.SuspendLayout()
	$groupbox3.SuspendLayout()
	#
	# formsettings
	#
	$formsettings.Controls.Add($checkbox1)
	$formsettings.Controls.Add($groupbox2)
	$formsettings.Controls.Add($groupbox1)
	$formsettings.Controls.Add($groupbox3)
	$formsettings.AutoScaleDimensions = New-Object System.Drawing.SizeF(7, 16)
	$formsettings.AutoScaleMode = 'Font'
	$formsettings.AutoSize = $true
	$formsettings.BackColor = [System.Drawing.Color]::FromArgb(255, 40, 40, 40)
	$formsettings.ClientSize = New-Object System.Drawing.Size(809, 355)
	$formsettings.Font = [System.Drawing.Font]::new('Microsoft Tai Le', '9')
	$formsettings.ForeColor = [System.Drawing.SystemColors]::ButtonHighlight
	$formsettings.Icon = [system.Drawing.Icon]::ExtractAssociatedIcon($iconpath)
	$formsettings.Margin = '4, 4, 4, 4'
	$formsettings.MaximizeBox = $False
	$formsettings.MinimizeBox = $False
	$formsettings.Name = 'formsettings'
	$formsettings.Padding = '7, 7, 7, 7'
	$formsettings.Text = 'Settings'
	$formsettings.TopMost = $True
	$formsettings.add_FormClosed($formsettings_FormClosed)
	$formsettings.add_Load($formsettings_Load)
	#
	# groupbox2
	#
	$groupbox2.Controls.Add($checkedlistbox1)
	$groupbox2.Controls.Add($buttonMoveUp)
	$groupbox2.Anchor = 'Top, Left, Right'
	$groupbox2.AutoSizeMode = 'GrowAndShrink'
	$groupbox2.BackgroundImageLayout = 'None'
	$groupbox2.FlatStyle = 'Flat'
	$groupbox2.ForeColor = [System.Drawing.SystemColors]::ButtonHighlight
	$groupbox2.Location = New-Object System.Drawing.Point(11, 11)
	$groupbox2.Margin = '4, 4, 4, 4'
	$groupbox2.MinimumSize = New-Object System.Drawing.Size(376, 24)
	$groupbox2.Name = 'groupbox2'
	$groupbox2.Padding = '7, 7, 7, 7'
	$groupbox2.Size = New-Object System.Drawing.Size(783, 259)
	$groupbox2.TabIndex = 6
	$groupbox2.TabStop = $False
	$groupbox2.Text = 'Outputs'
	#
	# checkedlistbox1
	#
	$checkedlistbox1.BackColor = [System.Drawing.Color]::FromArgb(255, 50, 50, 50)
	$checkedlistbox1.BorderStyle = 'FixedSingle'
	$checkedlistbox1.ForeColor = [System.Drawing.SystemColors]::ButtonHighlight
	$checkedlistbox1.FormattingEnabled = $True
	$checkedlistbox1.Location = New-Object System.Drawing.Point(8, 60)
	$checkedlistbox1.Margin = '4, 4, 4, 4'
	$checkedlistbox1.Anchor = 'Top, Left, Right'
	$checkedlistbox1.Name = 'checkedlistbox1'
	$checkedlistbox1.Size = New-Object System.Drawing.Size(767, 182)
	$checkedlistbox1.TabIndex = 1
	$checkedlistbox1.ThreeDCheckBoxes = $True
	#
	# buttonMoveUp
	#
	$buttonMoveUp.FlatStyle = 'Flat'
	$buttonMoveUp.Location = New-Object System.Drawing.Point(8, 24)
	$buttonMoveUp.Margin = '4, 4, 4, 4'
	$buttonMoveUp.Name = 'buttonMoveUp'
	$buttonMoveUp.Size = New-Object System.Drawing.Size(88, 28)
	$buttonMoveUp.TabIndex = 6
	$buttonMoveUp.Text = 'Move Up'
	$buttonMoveUp.UseVisualStyleBackColor = $True
	$buttonMoveUp.add_Click($buttonMoveUp_Click)
	#
	# groupbox1
	#
	$groupbox1.Controls.Add($textbox1)
	$groupbox1.Anchor = 'Top, Left, Right'
	$groupbox1.AutoSizeMode = 'GrowAndShrink'
	$groupbox1.BackgroundImageLayout = 'None'
	$groupbox1.FlatStyle = 'Flat'
	$groupbox1.ForeColor = [System.Drawing.SystemColors]::ButtonHighlight
	$groupbox1.Location = New-Object System.Drawing.Point(11, 278)
	$groupbox1.Margin = '4, 4, 4, 4'
	$groupbox1.MinimumSize = New-Object System.Drawing.Size(376, 24)
	$groupbox1.Name = 'groupbox1'
	$groupbox1.Padding = '7, 7, 7, 7'
	$groupbox1.Size = New-Object System.Drawing.Size(787, 61)
	$groupbox1.TabIndex = 5
	$groupbox1.TabStop = $False
	$groupbox1.Text = 'Hotkey'
	#
	# textbox1
	#
	$textbox1.BackColor = [System.Drawing.Color]::FromArgb(255, 50, 50, 50)
	$textbox1.BorderStyle = 'FixedSingle'
	$textbox1.Dock = 'fill'
	$textbox1.Font = [System.Drawing.Font]::new('Microsoft Tai Le', '12')
	$textbox1.ForeColor = [System.Drawing.SystemColors]::ButtonHighlight
	#$textbox1.Location = New-Object System.Drawing.Point(7, 23)
	$textbox1.Margin = '4, 4, 4, 4'
	$textbox1.Name = 'textbox1'
	$textbox1.Size = New-Object System.Drawing.Size(773, 28)
	$textbox1.TabIndex = 1
	$textbox1.add_KeyDown($textbox1_KeyDown)
	#
	#groupbox3
	#
	$groupbox3.Controls.Add($checkbox1)
	$groupbox3.Anchor = 'Top, Left, Right'
	$groupbox3.AutoSizeMode = 'GrowAndShrink'
	$groupbox3.BackgroundImageLayout = 'None'
	$groupbox3.FlatStyle = 'Flat'
	$groupbox3.ForeColor = [System.Drawing.SystemColors]::ButtonHighlight
	$groupbox3.Location = New-Object System.Drawing.Point(11, 350)
	$groupbox3.Margin = '4, 4, 4, 4'
	$groupbox3.MinimumSize = New-Object System.Drawing.Size(376, 24)
	$groupbox3.Name = 'groupbox3'
	$groupbox3.Padding = '7, 7, 7, 7'
	$groupbox3.Size = New-Object System.Drawing.Size(787, 61)
	$groupbox3.TabIndex = 6
	$groupbox3.TabStop = $False
	$groupbox3.Text = 'Startup'
	#
	#checkbox1
	#
	$checkbox1.Text = "Open Switchaudio24 at Startup"
	$checkbox1.Checked = $true
	$checkbox1.Dock = 'Fill'
	
	
	
	$groupbox2.ResumeLayout()
	$groupbox1.ResumeLayout()
	$groupbox3.ResumeLayout()
	$formsettings.ResumeLayout()
	
	#endregion Generated Form Code
	
	#----------------------------------------------
	
	#Save the initial state of the form
	$InitialFormWindowState = $formsettings.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$formsettings.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$formsettings.add_FormClosed($Form_Cleanup_FormClosed)
	#Store the control values when form is closing
	$formsettings.add_Closing($Form_StoreValues_Closing)
	#Show the Form
	return $formsettings.ShowDialog()
	
}
#endregion Source: Settings.psf

#region Source: Show-SwitchAudio24.psf
function Show-SwitchAudio24_psf
{
	#----------------------------------------------
	#region Import the Assemblies
	#----------------------------------------------
	[void][reflection.assembly]::Load('System.Drawing, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
	[void][reflection.assembly]::Load('System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	#endregion Import Assemblies
	
	#----------------------------------------------
	#region Generated Form Objects
	#----------------------------------------------
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$formSwitchaudio24 = New-Object 'System.Windows.Forms.Form'
	$combobox1 = New-Object 'System.Windows.Forms.ComboBox'
	$picturebox1 = New-Object 'System.Windows.Forms.PictureBox'
	$nIcon = New-Object 'System.Windows.Forms.NotifyIcon'
	$tTimeout = New-Object 'System.Windows.Forms.Timer'
	$bswitchNow = New-Object 'System.Windows.Forms.ToolStripMenuItem'
	$bRefreshList = New-Object 'System.Windows.Forms.ToolStripMenuItem'
	$bExit = New-Object 'System.Windows.Forms.ToolStripMenuItem'
	$cMenu = New-Object 'System.Windows.Forms.ContextMenuStrip'
	$tHotkey = New-Object 'System.Windows.Forms.Timer'
	$bSettings = New-Object 'System.Windows.Forms.ToolStripMenuItem'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects
	
	
	#region load
	$formSwitchaudio24_Load = {
		Try
		{
			If (-not (Get-Module -Name AudioDeviceCmdlets -ListAvailable))
			{
				Install-Module -Name AudioDeviceCmdlets -Confirm:$false -Scope AllUsers -Force
			}
		}
		Catch
		{
			[System.Windows.Forms.MessageBox]::Show("Switchaudio24 was not able to load Module AudioDeviceCmdlets.`nPlease try again as Adminstrator.", "Loading Error", 0, [System.Windows.Forms.MessageBoxIcon]::Error)
			$formSwitchaudio24.Close()
		}
		
		# set start position
		$script:monitor = [System.Windows.Forms.Screen]::PrimaryScreen
		$formSwitchaudio24.Location = New-Object System.Drawing.Point(($monitor.WorkingArea.Width - $formSwitchaudio24.Width), ($monitor.WorkingArea.Height - $formSwitchaudio24.Height))
		
		Load-Audiolist
	}
	
	$formSwitchaudio24_Shown = {
		Invoke-FormFade -FadeIn
		$nIcon.Visible = $true
		$tTimeout.Enabled = $true
	}
	#endregion
	
	$tHotkey_Tick = {
		if ($key2)
		{
			if ([keyboard]::GetAsyncKeyState($key1) -and [keyboard]::GetAsyncKeyState($key2))
			{
				$tHotkey.Enabled = $false
				Change-Index
				Start-Sleep -Milliseconds 60
				$tHotkey.Enabled = $true
			}
		}
		else
		{
			if ([keyboard]::GetAsyncKeyState($key1))
			{
				$tHotkey.Enabled = $false
				Change-Index
				Start-Sleep -Milliseconds 60
				$tHotkey.Enabled = $true
			}
		}
	}
	
	$tTimeout_Tick = {
		#makes the from disapear after ~3 seconds
		Invoke-FormFade -Fadeout
		$tTimeout.Enabled = $false
	}
	
	#region IU controls
	$bRefreshList_Click = {
		Load-Audiolist
	}
	
	$combobox1_Click = {
		$combobox1.DroppedDown = $true
	}
	
	$nIcon_MouseDoubleClick = [System.Windows.Forms.MouseEventHandler]{
		Change-Index
	}
	
	$bswitchNow_Click = {
		Change-Index
	}
	
	$combobox1_SelectedIndexChanged = {
		Invoke-Switch -name $combobox1.Text
	}
	
	$formSwitchaudio24_FormClosed = [System.Windows.Forms.FormClosedEventHandler]{
		$nIcon.Visible = $false
	}
	
	$bExit_Click = {
		$ErrorActionPreference = 'SilentlyContinue'
		$formSwitchaudio24.Close()
		$formsettings.close()
	}
	
	$bSettings_Click = {
		Show-Settings_psf
		if ($formVisible)
		{
			$tTimeout.Enabled = $true
		}
	}
	#endregion
	
	
	$Form_StateCorrection_Load =
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$formSwitchaudio24.WindowState = $InitialFormWindowState
	}
	
	$Form_StoreValues_Closing =
	{
		#Store the control values
		$script:SwitchAudio2_combobox1 = $combobox1.Text
		$script:SwitchAudio2_combobox1_SelectedItem = $combobox1.SelectedItem
	}
	
	
	$Form_Cleanup_FormClosed =
	{
		#Remove all event handlers from the controls
		try
		{
			$combobox1.remove_SelectedIndexChanged($combobox1_SelectedIndexChanged)
			$combobox1.remove_Click($combobox1_Click)
			$formSwitchaudio24.remove_FormClosed($formSwitchaudio24_FormClosed)
			$formSwitchaudio24.remove_Load($formSwitchaudio24_Load)
			$formSwitchaudio24.remove_Shown($formSwitchaudio24_Shown)
			$nIcon.remove_MouseDoubleClick($nIcon_MouseDoubleClick)
			$tTimeout.remove_Tick($tTimeout_Tick)
			$bswitchNow.remove_Click($bswitchNow_Click)
			$bRefreshList.remove_Click($bRefreshList_Click)
			$bExit.remove_Click($bExit_Click)
			$tHotkey.remove_Tick($tHotkey_Tick)
			$bSettings.remove_Click($bSettings_Click)
			$formSwitchaudio24.remove_Load($Form_StateCorrection_Load)
			$formSwitchaudio24.remove_Closing($Form_StoreValues_Closing)
			$formSwitchaudio24.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch { Out-Null <# Prevent PSScriptAnalyzer warning #> }
	}
	
	$formSwitchaudio24.SuspendLayout()
	$picturebox1.BeginInit()
	$cMenu.SuspendLayout()
	#
	# formSwitchaudio24
	#
	$formSwitchaudio24.Controls.Add($combobox1)
	$formSwitchaudio24.Controls.Add($picturebox1)
	$formSwitchaudio24.AutoScaleDimensions = New-Object System.Drawing.SizeF(6, 13)
	$formSwitchaudio24.AutoScaleMode = 'Font'
	$formSwitchaudio24.AutoSizeMode = 'GrowAndShrink'
	$formSwitchaudio24.BackColor = [System.Drawing.Color]::FromArgb(255, 40, 40, 40)
	$formSwitchaudio24.ClientSize = New-Object System.Drawing.Size(209, 34)
	$formSwitchaudio24.ContextMenuStrip = $cMenu
	$formSwitchaudio24.ControlBox = $False
	$formSwitchaudio24.FormBorderStyle = 'None'
	$formSwitchaudio24.Icon = $icon
	$formSwitchaudio24.Location = New-Object System.Drawing.Point(1680, 971)
	$formSwitchaudio24.MaximizeBox = $False
	$formSwitchaudio24.MinimizeBox = $False
	$formSwitchaudio24.Name = 'formSwitchaudio24'
	$formSwitchaudio24.Opacity = 0
	$formSwitchaudio24.Padding = '0, 5, 5, 0'
	$formSwitchaudio24.ShowInTaskbar = $False
	$formSwitchaudio24.SizeGripStyle = 'Hide'
	$formSwitchaudio24.StartPosition = 'CenterScreen'
	$formSwitchaudio24.Text = 'Switchaudio24'
	$formSwitchaudio24.TopMost = $True
	$formSwitchaudio24.add_FormClosed($formSwitchaudio24_FormClosed)
	$formSwitchaudio24.add_Load($formSwitchaudio24_Load)
	$formSwitchaudio24.add_Shown($formSwitchaudio24_Shown)
	#
	# combobox1
	#
	$combobox1.BackColor = [System.Drawing.Color]::FromArgb(255, 40, 40, 40)
	$combobox1.Cursor = 'Default'
	$combobox1.Dock = 'Right'
	$combobox1.DropDownStyle = 'DropDownList'
	$combobox1.FlatStyle = 'Flat'
	$combobox1.Font = [System.Drawing.Font]::new('Microsoft Tai Le', '9')
	$combobox1.ForeColor = [System.Drawing.SystemColors]::ButtonHighlight
	$combobox1.Location = New-Object System.Drawing.Point(38, 5)
	$combobox1.Margin = '0, 0, 0, 0'
	$combobox1.Name = 'combobox1'
	$combobox1.Size = New-Object System.Drawing.Size(166, 24)
	$combobox1.TabIndex = 0
	$combobox1.add_SelectedIndexChanged($combobox1_SelectedIndexChanged)
	$combobox1.add_Click($combobox1_Click)
	#
	# picturebox1
	#
	$picturebox1.ContextMenuStrip = $cMenu
	$picturebox1.Image = [system.Drawing.Icon]::ExtractAssociatedIcon($iconpath)
	$picturebox1.Location = New-Object System.Drawing.Point(10, 10)
	$picturebox1.Margin = '0, 0, 0, 0'
	$picturebox1.Name = 'picturebox1'
	$picturebox1.Size = New-Object System.Drawing.Size(16, 16)
	$picturebox1.SizeMode = 'CenterImage'
	$picturebox1.TabIndex = 3
	$picturebox1.TabStop = $False
	$picturebox1.SizeMode = 'Zoom'
	#
	# nIcon
	#
	$nIcon.ContextMenuStrip = $cMenu
	$nIcon.Icon = [system.Drawing.Icon]::ExtractAssociatedIcon($iconpath)
	$nIcon.add_MouseDoubleClick($nIcon_MouseDoubleClick)
	#
	# tTimeout
	#
	$tTimeout.Interval = 3000
	$tTimeout.add_Tick($tTimeout_Tick)
	#
	# bswitchNow
	#
	$bswitchNow.ForeColor = [System.Drawing.SystemColors]::ButtonHighlight
	$bswitchNow.Image = [system.Drawing.Icon]::ExtractAssociatedIcon($iconpath)
	$bswitchNow.Name = 'bswitchNow'
	$bswitchNow.Size = New-Object System.Drawing.Size(135, 22)
	$bswitchNow.Text = 'Switch now'
	$bswitchNow.add_Click($bswitchNow_Click)
	#
	# bRefreshList
	#
	$bRefreshList.ForeColor = [System.Drawing.SystemColors]::ButtonHighlight
	$bRefreshList.Image = [system.Drawing.Icon]::ExtractAssociatedIcon($iconRefresh)
	$bRefreshList.Name = 'bRefreshList'
	$bRefreshList.Size = New-Object System.Drawing.Size(135, 22)
	$bRefreshList.Text = 'Refresh list'
	$bRefreshList.add_Click($bRefreshList_Click)
	#
	# bExit
	#
	$bExit.ForeColor = [System.Drawing.SystemColors]::ButtonHighlight
	$bExit.Image = [system.Drawing.Icon]::ExtractAssociatedIcon($iconExite)
	$bExit.Name = 'bExit'
	$bExit.Size = New-Object System.Drawing.Size(135, 22)
	$bExit.Text = 'EXIT'
	$bExit.add_Click($bExit_Click)
	#
	# cMenu
	#
	$cMenu.BackColor = [System.Drawing.Color]::FromArgb(255, 40, 40, 40)
	[void]$cMenu.Items.Add($bswitchNow)
	[void]$cMenu.Items.Add($bSettings)
	[void]$cMenu.Items.Add($bRefreshList)
	[void]$cMenu.Items.Add($bExit)
	$cMenu.Name = 'contextmenustrip1'
	$cMenu.RenderMode = 'System'
	$cMenu.Size = New-Object System.Drawing.Size(136, 92)
	#
	# tHotkey
	#
	$tHotkey.Enabled = $True
	$tHotkey.Interval = 10
	$tHotkey.add_Tick($tHotkey_Tick)
	#
	# bSettings
	#
	$bSettings.ForeColor = [System.Drawing.SystemColors]::ButtonHighlight
	$bSettings.Image = [system.Drawing.Icon]::ExtractAssociatedIcon($iconSettings)
	$bSettings.Name = 'bSettings'
	$bSettings.Size = New-Object System.Drawing.Size(135, 22)
	$bSettings.Text = 'Settings'
	$bSettings.add_Click($bSettings_Click)
	$cMenu.ResumeLayout()
	$picturebox1.EndInit()
	$formSwitchaudio24.ResumeLayout()
	
	
	#Save the initial state of the form
	$InitialFormWindowState = $formSwitchaudio24.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$formSwitchaudio24.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$formSwitchaudio24.add_FormClosed($Form_Cleanup_FormClosed)
	#Store the control values when form is closing
	$formSwitchaudio24.add_Closing($Form_StoreValues_Closing)
	#Show the Form
	return $formSwitchaudio24.ShowDialog()
	
}
#endregion Source: SwitchAudio24.psf

#Start the application
Main ($CommandLine)