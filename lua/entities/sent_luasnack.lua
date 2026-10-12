--this code sucks
--will rewrite soon
local luasnackadmin = CreateConVar("luasnack_admin", 0, {FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Whetever only admins can edit LuaSnack code.", 0, 1)
local luasnackerrorkill = CreateConVar("luasnack_errorkill", 1, {FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Whetever Lua errors should kill the eater", 0, 1)
AddCSLuaFile()
DEFINE_BASECLASS("base_gmodentity")
ENT.Type	=	"anim"
ENT.Base	=	"base_gmodentity"
ENT.PrintName	=	"LuaSnack"
ENT.Author	=	""
ENT.Information	=	"Yum! Right click to edit code."
ENT.Contact	=	""
ENT.Purpose	=	""
ENT.Category	=	"LuaSnack"
ENT.Spawnable	=	true
ENT.AdminOnly	=	true
if (SERVER) then
    util.AddNetworkString("LuaSnack_UpdateLuaSnackCode")
    util.AddNetworkString("LuaSnack_ControlLuaSnackEditingStatus")
    net.Receive("LuaSnack_UpdateLuaSnackCode", function(len, ply)
        local ent = net.ReadEntity()
        local newcode = net.ReadString()
        if IsValid(ent) then
            ent:SetNW2String("LuaSnackCode", newcode)
        end
    end)
    net.Receive("LuaSnack_ControlLuaSnackEditingStatus", function(len, ply)
        local ent = net.ReadEntity()
        local shouldlock = net.ReadBool()
        if IsValid(ent) then
            ent:SetNW2Bool("IsInUse", shouldlock)
        end
    end)
    function ENT:Initialize()
       self:SetModel("models/xqm/boxfull.mdl")
       self:SetMoveType(MOVETYPE_VPHYSICS)
       self:SetSolid(SOLID_VPHYSICS)
       self:PhysicsInit(SOLID_VPHYSICS)
       self:SetUseType(SIMPLE_USE)
       local phy = self:GetPhysicsObject()
       if phy:IsValid() then 
          phy:Wake()
       end
       self:SetColor(Color(0, 0, 180))
       self:SetNW2String("LuaSnackCode", "")
       self:SetNW2Bool("IsInUse", false)
    end
end
function ENT:OnEat(acter)
    local code = "local eater,snackpos=... " .. self:GetNW2String("LuaSnackCode")
    local func, err = CompileString(code, "LuaSnack", false)
    if not func then
        print("compile error: " .. err)
        return
    end
    local success, result = pcall(func, acter, self:GetPos())
    if not success then
        if luasnackerrorkill:GetBool() then
            acter:Kill()
        end
        -- they wouldnt want this most likely
        --[[local expeff=EffectData()
        expeff:SetOrigin(self:GetPos() + vector_up * 10)
        util.Effect("Explosion",expeff)--]]
        self:EmitSound("buttons/button10.wav", 100)
        acter:SendLua("notification.AddLegacy('" .. result .. "',NOTIFY_ERROR,6)") -- LuaSnack poisoning! (wow no one read this D:)
    end
end
function ENT:Use(activator)
    if self:IsValid() then
        if not self:GetNW2Bool("IsInUse") then
            self:OnEat(activator)
            EmitSound("npc/barnacle/barnacle_crunch3.wav", self:GetPos())
            self:Remove()
        else
            activator:SendLua("notification.AddLegacy(\"You can't eat a LuaSnack that is currently being edited!\", NOTIFY_ERROR, 4) EmitSound(\"buttons/button10.wav\",LocalPlayer():GetPos())")
        end
    end
end
properties.Add("luasnack_setcode", {
    MenuLabel = "Set code...",
    Order = 100,
    MenuIcon = "icon16/script_code.png",
    Filter = function(self, ent, ply)
        return ent:IsValid() and ent:GetClass() == "sent_luasnack"
    end,
    Action = function(self, ent)
        if ent:GetNW2Bool("IsInUse") then
            if (CLIENT) then
                notification.AddLegacy("This LuaSnack is currently being edited by another player!", NOTIFY_ERROR, 4)
                EmitSound("buttons/button10.wav",LocalPlayer():GetPos())
            end
            return
        end
        if !LocalPlayer():IsAdmin() and luasnackadmin:GetInt() == 1 then
            notification.AddLegacy("Only admins can edit LuaSnacks!", NOTIFY_ERROR, 4) EmitSound("buttons/button10.wav",LocalPlayer():GetPos())
        return end
        net.Start("LuaSnack_ControlLuaSnackEditingStatus")
        net.WriteEntity(ent)
        net.WriteBool(true)
        net.SendToServer()
        if (CLIENT) then
            local blacklistedkeywords = {"while", "net", "system", "kick", "http", "debug", "os", "io", "require", "coroutine", "file", "compile", "hook", "concommand", "console", "setusergroup", "for", "render", "cam", "ban", "parent", "util", "sql", "resource", "team"}
            local confirmtext = "Confirm"
            local confirmcolor = Color(0, 180, 180, 150)
            local btncolor = Color(0, 180, 180, 150)
            local basecolor = Color(0, 0, 120, 150)
            local editorbgcolor = Color(0, 0, 0, 220)
            local editorcursorcolor = Color(100, 100, 255)
            local xbtncolor = Color(0, 0, 180)
            local codeeditor = vgui.Create("DFrame")
            codeeditor:SetTitle("")
            codeeditor:SetSize(400, 400)
            codeeditor:SetDraggable(false)
            codeeditor:Center()
            codeeditor:MakePopup()
            codeeditor:ShowCloseButton(false)

            local bg = vgui.Create("DPanel", codeeditor)
            bg:Dock(FILL)
            bg:SetBackgroundColor(color_black)

            function bg:Paint(w, h)
                draw.RoundedBox(8, 0, 0, w, h, editorbgcolor)
            end

            local input = vgui.Create("DTextEntry", bg)
            input:Dock(FILL)
            input:SetPlaceholderText("Enter LuaSnack code here... (511 characters max)")
            input:SetMultiline(true)
            input:SetText(ent:GetNW2String("LuaSnackCode"))
            input:SetMaximumCharCount(511)
            input:SetFont("DefaultFixed")
            input:SetPaintBackground(false)
            input:SetTextColor(color_white)
            input:SetCursorColor(editorcursorcolor)
            input:SetTooltip("You can use the following variables:\neater: refers to the player who ate the LuaSnack\nsnackpos: refers to the position of the LuaSnack\n\nBlacklisted keywords (for non-admins):\n" .. table.concat(blacklistedkeywords, " "))

            local confirmbtn = vgui.Create("DButton", codeeditor)
            confirmbtn:Dock(BOTTOM)
            confirmbtn:SetText("")
            confirmbtn:SetSize(10, 50)
            confirmbtn.DoClick = function()
                if not LocalPlayer():IsAdmin() then
                    for _, word in ipairs(blacklistedkeywords) do
                        if string.find(input:GetText():lower(), word) then
                            confirmbtn:SetEnabled(false)
                            confirmtext = "Your code has blacklisted words! (Admins are immune)"
                            confirmcolor = Color(180, 0, 0, 150)
                            EmitSound("buttons/button10.wav", LocalPlayer():GetPos())
                            timer.Simple(2, function()
                                if confirmbtn:IsValid() then
                                    confirmbtn:SetEnabled(true)
                                    confirmtext = "Confirm"
                                    confirmcolor = Color(0, 180, 180, 150)
                                end
                            end)
                            return
                        end
                    end
                end
                codeeditor:Remove()
                EmitSound("buttons/button14.wav", LocalPlayer():GetPos())
                if ent:IsValid() then
                    net.Start("LuaSnack_UpdateLuaSnackCode")
                    net.WriteEntity(ent)
                    net.WriteString(input:GetText())
                    net.SendToServer()
                end
            end

            local customclosebtn = vgui.Create("DButton", codeeditor)
            customclosebtn:SetPos(370, 5)
            customclosebtn:SetSize(20, 20)
            customclosebtn:SetText("")
            function customclosebtn:Paint(w, h)
                draw.RoundedBox(3, 0, 0, w, h, color_white)
                draw.SimpleText("x", "DermaLarge", 10, -7, xbtncolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end

            customclosebtn.DoClick = function()
                if input:GetText() ~= ent:GetNW2String("LuaSnackCode") then
                    codeeditor:SetMouseInputEnabled(false)
                    codeeditor:SetKeyboardInputEnabled(false)
                    local saveframe = vgui.Create("DFrame")
                    saveframe:SetSize(280, 100)
                    saveframe:SetDraggable(false)
                    saveframe:Center()
                    saveframe:SetTitle("")
                    saveframe:MakePopup()
                    saveframe:ShowCloseButton(false)

                    function saveframe:Paint(w, h)
                        draw.RoundedBox(10, 0, 0, w, h, basecolor)
                        draw.SimpleText("Careful, you have unsaved changes!", "CreditsText", 12, 18, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    end
                    
                    local leavebutton = vgui.Create("DButton", saveframe)
                    leavebutton:Dock(BOTTOM)
                    leavebutton:DockMargin(0, 5, 0, 0)
                    leavebutton:SetSize(100, 25)
                    leavebutton:SetText("")
                    leavebutton.DoClick = function()
                        saveframe:Remove()
                        codeeditor:Remove()
                        EmitSound("buttons/combine_button7.wav", LocalPlayer():GetPos())
                    end
                    function leavebutton:Paint(w, h)
                        draw.RoundedBox(5, 0, 0, w, h, btncolor)
                        draw.SimpleText("Exit without saving changes", "CreditsText", 42, 12, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    end
                    
                    local staybutton = vgui.Create("DButton", saveframe)
                    staybutton:Dock(BOTTOM)
                    staybutton:SetSize(100, 25)
                    staybutton:SetText("")
                    staybutton.DoClick = function()
                        saveframe:Remove()
                        codeeditor:SetMouseInputEnabled(true)
                        codeeditor:SetKeyboardInputEnabled(true)
                        EmitSound("buttons/button9.wav", LocalPlayer():GetPos())
                    end
                    function staybutton:Paint(w, h)
                        draw.RoundedBox(5, 0, 0, w, h, btncolor)
                        draw.SimpleText("Stay", "CreditsText", 124, 12, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    end

                    saveframe.btnClose.DoClick = function()
                        saveframe:Remove()
                        codeeditor:SetMouseInputEnabled(true)
                        codeeditor:SetKeyboardInputEnabled(true)
                    end
                    EmitSound("resource/warning.wav", LocalPlayer():GetPos())
                else
                    codeeditor:Remove()
                    EmitSound("buttons/combine_button7.wav", LocalPlayer():GetPos())
                end
            end
            local uniqueID = math.random()
            hook.Add("EntityRemoved", "LuaSnack_CheckIfTheSnackStillExistsUI" .. uniqueID, function(_ent)
                if _ent == ent then
                    if IsValid(codeeditor) then
                        codeeditor:Remove()
                        hook.Remove("EntityRemoved", "LuaSnack_CheckIfTheSnackStillExistsUI" .. uniqueID)
                    end
                end
            end)
            codeeditor.OnRemove = function()
                if ent:IsValid() then
                    net.Start("LuaSnack_ControlLuaSnackEditingStatus")
                    net.WriteEntity(ent)
                    net.WriteBool(false)
                    net.SendToServer()
                end
                hook.Remove("EntityRemoved", "LuaSnack_CheckIfTheSnackStillExistsUI" .. uniqueID)
            end
            function codeeditor:Paint(wi,he)
                if not wi then local wi = 400 end
                if not he then local he = 400 end
                draw.RoundedBox(10,0,0,wi,he,basecolor)
                draw.SimpleText("LuaSnack Editor", "CloseCaption_Normal", 200, 2.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end
            function confirmbtn:Paint(w,h)
                draw.RoundedBox(10,0,0,w,h,confirmcolor)
                draw.SimpleText(confirmtext, "CreditsText", 193, 13, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end
            EmitSound("buttons/combine_button1.wav", LocalPlayer():GetPos())
        end
    end
})
function ENT:PreEntityCopy()
    local luaSnackCode = self:GetNW2String("LuaSnackCode", "")
    local luasnackdata = {}
    luasnackdata.LuaSnackCode = luaSnackCode
    duplicator.StoreEntityModifier(self, "luasnackdata", luasnackdata)
end
function ENT:PostEntityPaste(ply, ent, createdEntities)
    if (ent.EntityMods and ent.EntityMods.luasnackdata) then
        local luasnackdata = ent.EntityMods.luasnackdata
        self:SetNW2String("LuaSnackCode", luasnackdata.LuaSnackCode)
    end
end
function ENT:Draw() self:DrawModel() end
