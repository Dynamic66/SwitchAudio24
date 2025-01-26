# SwitchAudio24

***This is a little tray app that helps you switch between different audio outputs.***


> This script was created mainly for my own use, but I hope it can help others too.
> If you don't know me personally, please take a moment to review what the script will do on your system.

> ***I'm not responsible if anything goes wrong, but I promise my script is not meant to cause any harm.***

---

### Usage: 

To use it, just double-click the icon in the tray to switch between your audio output options.
If the icon file is missing, the PowerShell icon will serve as a fallback.



---

### Test the script in RAM (no download)

Admin rights are required to install the module ***"AudioDeviceCmdlets"*** on the first run.

Enter the following command in a admin elevated PowerShell terminal (version 5.1 or newer).

```Powershell
Invoke-WebRequest "https://raw.githubusercontent.com/Dynamic66/SwitchAudio24/refs/heads/main/SwitchAudio24.ps1" | Invoke-Expression  
```

