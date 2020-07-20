-- Namespace
XLGB_Settings = {}
local sV

function XLGB_Settings:Initialize()
  sV = XLGearBanker.savedVariables

  local LAM = LibAddonMenu2
  local menuName = "XL Gear Banker"

  local panelData = {
      type = "panel",
      name = menuName,
      displayName = menuName,
      author = "@XL_Olsen (PC/EU)",
      -- version = xlHoF.Colorize(xlHoF.version, "AA00FF"),
      slashCommand = "/xlgb_settings",
      registerForRefresh = true,
      registerForDefaults = true,
  }
  XLGB_Settings.panel = LAM:RegisterAddonPanel(menuName, panelData)

  local optionsTable = {}

  table.insert(optionsTable, {
      type    = "checkbox",
      name    = "Enable safe mode",
      tooltip = "Safely move items with a delay depended on server load.",
      getFunc = function() return sV.safeMode end,
      setFunc = function(v)
                  sV.safeMode = v
              end,
      width   = "full",
      warning = "Turning safe mode off can result in a server boot if you spam deposit/withdraw.\nSafe mode is automatically enabled upon depositing/withdrawing sets/pages with more than 70 items."
  })

  LAM:RegisterOptionControls(menuName, optionsTable)

end

-- function xlHoF.UnlockEnableUIUpdate(alert)
--     if alert.unlock and alert.enable then
--         alert.control:SetHidden(false)
--     else
--         alert.control:SetHidden(true)
--     end
-- end

-- function xlHoF.GenerateSettingsForAlert(alert)
--     return
--     {
--         type        = "header",
--         name        = xlHoF.Colorize(alert.settingsHeader, alert.color),
--         width       = "full",	--or "half" (optional)
--     },
--     {
--         type        = "description",
--         text        = alert.description,
--         width       = "full",
--     },
--     {
--         type        = "checkbox",
--         name        = SI_XLHOF_SETTINGS_ENABLE,
--         tooltip     = SI_XLHOF_SETTINGS_ENABLE_TOOLTIP,
--         getFunc     = function() return alert.enable end,
--         setFunc     = function(v)
--                         alert.enable = v
--                         xlHoF.UnlockEnableUIUpdate(alert)
--                     end,
--         width       = "full",
--     },
--     {
--         type        = "checkbox",
--         name        = SI_XLHOF_SETTINGS_UNLOCK,
--         tooltip     = SI_XLHOF_SETTINGS_UNLOCK_TOOLTIP,
--         getFunc     = function() return alert.unlock end,
--         setFunc     = function(v)
--                         alert.unlock = v
--                         if not v then sV.unlockAll = false end
--                         xlHoF.UnlockEnableUIUpdate(alert)
--                     end,
--         width       = "full",
--         warning     = SI_XLHOF_SETTINGS_UNLOCK_WARNING,
--         disabled    = function() return not alert.enable end,
--     },
--     {
--         type        = "slider",
--         name        = SI_XLHOF_SETTINGS_SIZE,
--         tooltip     = SI_XLHOF_SETTINGS_SIZE_TOOLTIP,
--         min         = 16,
--         max         = 64,
--         step        = 2,
--         getFunc     = function() return alert.fontSize end,
--         setFunc     = function(v)
--                         alert.fontSize = v
--                         xlHoF.SetLabelFontSize(alert.control, alert.fontSize)
--                     end,
--         width       = "full",
--         warning     = SI_XLHOF_SETTINGS_SIZE_WARNING,
--         disabled    = function()
--                         return not (alert.unlock and alert.enable)
--                     end,
--     }
-- end

-- table.insert(
    --     optionsTable,
    --     {
    --         type = "checkbox",
    --         name = "Account Wide",
    --         tooltip = "Use the same settings throughout the entire account - instead of per character.",
    --         getFunc = function()
    --             return xlHoF.savedVariables.accountWide
    --         end,
    --         setFunc = function(v)
    --             xlHoF.characterSavedVars.accountWide = v
    --             xlHoF.accountSavedVars.accountWide = v
    --         end,
    --         width = "full", --or "half",
    --         requiresReload = true,
    --     }
    -- )

    -- -- Category. --
    -- table.insert(optionsTable, {
    --     type = "header",
    --     name = ZO_HIGHLIGHT_TEXT:Colorize("My Header"),
    --     width = "full",	--or "half" (optional)
    -- })

    -- table.insert(optionsTable, {
    --     type = "description",
    --     --title = "My Title",	--(optional)
    --     title = nil,	--(optional)
    --     text = "My description text to display.",
    --     width = "full",	--or "half" (optional)
    -- })

    -- table.insert(optionsTable, {
    --     type = "dropdown",
    --     name = "My Dropdown",
    --     tooltip = "Dropdown's tooltip text.",
    --     choices = {"table", "of", "choices"},
    --     getFunc = function() return "of" end,
    --     setFunc = function(var) print(var) end,
    --     width = "half",	--or "half" (optional)
    --     warning = "Will need to reload the UI.",	--(optional)
    -- })

    -- table.insert(optionsTable, {
    --     type = "dropdown",
    --     name = "My Dropdown",
    --     tooltip = "Dropdown's tooltip text.",
    --     choices = {"table", "of", "choices"},
    --     getFunc = function() return "of" end,
    --     setFunc = function(var) print(var) end,
    --     width = "half",	--or "half" (optional)
    --     warning = "Will need to reload the UI.",	--(optional)
    -- })

    -- table.insert(optionsTable, {
    --     type = "slider",
    --     name = "My Slider",
    --     tooltip = "Slider's tooltip text.",
    --     min = 0,
    --     max = 20,
    --     step = 1,	--(optional)
    --     getFunc = function() return 3 end,
    --     setFunc = function(value) d(value) end,
    --     width = "half",	--or "half" (optional)
    --     default = 5,	--(optional)
    -- })

    -- table.insert(optionsTable, {
    --     type = "button",
    --     name = "My Button",
    --     tooltip = "Button's tooltip text.",
    --     func = function() d("button pressed!") end,
    --     width = "half",	--or "half" (optional)
    --     warning = "Will need to reload the UI.",	--(optional)
    -- })

    -- table.insert(optionsTable, {
    --     type = "submenu",
    --     name = "Submenu Title",
    --     tooltip = "My submenu tooltip",	--(optional)
    --     controls = {
    --         [1] = {
    --             type = "checkbox",
    --             name = "My Checkbox",
    --             tooltip = "Checkbox's tooltip text.",
    --             getFunc = function() return true end,
    --             setFunc = function(value) d(value) end,
    --             width = "half",	--or "half" (optional)
    --             warning = "Will need to reload the UI.",	--(optional)
    --         },
    --         [2] = {
    --             type = "colorpicker",
    --             name = "My Color Picker",
    --             tooltip = "Color Picker's tooltip text.",
    --             getFunc = function() return 1, 0, 0, 1 end,	--(alpha is optional)
    --             setFunc = function(r,g,b,a) print(r, g, b, a) end,	--(alpha is optional)
    --             width = "half",	--or "half" (optional)
    --             warning = "warning text",
    --         },
    --         [3] = {
    --             type = "editbox",
    --             name = "My Editbox",
    --             tooltip = "Editbox's tooltip text.",
    --             getFunc = function() return "this is some text" end,
    --             setFunc = function(text) print(text) end,
    --             isMultiline = false,	--boolean
    --             width = "half",	--or "half" (optional)
    --             warning = "Will need to reload the UI.",	--(optional)
    --             default = "",	--(optional)
    --         },
    --     },
    -- })

    -- table.insert(optionsTable, {
    --     type = "custom",
    --     reference = "MyAddonCustomControl",	--unique name for your control to use as reference
    --     refreshFunc = function(customControl) end,	--(optional) function to call when panel/controls refresh
    --     width = "half",	--or "half" (optional)
    -- })

    -- table.insert(optionsTable, {
    --     type = "texture",
    --     image = "EsoUI\\Art\\ActionBar\\abilityframe64_up.dds",
    --     imageWidth = 64,	--max of 250 for half width, 510 for full
    --     imageHeight = 64,	--max of 100
    --     tooltip = "Image's tooltip text.",	--(optional)
    --     width = "half",	--or "half" (optional)
    -- })