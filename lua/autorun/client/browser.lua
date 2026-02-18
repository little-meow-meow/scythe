
local PANEL = {}

function PANEL:Init()
   self:SetSize(800, 600)
   self:SetSizable(true)
   self:SetMinHeight(128)
   self:SetTitle("Browser")
   self:SetAlpha(200)
   self:Center()
   self:MakePopup()

   self.btnMinim:SetDisabled(false)
   function self.btnMinim.DoClick(this)
      self:Hide()
   end

   local home = "https://wiki.facepunch.com/"
   self.br = self:Add("DHTML")
   self.br:Dock(FILL)

   self.ctrls = self:Add("DHTMLControls")
   self.ctrls:Dock(TOP)
   self.ctrls:SetHTML(self.br)
   self.ctrls.AddressBar:SetText(home)

   self.br:OpenURL(home)

   function self.br.OnChangeTitle(this, newTitle)
      self:SetTitle("Browser - " .. newTitle)
   end
end

vgui.Register("MyBrowser", PANEL, "DFrame")



mybrowser = mybrowser or nil
concommand.Add("mybrowser", function()
   if IsValid(mybrowser) then
      mybrowser:Show()
   else
      mybrowser = vgui.Create("MyBrowser")
   end
end)
