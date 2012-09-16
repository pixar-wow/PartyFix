--vars
local dlg_lfgfix_name = "FIX_UNKN_DLG"
local dlg_lfgfix_str = "Des Inconnus dans votre Groupe ! \n Que Voulez vous faire ?"

local unknown_str = "Inconnu"

local cancelstr = "Cacher"

local hide_dlg_lfgfix = false

-- Register slash cmd
SLASH_PARTYFIX1 = '/dgr'
SLASH_PARTYFIX2 = '/debuggr'
SLASH_PARTYFIX3 = '/grd'


local curr_time = 0 --antispam Popup var :)


---------------  Fct ----------------
local function inParty()
   _,indexinParty,_= GetLootMethod()
   return indexinParty~=nil
end

local function inRaidGroup()
   return GetNumRaidMembers()>0
end


local function inLFG()
   mode, _ = GetLFGMode()
   return mode~=nil -- return true if player queued too.
end

-- Call a fct with arg (if any) after waitingTime (in sec)
local function callFctIn(waitingTime,fct,arg)
   local f_tmp = CreateFrame("frame");
   local wait_time=0
   local function onUpdate(self,elapsed)
      wait_time = wait_time + elapsed
      if wait_time >= waitingTime then
         f_tmp:SetScript("OnUpdate", nil);
         if arg~=nil then
            fct(arg)
         else
            fct()
         end
         
      end
   end
   f_tmp:SetScript("OnUpdate", onUpdate);
end


-- FIX party bug on disconection (leave the party on disconect)
function Fix_disco()
   -- Fix Logout
   local old_Logout = Logout; 
   function Logout(...)
      LeaveParty()
      return old_Logout(...);
   end
   
   -- Fix Quit
   local old_Quit = Quit
   function Quit(...)
      LeaveParty()
      return old_Quit(...);
   end
end


-- ============= FIX LFG Party  =============


function SlashCmdList.PARTYFIX(msg, editbox)
   if inParty() or inRaidGroup() then 
      DEFAULT_CHAT_FRAME:AddMessage("Started a LFG Party Debug !")
      PartyFix()
   end
   
end


-- TRY TO FIX LFG party if some1 disconected
-- No Check if player is party leader
function PartyFix()
   local f_pf = CreateFrame("frame");
   
   local function onUpdate(self,elapsed)
      if  inParty() then 
         ConvertToRaid()
      end;
      
      if inRaidGroup() then 
         f_pf:SetScript("OnUpdate", nil);--Stop Update
         ConvertToParty() 
      end
   end
   
   
   f_pf:SetScript("OnUpdate", onUpdate);-- Start Update
end

----------- DETECT & report Unknown Player BUG -------

-- True if there is Unknown player in current party
local function isLFGBug()
   
   if not inParty() then return false end
   --if not inLFG() then return false end
   
   for i = 2,5 do
      local tt ="party"..i
      if UnitExists(tt) and UnitIsDeadOrGhost(tt)~=1 then
         local name,_ = UnitName(tt)
         if name == unknown_str or name == "Unknown" then
            return true
         end
      end
   end
   return false
end

local function hide_dlg_lfgfix_fct()
   hide_dlg_lfgfix = true
   StaticPopup_Hide(dlg_lfgfix_name)
   DEFAULT_CHAT_FRAME:AddMessage("Ce Popup n'apparaitras plus jusqu'au prochain reload !")
end

StaticPopupDialogs[dlg_lfgfix_name] = {
   text = dlg_lfgfix_str,
   button1 = "ReloadUI",
   button2 = cancelstr,
   OnAccept = ReloadUI,
   OnCancel = hide_dlg_lfgfix_fct,
   timeout = 0,
   whileDead = true,
   hideOnEscape = false,
   preferredIndex = 3,
}

function Fix_unknBug()
   local f_fu = PartyFixFrame
   f_fu:RegisterEvent("PARTY_MEMBERS_CHANGED")
   
   local function recheck()
      if isLFGBug() and not hide_dlg_lfgfix then
         StaticPopup_Show(dlg_lfgfix_name)--show Popup
         callFctIn(33, StaticPopup_Hide, dlg_lfgfix_name)-- autohide
      end
   end
   
   local function eventHandler_FixUnknP(self, event, ...)
      if event == "PARTY_MEMBERS_CHANGED" and not hide_dlg_lfgfix and time()-curr_time>45 and isLFGBug() then
         curr_time=time()
         callFctIn(5, recheck)--show Popup if needed
         -- f_fu:UnregisterEvent("PARTY_MEMBERS_CHANGED")
         -- f_fu:SetScript("OnEvent", nil)
      end
      
   end
   f_fu:SetScript("OnEvent", eventHandler_FixUnknP)
end