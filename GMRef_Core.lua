-- GMRef_Core.lua v1.2.0
-- Compatible Lua 5.0 (Vanilla 1.12), Lua 5.1 (TBC 2.4.3, WotLK 3.3.5)

local ADDON_NAME = "GMRef"
local VERSION    = "1.2.0"
local WIN_W      = 720
local WIN_H      = 520
local TAB_H      = 24
local GOLD       = { r=0.78, g=0.66, b=0.29 }
local GOLD_HEX   = "|cffC8A84B"
local GREEN_HEX  = "|cff55CC77"
local RED_HEX    = "|cffCC5555"
local DIM        = "|cff888888"

-- ============================================================
--  COMPAT LUA 5.0 / 5.1
--  Toutes les fonctions string sont appelees en forme longue
--  string.xxx() au lieu de str:xxx() pour compatibilite 5.0
-- ============================================================

-- Trim whitespace: retourne la chaine sans espaces de debut/fin
local function Trim(s)
    if not s then return "" end
    local result = string.gsub(s, "^%s*(.-)%s*$", "%1")
    return result
end

-- Lowercase safe
local function Lower(s)
    if not s then return "" end
    return string.lower(s)
end

-- Longueur de table compatible 5.0 et 5.1
local function TableLen(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

-- Modulo compatible 5.0
local function Mod(a, b)
    return a - math.floor(a/b) * b
end

-- Verifie si une chaine contient un pattern
local function StrFind(s, pattern, plain)
    if plain then
        return string.find(s, pattern, 1, true)
    end
    return string.find(s, pattern)
end

-- Iterateur sur les captures (remplace gmatch/gfind selon version)
local function GFind(s, pattern)
    if string.gfind then
        return string.gfind(s, pattern)
    else
        return string.gmatch(s, pattern)
    end
end

-- ============================================================
--  SAVED VARIABLES
-- ============================================================
local function InitSettings()
    if not GMRef_Settings then GMRef_Settings = {} end
end

-- ============================================================
--  EXECUTE COMMAND
-- ============================================================
local function ExecCmd(cmd)
    SendChatMessage(cmd, "SAY")
    DEFAULT_CHAT_FRAME:AddMessage(GREEN_HEX..">> "..cmd.."|r", 0.4, 1, 0.5)
end

-- ============================================================
--  INPUT POPUP
-- ============================================================
local InputPopup

local function CreateInputPopup()
    local f = CreateFrame("Frame", "GMRefInputPopup", UIParent)
    f:SetWidth(360); f:SetHeight(130)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
    f:SetMovable(true); f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG"); f:Hide()

    local bg = f:CreateTexture(nil,"BACKGROUND")
    bg:SetAllPoints(f); bg:SetTexture(0.06,0.05,0.03,0.97)
    local bd = CreateFrame("Frame",nil,f); bd:SetAllPoints(f)
    bd:SetBackdrop({edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",edgeSize=20,insets={left=5,right=5,top=5,bottom=5}})
    bd:SetBackdropBorderColor(GOLD.r,GOLD.g,GOLD.b,0.8)

    local title = f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    title:SetPoint("TOPLEFT",f,"TOPLEFT",10,-10)
    title:SetTextColor(GOLD.r,GOLD.g,GOLD.b)
    f.title = title

    local plabel = f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    plabel:SetPoint("TOPLEFT",f,"TOPLEFT",10,-30)
    plabel:SetTextColor(0.75,0.70,0.50)
    f.paramLabel = plabel

    local eb = CreateFrame("EditBox","GMRefInputBox",f)
    eb:SetWidth(330); eb:SetHeight(24)
    eb:SetPoint("TOPLEFT",f,"TOPLEFT",14,-52)
    eb:SetAutoFocus(true)
    eb:SetFontObject("GameFontHighlight")
    eb:SetMaxLetters(128)
    eb:SetTextColor(0.4,1,0.5)
    local ebbg = eb:CreateTexture(nil,"BACKGROUND")
    ebbg:SetAllPoints(eb); ebbg:SetTexture(0,0,0,0.6)
    local ebbd = CreateFrame("Frame",nil,eb); ebbd:SetAllPoints(eb)
    ebbd:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
    ebbd:SetBackdropBorderColor(GOLD.r,GOLD.g,GOLD.b,0.5)
    f.editbox = eb
    eb:SetScript("OnEscapePressed", function() f:Hide() end)

    local btnOK = CreateFrame("Button",nil,f)
    btnOK:SetWidth(140); btnOK:SetHeight(22)
    btnOK:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",14,12)
    local ob = btnOK:CreateTexture(nil,"BACKGROUND"); ob:SetAllPoints(btnOK); ob:SetTexture(0.15,0.40,0.15,0.9)
    local oh = btnOK:CreateTexture(nil,"HIGHLIGHT"); oh:SetAllPoints(btnOK); oh:SetTexture(0.3,0.8,0.3,0.3)
    local ot = btnOK:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    ot:SetAllPoints(btnOK); ot:SetText("|cff55CC77Confirmer|r")
    f.btnOK = btnOK

    local btnX = CreateFrame("Button",nil,f)
    btnX:SetWidth(140); btnX:SetHeight(22)
    btnX:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-14,12)
    local xb = btnX:CreateTexture(nil,"BACKGROUND"); xb:SetAllPoints(btnX); xb:SetTexture(0.40,0.10,0.10,0.9)
    local xh = btnX:CreateTexture(nil,"HIGHLIGHT"); xh:SetAllPoints(btnX); xh:SetTexture(1,0.3,0.3,0.3)
    local xt = btnX:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    xt:SetAllPoints(btnX); xt:SetText("|cffCC5555Annuler|r")
    btnX:SetScript("OnClick", function() f:Hide() end)

    InputPopup = f
end

local function ShowInputPopup(cmd)
    if not InputPopup then CreateInputPopup() end
    local params = {}
    for p in GFind(cmd, "%[(.-)%]") do
        table.insert(params, p)
    end
    InputPopup.title:SetText(GOLD_HEX..cmd.."|r")
    InputPopup.paramLabel:SetText("Parametre(s) : "..table.concat(params, " / "))
    InputPopup.editbox:SetText("")
    InputPopup.editbox:SetFocus()

    local function BuildAndSend()
        local val = Trim(InputPopup.editbox:GetText())
        if val == "" then
            DEFAULT_CHAT_FRAME:AddMessage(RED_HEX.."[GMRef] Valeur vide, annule.|r",1,0.4,0.4)
            InputPopup:Hide()
            return
        end
        local final = cmd
        for _ in GFind(cmd, "%[.-%]") do
            final = string.gsub(final, "%[.-%]", val, 1)
        end
        InputPopup:Hide()
        ExecCmd(final)
    end

    InputPopup.btnOK:SetScript("OnClick", BuildAndSend)
    InputPopup.editbox:SetScript("OnEnterPressed", BuildAndSend)
    InputPopup:Show()
end

local function SendCmd(cmd)
    if StrFind(cmd, "%[") then
        ShowInputPopup(cmd)
    else
        ExecCmd(cmd)
    end
end

-- ============================================================
--  MAIN FRAME
-- ============================================================
local MainFrame, ScrollFrame, ScrollContent
local Tabs = {}
local ActiveTab = 1

local function CreateMainFrame()
    local f = CreateFrame("Frame","GMRefMainFrame",UIParent)
    f:SetWidth(WIN_W); f:SetHeight(WIN_H)
    f:SetPoint("CENTER",UIParent,"CENTER",0,0)
    f:SetMovable(true); f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        GMRef_Settings.posX = self:GetLeft()
        GMRef_Settings.posY = self:GetTop() - UIParent:GetHeight()
    end)
    f:SetFrameStrata("HIGH"); f:Hide()

    local bg = f:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(f); bg:SetTexture(0.06,0.05,0.03,0.97)
    local bd = CreateFrame("Frame",nil,f); bd:SetAllPoints(f)
    bd:SetBackdrop({edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",edgeSize=24,insets={left=6,right=6,top=6,bottom=6}})
    bd:SetBackdropBorderColor(GOLD.r,GOLD.g,GOLD.b,0.8)

    local topline = f:CreateTexture(nil,"ARTWORK"); topline:SetHeight(1)
    topline:SetPoint("TOPLEFT",f,"TOPLEFT",8,-30); topline:SetPoint("TOPRIGHT",f,"TOPRIGHT",-8,-30)
    topline:SetTexture(GOLD.r,GOLD.g,GOLD.b,0.5)

    local titleTxt = f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    titleTxt:SetPoint("TOPLEFT",f,"TOPLEFT",14,-11)
    titleTxt:SetText(GOLD_HEX.."GMRef|r  "..DIM.."v"..VERSION.."|r")

    local close = CreateFrame("Button",nil,f,"UIPanelCloseButton")
    close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-4,-4)
    close:SetScript("OnClick", function() f:Hide() end)

    -- Search box
    local searchBg = f:CreateTexture(nil,"ARTWORK"); searchBg:SetHeight(24)
    searchBg:SetPoint("TOPLEFT",f,"TOPLEFT",8,-31); searchBg:SetPoint("TOPRIGHT",f,"TOPRIGHT",-30,-31)
    searchBg:SetTexture(0,0,0,0.4)

    local searchBox = CreateFrame("EditBox",nil,f)
    searchBox:SetHeight(22)
    searchBox:SetPoint("TOPLEFT",f,"TOPLEFT",10,-31); searchBox:SetPoint("TOPRIGHT",f,"TOPRIGHT",-32,-31)
    searchBox:SetFontObject("GameFontHighlightSmall")
    searchBox:SetTextColor(0.85,0.80,0.65)
    searchBox:SetMaxLetters(64)
    searchBox:SetAutoFocus(false)
    local sbd = CreateFrame("Frame",nil,searchBox); sbd:SetAllPoints(searchBox)
    sbd:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10,insets={left=3,right=3,top=3,bottom=3}})
    sbd:SetBackdropBorderColor(GOLD.r,GOLD.g,GOLD.b,0.3)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
        GMRef_BuildActiveTab()
    end)
    searchBox:SetScript("OnTextChanged", function(self)
        GMRef_DoSearch(self:GetText())
    end)

    local ph = searchBox:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    ph:SetPoint("LEFT",searchBox,"LEFT",4,0)
    ph:SetTextColor(0.45,0.40,0.28)
    ph:SetText("Rechercher une commande...")
    searchBox:SetScript("OnEditFocusGained", function() ph:Hide() end)
    searchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then ph:Show() end
    end)

    MainFrame = f
    MainFrame.searchBox = searchBox
    MainFrame.placeholder = ph
    return f
end

-- ============================================================
--  SCROLL AREA
-- ============================================================
local function CreateScrollArea(parent)
    local sf = CreateFrame("ScrollFrame","GMRefScrollFrame",parent,"UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-(TAB_H+56))
    sf:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT",-28,8)
    local c = CreateFrame("Frame","GMRefScrollContent",sf)
    c:SetWidth(WIN_W - 44); c:SetHeight(1)
    sf:SetScrollChild(c)
    ScrollFrame = sf; ScrollContent = c
end

-- ============================================================
--  CLEAR CONTENT
-- ============================================================
local function ClearContent()
    if ScrollContent then
        ScrollContent:Hide()
        ScrollContent:SetParent(nil)
        ScrollContent = nil
    end
    local c = CreateFrame("Frame", nil, ScrollFrame)
    c:SetWidth(WIN_W - 44); c:SetHeight(1)
    ScrollFrame:SetScrollChild(c)
    ScrollFrame:SetVerticalScroll(0)
    ScrollContent = c
end

-- ============================================================
--  SECTION HEADER
-- ============================================================
local function AddHeader(parent, label, yOff, color)
    local f = CreateFrame("Frame",nil,parent)
    f:SetHeight(20)
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",0,yOff)
    f:SetPoint("TOPRIGHT",parent,"TOPRIGHT",0,yOff)
    local bg = f:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(f)
    bg:SetTexture(color[1]*0.25, color[2]*0.25, color[3]*0.25, 0.6)
    local acc = f:CreateTexture(nil,"ARTWORK"); acc:SetWidth(2)
    acc:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); acc:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",0,0)
    acc:SetTexture(color[1],color[2],color[3],1)
    local txt = f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    txt:SetPoint("LEFT",f,"LEFT",8,0)
    txt:SetTextColor(color[1],color[2],color[3])
    txt:SetText(string.upper(label))
    return f, 20
end

-- ============================================================
--  COMMAND ROW
-- ============================================================
local function AddCmdRow(parent, cmd, desc, yOff, idx)
    local rowH = 20
    local f = CreateFrame("Button",nil,parent)
    f:SetHeight(rowH)
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",0,yOff)
    f:SetPoint("TOPRIGHT",parent,"TOPRIGHT",0,yOff)

    local bgAlpha = 0
    if Mod(idx, 2) == 0 then bgAlpha = 0.05 end
    local bg = f:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(f); bg:SetTexture(1,1,1,bgAlpha)
    local hl = f:CreateTexture(nil,"HIGHLIGHT"); hl:SetAllPoints(f); hl:SetTexture(GOLD.r,GOLD.g,GOLD.b,0.12)

    local sep = f:CreateTexture(nil,"ARTWORK"); sep:SetWidth(1)
    sep:SetPoint("TOPLEFT",f,"TOPLEFT",240,-2)
    sep:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",240,2)
    sep:SetTexture(GOLD.r,GOLD.g,GOLD.b,0.18)

    local ct = f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    ct:SetPoint("LEFT",f,"LEFT",6,0); ct:SetWidth(232); ct:SetJustifyH("LEFT")
    ct:SetText(GREEN_HEX..cmd.."|r")

    local dt = f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    dt:SetPoint("LEFT",f,"LEFT",246,0); dt:SetPoint("RIGHT",f,"RIGHT",-4,0); dt:SetJustifyH("LEFT")
    dt:SetTextColor(0.82,0.77,0.60); dt:SetText(desc)

    f:SetScript("OnClick", function() SendCmd(cmd) end)
    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
        GameTooltip:AddLine(GOLD_HEX..cmd.."|r")
        if StrFind(cmd, "%[") then
            GameTooltip:AddLine("|cffFFCC44Cliquer pour saisir le parametre puis confirmer.|r",1,0.85,0.3)
        else
            GameTooltip:AddLine("|cff55CC77Cliquer pour executer immediatement.|r",0.4,1,0.5)
        end
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return f, rowH
end

-- ============================================================
--  REP ROW
-- ============================================================
local function AddRepRow(parent, name, id, yOff, idx)
    local rowH = 22
    local f = CreateFrame("Frame",nil,parent)
    f:SetHeight(rowH)
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",0,yOff)
    f:SetPoint("TOPRIGHT",parent,"TOPRIGHT",0,yOff)
    local bgAlpha = 0
    if Mod(idx, 2) == 0 then bgAlpha = 0.05 end
    local bg = f:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(f); bg:SetTexture(1,1,1,bgAlpha)

    local nt = f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    nt:SetPoint("LEFT",f,"LEFT",8,0); nt:SetWidth(290); nt:SetJustifyH("LEFT")
    nt:SetTextColor(0.88,0.83,0.68); nt:SetText(name)

    local it = f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    it:SetPoint("LEFT",f,"LEFT",305,0)
    it:SetTextColor(GOLD.r,GOLD.g,GOLD.b)
    it:SetText("ID: "..tostring(id))

    local fid = id

    local btnEx = CreateFrame("Button",nil,f)
    btnEx:SetWidth(78); btnEx:SetHeight(16); btnEx:SetPoint("RIGHT",f,"RIGHT",-86,0)
    local be = btnEx:CreateTexture(nil,"BACKGROUND"); be:SetAllPoints(btnEx); be:SetTexture(0.12,0.40,0.12,0.8)
    local beh = btnEx:CreateTexture(nil,"HIGHLIGHT"); beh:SetAllPoints(btnEx); beh:SetTexture(0.3,0.8,0.3,0.3)
    local bet = btnEx:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    bet:SetAllPoints(btnEx); bet:SetText("|cff55CC77Exalte|r")
    btnEx:SetScript("OnClick", function() ExecCmd(".mod rep "..fid.." 999999") end)
    btnEx:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
        GameTooltip:AddLine(".mod rep "..fid.." 999999",0.4,1,0.5)
        GameTooltip:Show()
    end)
    btnEx:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local btnNt = CreateFrame("Button",nil,f)
    btnNt:SetWidth(78); btnNt:SetHeight(16); btnNt:SetPoint("RIGHT",f,"RIGHT",-2,0)
    local bn = btnNt:CreateTexture(nil,"BACKGROUND"); bn:SetAllPoints(btnNt); bn:SetTexture(0.28,0.22,0.08,0.8)
    local bnh = btnNt:CreateTexture(nil,"HIGHLIGHT"); bnh:SetAllPoints(btnNt); bnh:SetTexture(0.9,0.75,0.3,0.25)
    local bnt = btnNt:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    bnt:SetAllPoints(btnNt); bnt:SetText(GOLD_HEX.."Neutre|r")
    btnNt:SetScript("OnClick", function() ExecCmd(".mod rep "..fid.." 0") end)
    btnNt:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
        GameTooltip:AddLine(".mod rep "..fid.." 0",0.85,0.65,0.2)
        GameTooltip:Show()
    end)
    btnNt:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return f, rowH
end

-- ============================================================
--  MACRO BLOCK
-- ============================================================
local function AddMacroBlock(parent, macro, yOff)
    local f = CreateFrame("Frame",nil,parent)
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",0,yOff)
    f:SetPoint("TOPRIGHT",parent,"TOPRIGHT",-4,yOff)

    local hdr = CreateFrame("Frame",nil,f); hdr:SetHeight(22)
    hdr:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); hdr:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0)
    local hbg = hdr:CreateTexture(nil,"BACKGROUND"); hbg:SetAllPoints(hdr)
    hbg:SetTexture(GOLD.r*0.28, GOLD.g*0.28, GOLD.b*0.28, 0.7)
    local htxt = hdr:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    htxt:SetPoint("LEFT",hdr,"LEFT",8,0)
    htxt:SetTextColor(GOLD.r,GOLD.g,GOLD.b)
    htxt:SetText(macro.label)

    local nbCmds = table.getn(macro.commands)

    local execBtn = CreateFrame("Button",nil,hdr)
    execBtn:SetWidth(120); execBtn:SetHeight(16); execBtn:SetPoint("RIGHT",hdr,"RIGHT",-4,0)
    local eb = execBtn:CreateTexture(nil,"BACKGROUND"); eb:SetAllPoints(execBtn); eb:SetTexture(0.12,0.40,0.12,0.85)
    local eh = execBtn:CreateTexture(nil,"HIGHLIGHT"); eh:SetAllPoints(execBtn); eh:SetTexture(0.3,0.8,0.3,0.3)
    local et = execBtn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    et:SetAllPoints(execBtn); et:SetText("|cff55CC77Tout executer|r")
    execBtn:SetScript("OnClick", function()
        for i = 1, nbCmds do ExecCmd(macro.commands[i]) end
        DEFAULT_CHAT_FRAME:AddMessage(GOLD_HEX.."[GMRef]|r "..nbCmds.." commandes envoyees.",1,0.9,0.4)
    end)

    local cmdH = 0
    for i = 1, nbCmds do
        local cmd = macro.commands[i]
        local row = CreateFrame("Frame",nil,f); row:SetHeight(19)
        row:SetPoint("TOPLEFT",f,"TOPLEFT",0,-(22+cmdH))
        row:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,-(22+cmdH))
        local rbgAlpha = 0
        if Mod(i, 2) == 0 then rbgAlpha = 0.04 end
        local rbg = row:CreateTexture(nil,"BACKGROUND"); rbg:SetAllPoints(row); rbg:SetTexture(1,1,1,rbgAlpha)
        local rt = row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        rt:SetPoint("LEFT",row,"LEFT",8,0); rt:SetTextColor(0.42,0.82,0.52); rt:SetText(cmd)
        cmdH = cmdH + 19
    end

    local total = 22 + cmdH + 6
    f:SetHeight(total)
    return f, total
end

-- ============================================================
--  PROF ROW
-- ============================================================
local function AddProfRow(parent, prof, yOff, idx)
    local rowH = 25
    local f = CreateFrame("Frame",nil,parent)
    f:SetHeight(rowH)
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",0,yOff)
    f:SetPoint("TOPRIGHT",parent,"TOPRIGHT",0,yOff)
    local bgAlpha = 0
    if Mod(idx, 2) == 0 then bgAlpha = 0.05 end
    local bg = f:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(f); bg:SetTexture(1,1,1,bgAlpha)

    local nt = f:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    nt:SetPoint("LEFT",f,"LEFT",8,0); nt:SetWidth(150); nt:SetJustifyH("LEFT")
    nt:SetTextColor(0.88,0.83,0.68); nt:SetText(prof.name)

    local btnL = CreateFrame("Button",nil,f)
    btnL:SetWidth(145); btnL:SetHeight(18); btnL:SetPoint("LEFT",f,"LEFT",168,0)
    local lb = btnL:CreateTexture(nil,"BACKGROUND"); lb:SetAllPoints(btnL); lb:SetTexture(0.08,0.18,0.32,0.85)
    local lh = btnL:CreateTexture(nil,"HIGHLIGHT"); lh:SetAllPoints(btnL); lh:SetTexture(0.3,0.6,1,0.25)
    local lt = btnL:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    lt:SetAllPoints(btnL); lt:SetText("|cff88BBFF.learn "..prof.learnId.."|r")
    btnL:SetScript("OnClick", function() ExecCmd(".learn "..prof.learnId) end)
    btnL:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
        GameTooltip:AddLine("Apprendre "..prof.name)
        GameTooltip:AddLine(".learn "..prof.learnId,0.5,0.8,1)
        GameTooltip:Show()
    end)
    btnL:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local btnS = CreateFrame("Button",nil,f)
    btnS:SetWidth(200); btnS:SetHeight(18); btnS:SetPoint("LEFT",f,"LEFT",322,0)
    local sb = btnS:CreateTexture(nil,"BACKGROUND"); sb:SetAllPoints(btnS); sb:SetTexture(0.12,0.32,0.12,0.85)
    local sh = btnS:CreateTexture(nil,"HIGHLIGHT"); sh:SetAllPoints(btnS); sh:SetTexture(0.3,0.8,0.3,0.25)
    local st = btnS:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    st:SetAllPoints(btnS); st:SetText("|cff55CC77.setskill "..prof.skillId.." 375 375|r")
    btnS:SetScript("OnClick", function() ExecCmd(".setskill "..prof.skillId.." 375 375") end)
    btnS:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
        GameTooltip:AddLine("Monter "..prof.name.." au max (375)")
        GameTooltip:AddLine(".setskill "..prof.skillId.." 375 375",0.4,1,0.5)
        GameTooltip:Show()
    end)
    btnS:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return f, rowH
end

-- ============================================================
--  BUILD FUNCTIONS
-- ============================================================
local function BuildCmdTab(groupIndex)
    ClearContent()
    local yOff = 0
    local rowIdx = 0
    local group = GMRef_Data.Commands[groupIndex]
    if not group then return end
    local nb = table.getn(group.entries)
    for i = 1, nb do
        local entry = group.entries[i]
        rowIdx = rowIdx + 1
        local _, rowH = AddCmdRow(ScrollContent, entry.cmd, entry.desc, -yOff, rowIdx)
        yOff = yOff + rowH
    end
    ScrollContent:SetHeight(yOff + 10)
    ScrollFrame:SetVerticalScroll(0)
end

local function BuildReputations()
    ClearContent()
    local yOff = 0
    local rowIdx = 0
    local nbG = table.getn(GMRef_Data.Reputations)
    for g = 1, nbG do
        local group = GMRef_Data.Reputations[g]
        local _, hH = AddHeader(ScrollContent, group.group, -yOff, group.color)
        yOff = yOff + hH
        local nbE = table.getn(group.entries)
        for e = 1, nbE do
            local entry = group.entries[e]
            rowIdx = rowIdx + 1
            local _, rH = AddRepRow(ScrollContent, entry.name, entry.id, -yOff, rowIdx)
            yOff = yOff + rH
        end
        yOff = yOff + 4
    end
    ScrollContent:SetHeight(yOff + 10)
    ScrollFrame:SetVerticalScroll(0)
end

local function BuildMacros()
    ClearContent()
    local yOff = 6
    local note = ScrollContent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    note:SetPoint("TOPLEFT",ScrollContent,"TOPLEFT",6,-yOff)
    note:SetTextColor(0.65,0.60,0.42)
    note:SetText("Cliquez sur 'Tout executer' pour envoyer toutes les commandes d'un groupe.")
    yOff = yOff + 18
    local nb = table.getn(GMRef_Data.Macros)
    for i = 1, nb do
        local _, bH = AddMacroBlock(ScrollContent, GMRef_Data.Macros[i], -yOff)
        yOff = yOff + bH
    end
    ScrollContent:SetHeight(yOff + 10)
    ScrollFrame:SetVerticalScroll(0)
end

local function BuildProfessions()
    ClearContent()
    local yOff = 0
    local h1 = ScrollContent:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    h1:SetPoint("TOPLEFT",ScrollContent,"TOPLEFT",8,-yOff-5)
    h1:SetTextColor(GOLD.r,GOLD.g,GOLD.b); h1:SetText("Profession")
    local h2 = ScrollContent:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    h2:SetPoint("TOPLEFT",ScrollContent,"TOPLEFT",168,-yOff-5)
    h2:SetTextColor(GOLD.r,GOLD.g,GOLD.b); h2:SetText("Apprendre")
    local h3 = ScrollContent:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    h3:SetPoint("TOPLEFT",ScrollContent,"TOPLEFT",322,-yOff-5)
    h3:SetTextColor(GOLD.r,GOLD.g,GOLD.b); h3:SetText("Monter au max (375)")
    yOff = yOff + 20
    local hl = ScrollContent:CreateTexture(nil,"ARTWORK"); hl:SetHeight(1)
    hl:SetPoint("TOPLEFT",ScrollContent,"TOPLEFT",0,-yOff)
    hl:SetPoint("TOPRIGHT",ScrollContent,"TOPRIGHT",0,-yOff)
    hl:SetTexture(GOLD.r,GOLD.g,GOLD.b,0.25)
    yOff = yOff + 3
    local nb = table.getn(GMRef_Data.Professions)
    for i = 1, nb do
        local _, rH = AddProfRow(ScrollContent, GMRef_Data.Professions[i], -yOff, i)
        yOff = yOff + rH
    end
    ScrollContent:SetHeight(yOff + 10)
    ScrollFrame:SetVerticalScroll(0)
end

-- ============================================================
--  SEARCH
-- ============================================================
function GMRef_DoSearch(query)
    query = Trim(Lower(query))
    if query == "" then
        GMRef_BuildActiveTab()
        return
    end
    ClearContent()
    local yOff = 0
    local rowIdx = 0
    local found = 0
    local nbG = table.getn(GMRef_Data.Commands)
    for g = 1, nbG do
        local group = GMRef_Data.Commands[g]
        local groupMatches = {}
        local nbE = table.getn(group.entries)
        for e = 1, nbE do
            local entry = group.entries[e]
            local combined = Lower(entry.cmd .. " " .. entry.desc)
            if StrFind(combined, query, true) then
                table.insert(groupMatches, entry)
            end
        end
        local nm = table.getn(groupMatches)
        if nm > 0 then
            local _, hH = AddHeader(ScrollContent, group.group, -yOff, {GOLD.r, GOLD.g, GOLD.b})
            yOff = yOff + hH
            for i = 1, nm do
                rowIdx = rowIdx + 1; found = found + 1
                local _, rH = AddCmdRow(ScrollContent, groupMatches[i].cmd, groupMatches[i].desc, -yOff, rowIdx)
                yOff = yOff + rH
            end
            yOff = yOff + 4
        end
    end
    if found == 0 then
        local noRes = ScrollContent:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        noRes:SetPoint("CENTER",ScrollContent,"TOPLEFT",300,-60)
        noRes:SetTextColor(0.55,0.50,0.38)
        noRes:SetText("Aucune commande trouvee pour \""..query.."\"")
    end
    ScrollContent:SetHeight(yOff + 10)
    ScrollFrame:SetVerticalScroll(0)
end

-- ============================================================
--  TAB DEFINITIONS
-- ============================================================
local TAB_DEFS = {
    { label = "Perso",       build = function() BuildCmdTab(1) end },
    { label = "Objets",      build = function() BuildCmdTab(2) end },
    { label = "Quetes",      build = function() BuildCmdTab(3) end },
    { label = "Teleport",    build = function() BuildCmdTab(4) end },
    { label = "Combat/GM",   build = function() BuildCmdTab(5) end },
    { label = "Modifiers",   build = function() BuildCmdTab(6) end },
    { label = "NPC/Monde",   build = function() BuildCmdTab(7) end },
    { label = "Compte/Serv", build = function() BuildCmdTab(8) end },
    { label = "Reputations", build = BuildReputations },
    { label = "Macros",      build = BuildMacros },
    { label = "Professions", build = BuildProfessions },
}

function GMRef_BuildActiveTab()
    if TAB_DEFS[ActiveTab] then TAB_DEFS[ActiveTab].build() end
end

local function SetActiveTab(idx)
    ActiveTab = idx
    if MainFrame.searchBox then
        MainFrame.searchBox:SetText("")
        if MainFrame.placeholder then MainFrame.placeholder:Show() end
    end
    local nb = table.getn(Tabs)
    for i = 1, nb do
        local tab = Tabs[i]
        if i == idx then
            tab.bg:SetTexture(GOLD.r*0.22, GOLD.g*0.22, GOLD.b*0.22, 0.9)
            tab.txt:SetTextColor(GOLD.r,GOLD.g,GOLD.b)
            tab.line:SetTexture(GOLD.r,GOLD.g,GOLD.b,1)
        else
            tab.bg:SetTexture(0,0,0,0)
            tab.txt:SetTextColor(0.55,0.50,0.36)
            tab.line:SetTexture(0,0,0,0)
        end
    end
    GMRef_BuildActiveTab()
end

-- ============================================================
--  CREATE TABS
-- ============================================================
local function CreateTabs(parent)
    local n = table.getn(TAB_DEFS)
    local tabW = math.floor((WIN_W - 16) / n)
    local startY = -56

    for i = 1, n do
        local def = TAB_DEFS[i]
        local btn = CreateFrame("Button",nil,parent)
        btn:SetHeight(TAB_H); btn:SetWidth(tabW)
        btn:SetPoint("TOPLEFT",parent,"TOPLEFT",8+(i-1)*tabW,startY)

        local bg = btn:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(btn); bg:SetTexture(0,0,0,0)
        local line = btn:CreateTexture(nil,"ARTWORK"); line:SetHeight(2)
        line:SetPoint("BOTTOMLEFT",btn,"BOTTOMLEFT",0,0)
        line:SetPoint("BOTTOMRIGHT",btn,"BOTTOMRIGHT",0,0)
        line:SetTexture(0,0,0,0)
        local hl = btn:CreateTexture(nil,"HIGHLIGHT"); hl:SetAllPoints(btn); hl:SetTexture(GOLD.r,GOLD.g,GOLD.b,0.08)
        local txt = btn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); txt:SetAllPoints(btn)
        txt:SetText(def.label); txt:SetTextColor(0.55,0.50,0.36)

        local tabIdx = i
        btn:SetScript("OnClick", function() SetActiveTab(tabIdx) end)
        Tabs[i] = { btn=btn, bg=bg, line=line, txt=txt }
    end
end

-- ============================================================
--  EVENTS & INIT
-- ============================================================
local EventFrame = CreateFrame("Frame")
-- PLAYER_ENTERING_WORLD est universel : Vanilla, TBC, WotLK
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
EventFrame:SetScript("OnEvent", function(self, event)
    if MainFrame then return end  -- evite double init
    InitSettings()
    CreateMainFrame()
    CreateTabs(MainFrame)
    CreateScrollArea(MainFrame)
    if GMRef_Settings.posX and GMRef_Settings.posY then
        MainFrame:ClearAllPoints()
        MainFrame:SetPoint("TOPLEFT",UIParent,"TOPLEFT",GMRef_Settings.posX,GMRef_Settings.posY)
    end
    DEFAULT_CHAT_FRAME:AddMessage(GOLD_HEX.."GMRef |rv"..VERSION.." charge. "..DIM.."/gmref pour ouvrir.|r",1,0.9,0.4)
end)



-- ============================================================
--  SLASH COMMANDS
-- ============================================================
SLASH_GMREF1 = "/gmref"
SlashCmdList["GMREF"] = function(msg)
    local arg = Trim(Lower(msg))

    if arg == "help" or arg == "?" then
        DEFAULT_CHAT_FRAME:AddMessage(GOLD_HEX.."GMRef|r -- Commandes slash :",1,0.9,0.4)
        DEFAULT_CHAT_FRAME:AddMessage("  /gmref         -- ouvre/ferme la fenetre")
        DEFAULT_CHAT_FRAME:AddMessage("  /gmref on      -- .gm on")
        DEFAULT_CHAT_FRAME:AddMessage("  /gmref off     -- .gm off")
        DEFAULT_CHAT_FRAME:AddMessage("  /gmref fly     -- .gm fly on")
        DEFAULT_CHAT_FRAME:AddMessage("  /gmref level 5 -- monte de 5 niveaux")
        DEFAULT_CHAT_FRAME:AddMessage("  /gmref maxskill -- skills au max")
        DEFAULT_CHAT_FRAME:AddMessage("  /gmref help    -- cette aide")

    elseif arg == "on"       then ExecCmd(".gm on")
    elseif arg == "off"      then ExecCmd(".gm off")
    elseif arg == "fly"      then ExecCmd(".gm fly on")
    elseif arg == "maxskill" then ExecCmd(".maxskill")

    elseif string.find(arg, "^level%s+%d+$") then
        local _,_,lvlnum = string.find(arg, "^level%s+(%d+)$")
        if lvlnum then ExecCmd(".levelup "..lvlnum) end

    elseif arg == "" then
        if not MainFrame then
            DEFAULT_CHAT_FRAME:AddMessage(GOLD_HEX.."GMRef:|r Fenetre pas encore prete, reessayez.",1,0.5,0.3)
        elseif MainFrame:IsShown() then
            MainFrame:Hide()
        else
            MainFrame:Show()
            SetActiveTab(ActiveTab or 1)
        end

    else
        DEFAULT_CHAT_FRAME:AddMessage(GOLD_HEX.."GMRef:|r Argument inconnu -- tapez /gmref help",1,0.5,0.3)
    end
end
