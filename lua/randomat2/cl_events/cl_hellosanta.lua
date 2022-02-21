-- Translation strings
hook.Add("Initialize", "RdmtHelloSanta_Translations_Initialize", function()
    if GAMEMODE.FolderName ~= "terrortown" then return end

    LANG.AddToLanguage("english", "rdmtsanta_xmascannon_help_pri", "Use {primaryfire} to give gifts to nice children")
    LANG.AddToLanguage("english", "rdmtsanta_xmascannon_help_sec", "Use {secondaryfire} to shoot coal at naughty children")
end)