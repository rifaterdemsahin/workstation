To update your PowerShell startup script to launch OBS Studio with administrative privileges and set its working directory, you can use the `Start-Process` cmdlet with the `-Verb` parameter set to `"RunAs"` for elevation and the `-WorkingDirectory` parameter to specify the desired starting directory. Here's how you can modify your script:

```powershell
# Launch OBS Studio with administrative privileges
$obsPath = "C:\Program Files\obs-studio\bin\64bit\obs64.exe"
$obsWorkingDirectory = "C:\Program Files\obs-studio\bin\64bit"
Start-Process -FilePath $obsPath -WorkingDirectory $obsWorkingDirectory -Verb RunAs
```

**Explanation:**

- **`$obsPath`**: Specifies the full path to the OBS Studio executable.
- **`$obsWorkingDirectory`**: Sets the working directory for OBS Studio.
- **`Start-Process` Parameters**:
  - **`-FilePath`**: Indicates the application to start.
  - **`-WorkingDirectory`**: Sets the initial directory for the process.
  - **`-Verb RunAs`**: Launches the process with administrative privileges.

By incorporating these parameters, OBS Studio will start elevated and with the specified working directory.

For more details on the `Start-Process` cmdlet and its parameters, you can refer to the official Microsoft documentation. citeturn0search0 
