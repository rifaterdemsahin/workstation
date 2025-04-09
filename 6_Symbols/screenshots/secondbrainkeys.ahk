; This context-sensitive hotkey activates only when the Tab key is physically held down.
#If, GetKeyState("Tab", "P")
    ` & Del::
        Run, obsidian://open?vault=secondbrain&file=secondbrain%2F4%20_Archieve%2Fp1%20project
        Return
#If ; End of context-sensitive hotkey                   