; Complete Keyboard Mapping for Obsidian
; This script creates context-sensitive hotkeys that activate only when the Tab key is physically held down.
; Combined with the backtick (`), almost every key on the keyboard is mapped to an Obsidian URL.

#If GetKeyState("Tab", "P")
    ; Numbers row (1-0)
    ` & 1::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/1 Projects/project-1"
        Return
    ` & 2::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/1 Projects/project-2"
        Return
    ` & 3::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/1 Projects/project-3"
        Return
    ` & 4::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/4 _Archieve/p1project"
        Return
    ` & 5::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/1 Projects/project-5"
        Return
    ` & 6::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/1 Projects/project-6"
        Return
    ` & 7::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/1 Projects/project-7"
        Return
    ` & 8::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/1 Projects/project-8"
        Return
    ` & 9::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/1 Projects/project-9"
        Return
    ` & 0::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/1 Projects/project-10"
        Return
    ` & -::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/Templates"
        Return
    ` & =::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/Settings"
        Return

    ; Top row (QWERTY)
    ` & q::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/Dashboard"
        Return
    ` & w::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/Weekly Review"
        Return
    ` & e::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/2 Areas/education"
        Return
    ` & r::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/reference"
        Return
    ` & t::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/Tasks"
        Return
    ` & y::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/Yearly Goals"
        Return
    ` & u::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/2 Areas/university"
        Return
    ` & i::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/Inbox"
        Return
    ` & o::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/2 Areas/organization"
        Return
    ` & p::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/people"
        Return
    ` & [::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/bookmarks"
        Return
    ` & ]::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/reference-list"
        Return
    ` & \::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/System"
        Return

    ; Middle row (ASDFGHJKL)
    ` & a::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/2 Areas"
        Return
    ` & s::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/2 Areas/self-improvement"
        Return
    ` & d::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/Daily Notes/today"
        Return
    ` & f::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/2 Areas/finance"
        Return
    ` & g::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/2 Areas/goals"
        Return
    ` & h::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/2 Areas/health"
        Return
    ` & j::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/Journal"
        Return
    ` & k::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/2 Areas/knowledge"
        Return
    ` & l::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/links"
        Return
    ` & `;::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/snippets"
        Return
    ` & '::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/quotes"
        Return

    ; Bottom row (ZXCVBNM)
    ` & z::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/zettelkasten"
        Return
    ` & x::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/external-resources"
        Return
    ` & c::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/cheatsheets"
        Return
    ` & v::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/videos"
        Return
    ` & b::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/books"
        Return
    ` & n::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/notes"
        Return
    ` & m::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/Meetings"
        Return
    ` & ,::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/collections"
        Return
    ` & .::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/ideas"
        Return
    ` & /::
        Run, % "obsidian://search?vault=secondbrain"  ; Open search
        Return

    ; Function keys
    ` & F1::
        Run, % "obsidian://open?vault=secondbrain&daily-notes"
        Return
    ` & F2::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Create%20new%20note"
        Return
    ` & F3::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Search"
        Return
    ` & F4::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Toggle%20Pin"
        Return
    ` & F5::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Reload%20app%20without%20saving"
        Return
    ` & F6::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/MOC"
        Return
    ` & F7::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Export%20to%20PDF"
        Return
    ` & F8::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Open%20graph%20view"
        Return
    ` & F9::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Open%20quick%20switcher"
        Return
    ` & F10::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Open%20command%20palette"
        Return
    ` & F11::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Toggle%20full%20screen"
        Return
    ` & F12::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Open%20settings"
        Return

    ; Special keys
    ` & Space::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Quick%20switcher"
        Return
    ` & Tab::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Navigate%20back"
        Return
    ` & Enter::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Follow%20link%20under%20cursor"
        Return
    ` & Backspace::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Navigate%20back"
        Return
    ` & Delete::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/4 _Archieve"
        Return
    ` & Insert::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Insert%20template"
        Return
    ` & Home::
        Run, % "obsidian://open?vault=secondbrain"  ; Open vault home
        Return
    ` & End::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Daily%20notes%3A%20Open%20today%27s%20daily%20note"
        Return
    ` & PgUp::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Go%20forward%20in%20document"
        Return
    ` & PgDn::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Go%20back%20in%20document"
        Return
    ` & CapsLock::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/Index"
        Return
    ` & PrintScreen::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Capture%20screenshot"
        Return
    ` & Pause::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Toggle%20pause%20recording"
        Return
    ` & ScrollLock::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Scroll%20to%20top"
        Return

    ; Arrow keys
    ` & Up::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/MOC"  ; Master table of contents
        Return
    ` & Down::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/Index"  ; Index
        Return
    ` & Left::
        Send, !{Left}  ; Navigate back in Obsidian
        Return
    ` & Right::
        Send, !{Right}  ; Navigate forward in Obsidian
        Return

    ; Numpad keys (if applicable)
    ` & Numpad0::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/tools/tool-0"
        Return
    ` & Numpad1::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/tools/tool-1"
        Return
    ` & Numpad2::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/tools/tool-2"
        Return
    ` & Numpad3::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/tools/tool-3"
        Return
    ` & Numpad4::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/tools/tool-4"
        Return
    ` & Numpad5::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/tools/tool-5"
        Return
    ` & Numpad6::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/tools/tool-6"
        Return
    ` & Numpad7::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/tools/tool-7"
        Return
    ` & Numpad8::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/tools/tool-8"
        Return
    ` & Numpad9::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/tools/tool-9"
        Return
    ` & NumpadDot::
        Run, % "obsidian://open?vault=secondbrain&file=secondbrain/3 Resources/tools/calculator"
        Return
    ` & NumpadAdd::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Create%20new%20note"
        Return
    ` & NumpadSub::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Delete%20current%20file"
        Return
    ` & NumpadMult::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Toggle%20highlight"
        Return
    ` & NumpadDiv::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Split%20vertically"
        Return
    ` & NumpadEnter::
        Run, % "obsidian://advanced-uri?vault=secondbrain&commandname=Follow%20link%20under%20cursor"
        Return

#If ; End of context-sensitive hotkey