; This context-sensitive hotkey activates only when the Tab key is physically held down.
#If GetKeyState("Tab", "P")
    ` & Del::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/4 _Archieve/p1project"
        Return
#If ; End of context-sensitive hotkey