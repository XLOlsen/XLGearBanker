XLGB_Page = {}
local sV

function XLGB_Page:GetNumberOfPages()
  return #sV.pages
end

function XLGB_Page:CreatePage()
  local x = "X"
  local pageName = "My " .. x .. "LGB Page"
  while XLGB_Page:GetPage(pageName) do
      x = x .. "X"
      pageName = "My " .. x .. "LGB Page"
  end
  local newPage = {
    name = pageName,
    sets = {}
  }
  table.insert(sV.pages, newPage)
end

function XLGB_Page:GetPage(name)
  for _, page in pairs(sV.pages) do
      if page.name == name then
        return page
      end
  end
  return false
end

function XLGB_Page:GetPageByIndex(index)
  return sV.pages[index]
end

function XLGB_Page:GetAllPages()
  return sV.pages
end

function XLGB_Page:RemovePage(name)
  for i, page in pairs(sV.pages) do
    if page.name == name then
      table.remove(sV.pages, i)
      return
    end
  end
end

function XLGB_Page:SetPageName(oldName, newName)
  local page = XLGB_Page:GetPage(oldName)
  local isUnique = not XLGB_Page:GetPage(newName)
  if isUnique then
    page.name = newName
  end
end

local function GetSetIndexInPage(setName, page)
  for i, set in pairs(page.sets) do
    if set.name == setName then
      return i
    end
  end
  return false
end

function XLGB_Page:AddSetToPage(setName, pageName)
  local page = XLGB_Page:GetPage(pageName)
  local isUnique = not GetSetIndexInPage(setName, page)
  if isUnique then
    table.insert(page.sets, setName)
  end
end

function XLGB_Page:RemoveSetFromPage(setName, pageName)
  local page = XLGB_Page:GetPage(pageName)
  local setIndex = GetSetIndexInPage(setName, page)
  if setIndex then
    table.remove(page.sets, setIndex)
  end
end

function XLGB_Page:GetSetsInPage(pageName)
  local page = XLGB_Page:GetPage(pageName)
  return page.sets
end
-- function XLGB_Page:GetPageItems(pageName)
--   local page = XLGB_Page:GetPage(pageName)
--   local tempSet = {}
--   for _, set in pairs(page.sets) do
--   end
-- end
function XLGB_Page:DepositPage(pageName)
  local page = XLGB_Page:GetPage(pageName)
  for _, set in pairs(page.sets) do
    XLGB_Banking:DepositGearSet(set)
  end
  d("[XLGB] Page '" .. pageName .. "' deposited!")

end

function XLGB_Page:WithdrawPage(pageName)
  local page = XLGB_Page:GetPage(pageName)
  for _, set in pairs(page.sets) do
    XLGB_Banking:WithdrawGearSet(set)
  end
  d("[XLGB] Page '" .. pageName .. "' withdrawn!")

end

local function copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
  return res
end

function XLGB_Page:CopyPageSet(pageName)
  return copy(XLGB_Page:GetPage(pageName).sets)
end

function XLGB_Page:Initialize()
  sV = XLGearBanker.savedVariables
  sV.pages = sV.pages or {}
end