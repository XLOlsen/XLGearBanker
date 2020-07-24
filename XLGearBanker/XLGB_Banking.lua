--[[
  XLGB_Banking.lua

  This module contains all functionality related to item transfer.

  Functions:

]]--

--Namespace
XLGB_Banking = {}
local sV

local XLGB = XLGB_Constants

function XLGB_Banking.OnBankOpenEvent(event, bankBag)
  if not XLGB_Banking.bankOpen then
    XLGB_Banking.bankOpen = IsBankOpen()
    XLGB_Banking.currentBankBag = bankBag
    XLGB_UI:OnBankOpen()
    KEYBIND_STRIP:AddKeybindButtonGroup(XLGB_Banking.bankButtonGroup)
    easyDebug("Bank open!")
  end
end

function XLGB_Banking.OnBankCloseEvent(event)
  if XLGB_Banking.bankOpen then
    XLGB_Banking.bankOpen = IsBankOpen()
    XLGB_Banking.currentBankBag = XLGB.NO_BAG
    XLGB_Banking.isMoveCancelled = true
    XLGB_UI:OnBankClosed()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(XLGB_Banking.bankButtonGroup)
    easyDebug("Bank closed")
  end
end

local function findItemIndexInBag(bag, itemID)
  local item_index = XLGB.ITEM_NOT_IN_BAG
  for i = 0, GetBagSize(bag) do
    if (Id64ToString(GetItemUniqueId(bag, i)) == itemID) then
      item_index = i
      return item_index
    end
  end
  return item_index
end

local function findItemsToMove(sourceBag, sourceItems)
  local itemsToMove = {}
  for _, item in pairs(sourceItems) do
    local itemIndex = findItemIndexInBag(sourceBag, item.ID)
    if (itemIndex ~= XLGB.ITEM_NOT_IN_BAG) then
      local itemToMoveEntry = {}
      itemToMoveEntry.item = item
      itemToMoveEntry.index = itemIndex
      table.insert(itemsToMove, itemToMoveEntry)
    end
  end
  return itemsToMove
end


local function getAvailableBagSpaces(bag)
  easyDebug("Finding available bagspaces in bag: " .. bag)
  local availableBagSpaces = {}
  local slot = FindFirstEmptySlotInBag(bag)
  while slot do
    if GetItemName(bag, slot) == "" then
      table.insert(availableBagSpaces, slot)
    end
    slot = ZO_GetNextBagSlotIndex(bag, slot)
  end
  -- for i = firstEmptySlot, GetBagSize(bag) do
  --   if GetItemName(bag, i) == "" then
  --     table.insert(availableBagSpaces, i)
  --   end
  -- end

  easyDebug("Found " .. #availableBagSpaces .. " available spaces in bag.")
  return availableBagSpaces
end

local function stopMovingItems()
  EVENT_MANAGER:UnregisterForEvent(XLGearBanker.name .. "MoveGearFromTwoBags", EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
  EVENT_MANAGER:UnregisterForUpdate(XLGearBanker.name .. "MoveGearFromTwoBags")

  EVENT_MANAGER:UnregisterForEvent(XLGearBanker.name .. "MoveGear", EVENT_INVENTORY_SINGLE_SLOT_UPDATE)

  XLGB_Banking.isWaitingForBag = false
  XLGB_Banking.movesInSuccession = XLGB_Banking.movesInSuccession - 1
  if XLGB_Banking.movesInSuccession < 1 then
    XLGB_Banking.isMovingItems = false
  end
end

local function onMoveFailed(sourceBag, failedAtItemIndex, targetBag, spaceFailedToMoveInto)
  d("---------------------------------")
  d("Failed to move item!")
  d("-")
  d("sourceBag " .. tostring(sourceBag))
  d("failedAtItemIndex " .. tostring(failedAtItemIndex))
  d("targetBag " .. tostring(targetBag))
  d("spaceFailedToMoveInto " .. tostring(spaceFailedToMoveInto))
  d("-")
  d("Item at index = '" .. GetItemName(sourceBag, failedAtItemIndex) ..  "'")
  d("Space = '" .. GetItemName(targetBag, spaceFailedToMoveInto) .. "'")
  d("-")
  d("--------------------------------")
  XLGB_Banking.isMoveCancelled = true
  stopMovingItems()
end

local function moveItem(sourceBag, itemIndex, targetBag, availableSpace)
  -- d("Moving Item at index = '" .. GetItemName(sourceBag, itemIndex) ..  "' to space = '" .. GetItemName(targetBag, availableSpace) .. "'")
  local moveFailed = not CallSecureProtected("RequestMoveItem", sourceBag, itemIndex, targetBag, availableSpace, 1)
  if moveFailed or GetItemName(targetBag, availableSpace) ~= "" then
    onMoveFailed(sourceBag, itemIndex, targetBag, availableSpace)
  end
end

local function moveItemDelayed(sourceBag, itemIndex, targetBag, availableSpace)
  zo_callLater(function () moveItem(sourceBag, itemIndex, targetBag, availableSpace) end, XLGB_Banking.itemMoveDelay)
end

local function updateMoveEvent(eventName, targetBag, lambda)
  d("updateMoveEvent called!")
  if sV.safeMode then
    EVENT_MANAGER:RegisterForEvent(XLGearBanker.name .. eventName, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, lambda)
    EVENT_MANAGER:AddFilterForEvent(XLGearBanker.name .. eventName, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_IS_NEW_ITEM, false)
    EVENT_MANAGER:AddFilterForEvent(XLGearBanker.name .. eventName, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, targetBag)
    EVENT_MANAGER:AddFilterForEvent(XLGearBanker.name .. eventName, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
  else
    EVENT_MANAGER:UnregisterForUpdate(XLGearBanker.name .. eventName)
    EVENT_MANAGER:RegisterForUpdate(XLGearBanker.name .. eventName, XLGB_Banking.itemMoveDelay, lambda)
  end
end

local function moveGear(sourceBag, itemsToMove, targetBag, availableBagSpaces)
  local nextIndex = 1

  local function _onTargetBagItemReceived(eventCode, bagId, slotIndex, isNewItem, itemSoundCategory, updateReason, stackCountChange)
    -- d("Received item!")
    if XLGB_Banking.isMoveCancelled then
      -- d("Move cancelled!")
      return stopMovingItems()
    end
    if nextIndex > #availableBagSpaces then
      -- d("Not enough spaces!")
      return stopMovingItems()
    end
    if (nextIndex > #itemsToMove) then
      -- d("Bag done!")
      return stopMovingItems()
    end
    -- d("(".. tostring(sourceBag) .. ") Moving item [" .. tostring(nextIndex) .. "/" .. tostring(#itemsToMove) .. "]")
    moveItem(sourceBag, itemsToMove[nextIndex].index, targetBag, availableBagSpaces[nextIndex])
    local itemsLeft = #itemsToMove - nextIndex
    XLGB_Events:OnMoveItem(targetBag, itemsLeft)
    nextIndex = nextIndex + 1
  end
  if sV.safeMode then
    EVENT_MANAGER:RegisterForEvent(XLGearBanker.name .. "MoveGear", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, _onTargetBagItemReceived)
    EVENT_MANAGER:AddFilterForEvent(XLGearBanker.name .. "MoveGear", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_IS_NEW_ITEM, false)
    EVENT_MANAGER:AddFilterForEvent(XLGearBanker.name .. "MoveGear", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, targetBag)
    EVENT_MANAGER:AddFilterForEvent(XLGearBanker.name .. "MoveGear", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
  else
    EVENT_MANAGER:UnregisterForUpdate(XLGearBanker.name .. "MoveGear")
    EVENT_MANAGER:RegisterForUpdate(XLGearBanker.name .. "MoveGear", XLGB_Banking.itemMoveDelay, _onTargetBagItemReceived)
  end
  -- d("Source Bag: " .. tostring(sourceBag))
  -- d("ItemsToMove: " .. tostring(#itemsToMove))

  _onTargetBagItemReceived()
end

local function moveGearFromTwoBags(sourceBagOne, itemsToMoveOne, sourceBagTwo, itemsToMoveTwo, targetBag, availableBagSpaces)
  local nextIndex = 1
  local sourceBag = sourceBagOne
  local itemsToMove = itemsToMoveOne
  local availableSpaceOffset = 0

  local function _onTargetBagItemReceived(eventCode, bagId, slotIndex, isNewItem, itemSoundCategory, updateReason, stackCountChange)
    -- d("Received item number " .. tostring(nextIndex-1))
    if XLGB_Banking.isMoveCancelled then
      -- d("Move cancelled!")
      return stopMovingItems()
    end
    if nextIndex > #availableBagSpaces then
      -- d("Not enough space!")
      return stopMovingItems()
    end
    if (nextIndex > #itemsToMove) then

      if sourceBag == sourceBagTwo then 
        -- d("Bag 2 done!")
        return stopMovingItems()
      else
        -- d("Bag 1 done! Swapping to bag 2!")
        availableSpaceOffset = #itemsToMove
        sourceBag = sourceBagTwo
        itemsToMove = itemsToMoveTwo
        nextIndex = 1
        return _onTargetBagItemReceived()
      end
    end
    -- d("(".. tostring(sourceBag) .. ") Moving item [" .. tostring(nextIndex) .. "/" .. tostring(#itemsToMove) .. "]")
    moveItem(sourceBag, itemsToMove[nextIndex].index, targetBag, availableBagSpaces[nextIndex + availableSpaceOffset])
    local itemsLeft = #itemsToMove - nextIndex
    XLGB_Events:OnMoveItem(targetBag, itemsLeft)
    nextIndex = nextIndex + 1
  end

  updateMoveEvent("MoveGearFromTwoBags", targetBag, _onTargetBagItemReceived)
  
  -- d("Source Bag 1: " .. tostring(sourceBagOne))
  -- d("ItemsToMove 1: " .. tostring(#itemsToMoveOne))
  -- d("-")
  -- d("Source Bag 2: " .. tostring(sourceBagTwo))
  -- d("ItemsToMove 2: " .. tostring(#itemsToMoveTwo))
  -- d("-")
  -- d("Equipment bag: " .. tostring(BAG_WORN))
  -- d("Backpack bag: " .. tostring(BAG_BACKPACK))
  -- d("-")

  _onTargetBagItemReceived()
end

--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--
--
--
--                                        WITHDRAW FUNCTIONS
--
--
--
--------------------------------------------------------------------------------------------

local function withdrawGearESOPlus(gearSet)
  d("withdrawGearESOPlus")
  local regularBankItemsToMove = findItemsToMove(BAG_BANK, gearSet.items)
  local ESOPlusItemsToMove = findItemsToMove(BAG_SUBSCRIBER_BANK, gearSet.items)
  local availableBagSpaces = getAvailableBagSpaces(BAG_BACKPACK)
  local numberOfItemsToMove = #regularBankItemsToMove + #ESOPlusItemsToMove
  if (#availableBagSpaces < numberOfItemsToMove) then
    d("[XLGB_ERROR] Trying to move " .. numberOfItemsToMove.. "items into a bag with " .. #availableBagSpaces .." empty slots.")
    return false
  end
  moveGearFromTwoBags(
      BAG_BANK, regularBankItemsToMove,
      BAG_SUBSCRIBER_BANK, ESOPlusItemsToMove,
      BAG_BACKPACK, availableBagSpaces)
  return true
end

local function withdrawItemsNonESOPlus(itemsToWithdraw)
  d("withdrawItemsNonESOPlus")
  local itemsToMove = findItemsToMove(XLGB_Banking.currentBankBag, itemsToWithdraw)
  local availableBagSpaces = getAvailableBagSpaces(BAG_BACKPACK)
  if (#availableBagSpaces < #itemsToMove) then
    d("[XLGB_ERROR] Trying to move " .. #itemsToMove.. "items into a bag with " .. #availableBagSpaces .." empty slots.")
    return false
  end
  moveGear(XLGB_Banking.currentBankBag, itemsToMove, BAG_BACKPACK, availableBagSpaces)
  return true
end

local function waitForMoveItemEnd(startTime, setName, isWithdrawing)

  local function _waitForEnd()
    if XLGB_Banking.isMovingItems then return end
    local endTime = GetGameTimeMilliseconds()

    local text = ""
    if isWithdrawing then
      text = "withdrawn"
      if not XLGB_Page.isMovingPage then
        XLGB_Events:OnSingleSetWithdrawStop()
      end
    else
      text = "deposited"
      if not XLGB_Page.isMovingPage then
        XLGB_Events:OnSingleSetDepositStop()
      end
    end

    d("[XLGB] Set '" .. setName .."' ".. text .." in " .. tostring(string.format("%.2f", (endTime - startTime)/1000)) .. " seconds.")
    EVENT_MANAGER:UnregisterForUpdate(XLGearBanker.name .. "waitForMoveItemEnd")
  end
  EVENT_MANAGER:UnregisterForUpdate(XLGearBanker.name .. "waitForMoveItemEnd")
  EVENT_MANAGER:RegisterForUpdate(XLGearBanker.name .. "waitForMoveItemEnd", 400, _waitForEnd)
end

function XLGB_Banking:WithdrawSet(gearSetName)
  if not XLGB_Banking.bankOpen then
    d("[XLGB_ERROR] Bank is not open, abort!")
    PlaySound(SOUNDS.ABILITY_FAILED)
    return false
  end

  if XLGB_Banking.isMovingItems then
    d("Already moving")
    return false
  end
  XLGB_Banking.isMovingItems = true
  XLGB_Banking.isMoveCancelled = false
  XLGB_Banking.movesInSuccession = 1

  local startTime = GetGameTimeMilliseconds()
  if not XLGB_Page.isMovingPage then
    XLGB_Events:OnSingleSetWithdrawStart(gearSetName)
  end

  local gearSet = XLGB_GearSet:FindGearSet(gearSetName)
  if (IsESOPlusSubscriber() and (XLGB_Banking.currentBankBag == BAG_BANK)) then
    if withdrawGearESOPlus(gearSet) then
      PlaySound(SOUNDS.RETRAITING_ITEM_TO_RETRAIT_REMOVED)
      return waitForMoveItemEnd(startTime, gearSetName, true)
    end
  else
    if withdrawItemsNonESOPlus(gearSet.items) then
      PlaySound(SOUNDS.RETRAITING_ITEM_TO_RETRAIT_REMOVED)
      return waitForMoveItemEnd(startTime, gearSetName, true)
    end
  end
  PlaySound(SOUNDS.ABILITY_FAILED)
  XLGB_Banking.isMovingItems = false
  return waitForMoveItemEnd(startTime, gearSetName, true)
end

--------------------------------------------------------------------------------------------
-- WITHDRAW FUNCTIONS END
--------------------------------------------------------------------------------------------



--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--
--
--
--                                        DEPOSIT FUNCTIONS
--
--
--
--------------------------------------------------------------------------------------------

local function depositItemsToBankNonESOPlus(itemsToDeposit)
  -- d("depositItemsToBankNonESOPlus")
  local equippedItemsToMove = findItemsToMove(BAG_WORN, itemsToDeposit)
  local inventoryItemsToMove = findItemsToMove(BAG_BACKPACK, itemsToDeposit)

  local availableBagSpaces = getAvailableBagSpaces(XLGB_Banking.currentBankBag)
  local numberOfItemsToMove = #equippedItemsToMove + #inventoryItemsToMove

  if (#availableBagSpaces < numberOfItemsToMove) then
    return false
  end

  moveGearFromTwoBags(
      BAG_BACKPACK, inventoryItemsToMove,
      BAG_WORN, equippedItemsToMove,
      XLGB_Banking.currentBankBag, availableBagSpaces)
  return true
end

local function depositGearToBankESOPlus(gearSet)
  -- d("depositGearToBankESOPlus")
  local equippedItemsToMove = findItemsToMove(BAG_WORN, gearSet.items)
  local inventoryItemsToMove = findItemsToMove(BAG_BACKPACK, gearSet.items)

  local availableBagSpacesRegularBank = getAvailableBagSpaces(BAG_BANK)
  local availableBagSpacesESOPlusBank = getAvailableBagSpaces(BAG_SUBSCRIBER_BANK)
  -- 
  local numberOfAvailableSpaces = #availableBagSpacesRegularBank + #availableBagSpacesESOPlusBank
  local numberOfItemsToMove = #equippedItemsToMove + #inventoryItemsToMove

  if (numberOfAvailableSpaces < numberOfItemsToMove) then
    return false
  end

  if (#availableBagSpacesRegularBank >= numberOfItemsToMove) then
    moveGearFromTwoBags(
        BAG_BACKPACK, inventoryItemsToMove,
        BAG_WORN, equippedItemsToMove,
        BAG_BANK, availableBagSpacesRegularBank)
    return true

  else
    -- Add items to regular bank
    XLGB_Banking.isWaitingForBag = true
    XLGB_Banking.movesInSuccession = 2
    
    moveGearFromTwoBags(
        BAG_BACKPACK, inventoryItemsToMove,
        BAG_WORN, equippedItemsToMove,
        BAG_BANK, availableBagSpacesRegularBank)

    local function _waitForBag()
      -- d("Waiting for bag to finish...")
      if XLGB_Banking.isWaitingForBag then return end
      -- d("-")
      -- d("-")
      -- d("Starting 2nd bank bag ------------")
      -- d("-")
      -- d("-")
      inventoryItemsToMove = findItemsToMove(BAG_BACKPACK, gearSet.items)
      equippedItemsToMove = findItemsToMove(BAG_WORN, gearSet.items)

      moveGearFromTwoBags(
          BAG_BACKPACK, inventoryItemsToMove,
          BAG_WORN, equippedItemsToMove,
          BAG_SUBSCRIBER_BANK, availableBagSpacesESOPlusBank)

      EVENT_MANAGER:UnregisterForUpdate(XLGearBanker.name .. "isWaitingForBag")
    end

    EVENT_MANAGER:UnregisterForUpdate(XLGearBanker.name .. "isWaitingForBag")
    EVENT_MANAGER:RegisterForUpdate(XLGearBanker.name .. "isWaitingForBag", 500, _waitForBag)

    return true
  end
end

function XLGB_Banking:DepositSet(gearSetName)
  if not XLGB_Banking.bankOpen then
    d("[XLGB_ERROR] Bank is not open, abort!")
    PlaySound(SOUNDS.ABILITY_FAILED)
    return false
  end
  
  if XLGB_Banking.isMovingItems then
    d("Already moving")
    return false
  end
  XLGB_Banking.isMovingItems = true
  XLGB_Banking.isMoveCancelled = false
  XLGB_Banking.movesInSuccession = 1

  local startTime = GetGameTimeMilliseconds()
  if not XLGB_Page.isMovingPage then
    XLGB_Events:OnSingleSetDepositStart(gearSetName)
  end

  local gearSet = XLGB_GearSet:FindGearSet(gearSetName)
  if IsESOPlusSubscriber() and (XLGB_Banking.currentBankBag == BAG_BANK) then
    if depositGearToBankESOPlus(gearSet) then
      PlaySound(SOUNDS.INVENTORY_ITEM_UNLOCKED)
      return waitForMoveItemEnd(startTime, gearSetName, false)
    end
  else
    if depositItemsToBankNonESOPlus(gearSet.items) then
      PlaySound(SOUNDS.INVENTORY_ITEM_UNLOCKED)
      return waitForMoveItemEnd(startTime, gearSetName, false)
    end
  end
  PlaySound(SOUNDS.ABILITY_FAILED)
  XLGB_Banking.isMovingItems = false
  return waitForMoveItemEnd(startTime, gearSetName, false)
end

--------------------------------------------------------------------------------------------
-- DEPOSIT FUNCTIONS END
--------------------------------------------------------------------------------------------



--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--
--
--
--                                        INITIALIZATION
--
--
--
--------------------------------------------------------------------------------------------

function XLGB_Banking:Initialize()
  sV = XLGearBanker.savedVariables
  self.bankOpen = IsBankOpen()
  self.isMoveCancelled = false
  self.isMovingItems = false
  self.isWaitingForBag = false
  self.itemMoveDelay = 0
  self.movesInSuccession = 0
  self.swapEvent = false

  self.bankButtonGroup = {
    {
      name = "Toggle XLGB UI",
      keybind = "TOGGLE_XLGB_UI",
      callback = function() XLGB_UI:TogglePageUI() end,
    },
    alignment = KEYBIND_STRIP_ALIGN_CENTER,
  }

  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_OPEN_BANK, self.OnBankOpenEvent)
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CLOSE_BANK, self.OnBankCloseEvent)
end