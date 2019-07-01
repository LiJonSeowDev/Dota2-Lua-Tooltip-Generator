--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[ SETUP ]]

if not Tooltip_Generator then
    print( '[Tooltip Generator] - Creating Tooltip_Generator' )
    Tooltip_Generator = class({})
end


---- [[ Event setup to fetch date from client side. Not needed if you do not want to use timestamps ]]   
CustomGameEventManager:RegisterListener( "POST_DATE", function(...) return Tooltip_Generator:OnDateNotified( ... ) end)
if ThinkerEntity == nil then
    ThinkerEntity = Entities:CreateByClassname("info_target") -- Just a thinker. which is not really used. (But needed. because lua has no access to os. we are using events to fetch date and the thinker is used incase of latency)
end

Convars:RegisterCommand( "dumptooltip", function(...) return Tooltip_Generator:_DumpTooltip_console( ... ) end, "Dumps tooltip with general params. 6 params (bDumpAbility = f, bDumpItem = f, bDumpUnit = f, bDumpHeroes = f, bOverrideFile = t, bAppend_CommentedDateBeforeEOL = f). has default values. no override means append if exist ", FCVAR_CHEAT )
Convars:RegisterCommand( "dumptooltip_all", function(...) return Tooltip_Generator:_DumpTooltip_console_All( ... ) end, "Dumps all tooltips. 2 params ( bOverrideFile = t , bAppend_CommentedDateBeforeEOL = f ). has default values. no override means append if exist", FCVAR_CHEAT )
Convars:RegisterCommand( "override_dump_filename", function(...) return Tooltip_Generator:_DumpTooltip_filename_override_console( ... ) end, "Overrides the filename. 1 param (strFileName)", FCVAR_CHEAT )
Convars:RegisterCommand( "override_dump_base_path", function(...) return Tooltip_Generator:_DumpTooltip_base_path_override_console( ... ) end, "Overrides the file base path (without the file name). 1 param (strBaseFilePath)", FCVAR_CHEAT )
Convars:RegisterCommand( "override_dump_path", function(...) return Tooltip_Generator:_DumpTooltip_path_override_console( ... ) end, "Specify the base_file_path and the file_name to override the entire path. 2 params (strBaseFilePath , strFileName)", FCVAR_CHEAT )
Convars:RegisterCommand( "override_language_token", function(...) return Tooltip_Generator:_DumpTooltip_language_token_override_console( ... ) end, "Specify the language_token. Does not affect filename ! language_token is referring to the KV for \"language\" in the tooltips file. 1 param - do not include escape char! (strLanguageToken)", FCVAR_CHEAT )

-- [[ Aliasing some functions ]]
Convars:RegisterCommand( "tooltip_generate", function(...) return Tooltip_Generator:_DumpTooltip_console( ... ) end, "Dumps tooltip with general params. 6 params (bDumpAbility = f, bDumpItem = f, bDumpUnit = f, bDumpHeroes = f, bOverrideFile = t, bAppend_CommentedDateBeforeEOL = f). has default values. no override means append if exist ", FCVAR_CHEAT )
Convars:RegisterCommand( "tooltip_generate_all", function(...) return Tooltip_Generator:_DumpTooltip_console_All( ... ) end, "Dumps all tooltips. 2 params ( bOverrideFile = t , bAppend_CommentedDateBeforeEOL = f ). has default values. no override means append if exist", FCVAR_CHEAT )
Convars:RegisterCommand( "tooltip_def_filename", function(...) return Tooltip_Generator:_DumpTooltip_filename_override_console( ... ) end, "Overrides the filename. 1 param (strFileName)", FCVAR_CHEAT )
Convars:RegisterCommand( "tooltip_def_base_path", function(...) return Tooltip_Generator:_DumpTooltip_base_path_override_console( ... ) end, "Overrides the file base path (without the file name). 1 param (strBaseFilePath)", FCVAR_CHEAT )
Convars:RegisterCommand( "tooltip_def_path", function(...) return Tooltip_Generator:_DumpTooltip_path_override_console( ... ) end, "Specify the base_file_path and the file_name to override the entire path. 2 params (strBaseFilePath , strFileName)", FCVAR_CHEAT )
Convars:RegisterCommand( "tooltip_def_language", function(...) return Tooltip_Generator:_DumpTooltip_language_token_override_console( ... ) end, "Specify the language_token. Does not affect filename ! language_token is referring to the KV for \"language\" in the tooltips file. 1 param - do not include escape char! (strLanguageToken)", FCVAR_CHEAT )


function Tooltip_Generator:GenerateTabs(intNumberOfTabs , bAppendWithEOL)
    local tabs = ""
    for i=1, intNumberOfTabs do
        tabs = tabs .. "\t"
    end
    if bAppendWithEOL then tabs = tabs .. "\n" end

    return tabs
end


--------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [[ CONFIGURABLE DEFAULTS ]]
-- [[ DEFAULTS - configure if you want ]]
Tooltip_Generator.DEBUG_PRINT = true

Tooltip_Generator.default_AbilityKV_path = "scripts/npc/npc_abilities_custom.txt"
Tooltip_Generator.default_UnitKV_path = "scripts/npc/npc_units_custom.txt"
Tooltip_Generator.default_HeroKV_path = "scripts/npc/npc_heroes_custom.txt"
Tooltip_Generator.default_ItemKV_path = "scripts/npc/npc_items_custom.txt"
Tooltip_Generator.default_LanguageToken = "English" -- The token at the start of the addon_$Language$


-- This is only a base header. If user decides to append date with 'bAppend_CommentedDateBeforeEOL' param, it will be appended by the _CreateHeader() function
Tooltip_Generator.Header_BASE = "\"lang\"\n" ..
    "{\n" ..
    "\t\"Language\"\t\"".. Tooltip_Generator.default_LanguageToken .."\"\n" ..
    "\t\"Tokens\"\n" ..
    "\t{\n" 

Tooltip_Generator.AbilityHeader = 

    "\n"..
    "\t\t// ---------------------------------------------------------------------------------------\n"..
    "\t\t// [[ ABILITIES ]] \n"..
    "\t\t// ----------------------------------------------------------------------------------------\n\n"

Tooltip_Generator.ItemHeader = 

    "\n"..
    "\t\t// ---------------------------------------------------------------------------------------\n"..
    "\t\t// [[ ITEM ]] \n"..
    "\t\t// ----------------------------------------------------------------------------------------\n\n"

Tooltip_Generator.UnitHeader = 

    "\n"..
    "\t\t// ---------------------------------------------------------------------------------------\n"..
    "\t\t// [[ UNITS ]] \n"..
    "\t\t// ----------------------------------------------------------------------------------------\n\n"

Tooltip_Generator.HeroHeader = 

    "\n"..
    "\t\t// ---------------------------------------------------------------------------------------\n"..  
    "\t\t// [[ HEROES ]] \n"..
    "\t\t// ----------------------------------------------------------------------------------------\n\n"


Tooltip_Generator.Trailer = 

    "\n"..
    "\t\t// ---------------------------------------------------------------------------------------\n"..
    "\t\t// [[ END OF DUMP ]] //\n"..
    "\t\t// ---------------------------------------------------------------------------------------\n\n"..
    "\t}\n}"

--[[ Although they are sharable in values (Item & abilities , Units & Heroes) , added here for future cases where they end up splitting ]]
Tooltip_Generator.AbilityConst = "\t\t\"DOTA_Tooltip_ability_" 
Tooltip_Generator.ItemConst = "\t\t\"DOTA_Tooltip_ability_" -- the prefix is same as ability "_item_" prefix is already included in the item KV so we append as per usual
Tooltip_Generator.UnitConst = "\t\t\"" -- No key prefix
Tooltip_Generator.HeroConst = "\t\t\"" -- No key prefix

Tooltip_Generator.tabs = '\t\t\t\t\t' -- 5 Tabs spaced between key and value of the tooltip
Tooltip_Generator.mid_length_tabs = Tooltip_Generator:GenerateTabs(7, false) -- alternate way to express
Tooltip_Generator.time_stamp_spacer_tab = '\t\t\t\t\t\t\t\t\t\t' -- 9 tabs
Tooltip_Generator.dump_ability_note = true -- only does one note atm 
Tooltip_Generator.dump_ability_lore = true 
Tooltip_Generator.dump_ability_description = true 

Tooltip_Generator.dump_item_note = true -- only does one note atm 
Tooltip_Generator.dump_item_lore = true 
Tooltip_Generator.dump_item_description = true 

Tooltip_Generator.dump_active_item_skill_behavior = {}
Tooltip_Generator.dump_active_item_skill_behavior[1] = "DOTA_ABILITY_BEHAVIOR_POINT"
Tooltip_Generator.dump_active_item_skill_behavior[2] = "DOTA_ABILITY_BEHAVIOR_UNIT_TARGET"
Tooltip_Generator.dump_active_item_skill_behavior[3] = "DOTA_ABILITY_BEHAVIOR_CHANNELLED"
Tooltip_Generator.dump_active_item_skill_behavior[4] = "DOTA_ABILITY_BEHAVIOR_IMMEDIATE"

Tooltip_Generator.dump_toggle_item_skill_behavior = {}
Tooltip_Generator.dump_toggle_item_skill_behavior[1] = "DOTA_ABILITY_BEHAVIOR_TOGGLE"


        -- [[ Pretty much constant strings, with the changes depending on the key/val so we use function  ]]
-- A header for (Items) with activatable
function Tooltip_Generator:_Gen_ActiveItemString(strInject)
    return "<h1>Active: _SkillActive </h1> Activate_Skill: Description.\\n "..strInject.."_Description"
end

 -- A header for (Items) with is toggleable
function Tooltip_Generator:_Gen_ToggleItemString(strInject)
    return "<h1>Active: _ToggleSkillName </h1> Toggle_Skill: Description.\\n "..strInject.."_Description"
end


--------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [[ INITIALIZER FUNCTIONS ]]
function Tooltip_Generator:Initialize(str_fileBasePath, str_fileName, language_token) -- Non-default directory use, in case you have iterations + change dir.
    if not str_fileBasePath then error("Empty file base path dir") end
    if not str_fileName then error("Empty file name") end
    if not language_token then if Tooltip_Generator.DEBUG_PRINT then print("You have not specify a language_token ! - Defaulting to \""..Tooltip_Generator.default_LanguageToken.."\"") end end

    Tooltip_Generator:Set_LanguageToken(language_token)
    Tooltip_Generator:Set_DumpPath(str_fileBasePath, str_fileName) 
end

-- Replace Your Init Call with this for default kv
function Tooltip_Generator:Initialize_WithDefaultKV(str_fileBasePath, str_fileName, language_token)
    if not str_fileBasePath then error("Empty file base path dir") end
    if not str_fileName then error("Empty file name") end
    if not language_token then if Tooltip_Generator.DEBUG_PRINT then print("You have not specify a language_token ! - Defaulting to \""..Tooltip_Generator.default_LanguageToken.."\"") end end

    Tooltip_Generator.AbilityKV = LoadKeyValues(Tooltip_Generator.default_AbilityKV_path)
    Tooltip_Generator.ItemKV = LoadKeyValues(Tooltip_Generator.default_ItemKV_path)
    Tooltip_Generator.UnitKV = LoadKeyValues(Tooltip_Generator.default_UnitKV_path)
    Tooltip_Generator.HeroKV = LoadKeyValues(Tooltip_Generator.default_HeroKV_path)

    Tooltip_Generator:Set_LanguageToken(language_token)
    Tooltip_Generator:Set_DumpPath(str_fileBasePath, str_fileName) 
end


---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [[ INJECTOR Functions ]]
function Tooltip_Generator:SetAbilityKV(strPath) -- Relative FROM  - <Addon_GAME_Home> .   game/dota_addons/$Add_on_name
    Tooltip_Generator.AbilityKV = nil 
    Tooltip_Generator.AbilityKV = LoadKeyValues(strPath)
end

function Tooltip_Generator:SetItemKV(strPath) -- Relative FROM  - <Addon_GAME_Home> .   game/dota_addons/$Add_on_name
    Tooltip_Generator.ItemKV = nil 
    Tooltip_Generator.ItemKV = LoadKeyValues(strPath)
end

function Tooltip_Generator:SetUnitKV(strPath) -- Relative FROM  - <Addon_GAME_Home> .   game/dota_addons/$Add_on_name
    Tooltip_Generator.UnitKV = nil 
    Tooltip_Generator.UnitKV = LoadKeyValues(strPath)
end

function Tooltip_Generator:SetHeroKV(strPath) -- Relative FROM  - <Addon_GAME_Home> .   game/dota_addons/$Add_on_name
    Tooltip_Generator.HeroKV = nil 
    Tooltip_Generator.HeroKV = LoadKeyValues(strPath)
end

function Tooltip_Generator:Set_DumpPath(strBasePath, strFileName) -- the final and entire filepath to write the file [Relative from dota2.exe path | but can specify from drive like 'C:/.. or D:/..'] 
    if not strBasePath then error("Empty file base path dir") end
    if not strFileName then error("Empty file name") end    
    Tooltip_Generator.dump_file_base_path = strBasePath    
    Tooltip_Generator.dump_filename = strFileName
    Tooltip_Generator.dump_file_path = Tooltip_Generator.dump_file_base_path .. Tooltip_Generator.dump_filename

    return Tooltip_Generator.dump_file_path
end

-- Ends with '/' so :
-- C:/User/XX/Desktop = wrong
-- C:/User/XX/Desktop/ = correct
function Tooltip_Generator:Set_DumpBasePath(strPath) -- the base path without the file name to write the file [Relative from dota2.exe path | but can specify from drive like 'C:/.. or D:/..'] 
    Tooltip_Generator.dump_file_base_path = strPath
    Tooltip_Generator.dump_file_path = Tooltip_Generator.dump_file_base_path .. Tooltip_Generator.dump_filename 

    return Tooltip_Generator.dump_file_path   
end

function Tooltip_Generator:Set_DumpFilename(strPath) -- the file name to dump
    Tooltip_Generator.dump_filename = strPath
    Tooltip_Generator.dump_file_path = Tooltip_Generator.dump_file_base_path .. Tooltip_Generator.dump_filename  

    return Tooltip_Generator.dump_file_path   
end

function Tooltip_Generator:Set_LanguageToken(strToken)
    Tooltip_Generator.LanguageToken = strToken
    Tooltip_Generator:_RefreshBaseHeader()

    return Tooltip_Generator.LanguageToken
end

function Tooltip_Generator:Get_DumpPath()
    return Tooltip_Generator.dump_file_path
end

function Tooltip_Generator:Request_Date()
    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(0),"GET_DATE",{})
    if Tooltip_Generator.DEBUG_PRINT then print("Event Sent !") end
end

function Tooltip_Generator:OnDateNotified( msg , parms )
    if Tooltip_Generator.DEBUG_PRINT then print("Received Date ".. parms['date'] .. " " .. parms['day']) end
   Tooltip_Generator.LOCAL_DATE = parms['date']
   Tooltip_Generator.LOCAL_DAY = parms['day']
end

function Tooltip_Generator:_RefreshBaseHeader()
    Tooltip_Generator.Header_BASE = "\"lang\"\n" ..
        "{\n" ..
        "\t\"Language\"\t\"".. Tooltip_Generator.LanguageToken .."\"\n" ..
        "\t\"Tokens\"\n" ..
        "\t{\n" 
end


--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[Console Command To Server Translator]]
-- [[ console ENTRY POINT ]] Console calls --> DumpToolTip . Creates Queue --> DumpFunctionRouter . Recursively Called From Queue --> XX_Dumper . Called from routing dump type.
-- bDumpAbility = dump ability tooltips 
-- bDumpItem = dump item tooltips
-- bDumpUnit = dump unit tooltips
-- bDumpHeroes = dump heroes tooltips
-- bOverrideFile = override existing file (default true) - if false, it will append !
-- bAppend_CommentedDateBeforeEOL = adds date to end of every line. This helps if you have multi version dumping and want quick multiline edits between patches.
function Tooltip_Generator:_DumpTooltip_console(cmdName, bDumpAbility, bDumpItem, bDumpUnit, bDumpHeroes, bOverrideFile, bAppend_CommentedDateBeforeEOL)
    -- [[PRE-processing and protecting parms]]
    -- Initialize Defaults, override if exists. (Need to convert string to bool so cant shorthand with if(x) )

    local IsWillDumpAbility = Tooltip_Generator:__CONSOLE_string_to_bool_handler(bDumpAbility, false)
    local IsWillDumpItem = Tooltip_Generator:__CONSOLE_string_to_bool_handler(bDumpItem, false)
    local IsWillDumpUnit = Tooltip_Generator:__CONSOLE_string_to_bool_handler(bDumpUnit, false)
    local IsWillDumpHeroes =  Tooltip_Generator:__CONSOLE_string_to_bool_handler(bDumpHeroes, false) 
    local IsWillOverrideFile =  Tooltip_Generator:__CONSOLE_string_to_bool_handler(bOverrideFile, true)
    local IsWillAppendDateEOL =  Tooltip_Generator:__CONSOLE_string_to_bool_handler(bAppend_CommentedDateBeforeEOL, false)

    -- [[ Check if Events are active yet || PRE_GAME_STATE ]] *Not disablable debug print
    if GameRules:State_Get() < DOTA_GAMERULES_STATE_PRE_GAME then
        print("=================================================================================================================================================================")
        print("[WARNING] You are trying to print with EOL Date : But events are not active. Unable to fetch date from client. Please enter PRE_GAME State (After strategy time)")
        print("  |-->[WARN] EOL parameter overrided to false due to event inactive.")
        print("=================================================================================================================================================================")
        IsWillAppendDateEOL = false
    end

    -- [[  Call the dumper function  ]]
    if Tooltip_Generator.DEBUG_PRINT then print(string.format(" Understood command. Calling DumpToolTip [ability_tooltip = %s] [item_tooltip = %s] [unit_tooltip = %s] [hero_tooltip = %s] [overwrite_if_exist = %s] [append_date = %s]  ", tostring(IsWillDumpAbility),tostring(IsWillDumpItem),tostring(IsWillDumpUnit),tostring(IsWillDumpHeroes),tostring(IsWillOverrideFile),tostring(IsWillAppendDateEOL))) end
    Tooltip_Generator:DumpTooltip(IsWillDumpAbility, IsWillDumpItem, IsWillDumpUnit, IsWillDumpHeroes, IsWillOverrideFile, IsWillAppendDateEOL)
end

function Tooltip_Generator:_DumpTooltip_console_All(cmdName, bOverrideFile, bAppend_CommentedDateBeforeEOL)
    -- [[PRE-processing and protecting parms]]
    -- Initialize Defaults, override if exists. (Need to convert string to bool so cant shorthand with if(x) )
    local IsWillOverrideFile =  Tooltip_Generator:__CONSOLE_string_to_bool_handler(bOverrideFile, true)
    local IsWillAppendDateEOL =  Tooltip_Generator:__CONSOLE_string_to_bool_handler(bAppend_CommentedDateBeforeEOL, false)

    -- [[ Check if Events are active yet || PRE_GAME_STATE ]] *Not disablable debug print
    if GameRules:State_Get() < DOTA_GAMERULES_STATE_PRE_GAME then
        print("=================================================================================================================================================================")
        print("[WARNING] You are trying to print with EOL Date : But events are not active. Unable to fetch date from client. Please enter PRE_GAME State (After strategy time)")
        print("  |-->[WARN] EOL parameter overrided to false due to event inactive.")
        print("=================================================================================================================================================================")
        IsWillAppendDateEOL = false
    end

    -- [[  Call the dumper function  ]]
    if Tooltip_Generator.DEBUG_PRINT then print(string.format(" Understood command. Calling DumpToolTip (ALL) - Ability,Item,Unit & Hero [overwrite_if_exist = %s] [append_date = %s]  ", "true", "true", "true", "true", tostring(IsWillOverrideFile),tostring(IsWillAppendDateEOL))) end
    Tooltip_Generator:DumpTooltips_AllKV(IsWillOverrideFile, IsWillAppendDateEOL)
end

function Tooltip_Generator:_DumpTooltip_filename_override_console(cmdName, strFileName)
    if not strFileName then
        error("did not specify a filename to override !")
    end

    local final_path = Tooltip_Generator:Set_DumpFilename(strFileName)
    if Tooltip_Generator.DEBUG_PRINT then print("Your new filename is " .. final_path) end

end

function Tooltip_Generator:_DumpTooltip_base_path_override_console(cmdName, strBasePath)
    if not strBasePath then
        error("did not specify a basePath to override !")
    end

    local final_path = Tooltip_Generator:Set_DumpBasePath(strBasePath)
    if Tooltip_Generator.DEBUG_PRINT then print("Your new path is : " .. final_path)     end
end

function Tooltip_Generator:_DumpTooltip_path_override_console(cmdName, strBasePath, strFileName)
    if not strFileName then
        error("did not specify a filename to override !")
    end
    if not strBasePath then
        error("did not specify a basePath to override !")
    end


    local final_path = Tooltip_Generator:Set_DumpPath(strBasePath, strFileName)
    if Tooltip_Generator.DEBUG_PRINT then print("Your new path is : " .. final_path)    end
end

function Tooltip_Generator:_DumpTooltip_language_token_override_console(cmdName, strLanguageToken)
    if not strFileName then
        error("did not specify a language_token to override !")
    end
    local language_token = Tooltip_Generator:Set_LanguageToken(strLanguageToken)
    if Tooltip_Generator.DEBUG_PRINT then print("Your new language token is : " .. language_token) end
    if Tooltip_Generator.DEBUG_PRINT then print(" Header has been refreshed. Tooltip_dump -> start of file now looks like this : ") end
    if Tooltip_Generator.DEBUG_PRINT then print(Tooltip_Generator.Header_BASE) end
end

-- Not Nil Protected
function Tooltip_Generator:__CONSOLE_string_to_bool_handler(strParam, bdefault)
    if not strParam then 
        return bdefault
    end

    local s_param = string.lower(strParam)
    if s_param == "true" or s_param == "t" or s_param == "y" or s_param =="yes" then 
        s_param = true --convert to bool and return
    elseif s_param == "false" or s_param == "f" or s_param == "n" or s_param =="no" then 
        s_param = false -- convert to bool and return
    else
        return bdefault
    end

    return s_param
end


---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [[ Core Operations ]]
-- [[ call ENTRY POINT ]] DumpToolTip . Creates Queue --> DumpFunctionRouter . Recursively Called From Queue --> XX_Dumper . Called from routing dump type.
-- bDumpAbility = dump ability tooltips 
-- bDumpItem = dump item tooltips
-- bDumpUnit = dump unit tooltips
-- bDumpHeroes = dump heroes tooltips
-- bOverrideFile = override existing file (default true) - if false, it will append !
-- bAppend_CommentedDateBeforeEOL = adds date to end of every line. This helps if you have multi version dumping and want quick multiline edits between patches.
function Tooltip_Generator:DumpTooltip(bDumpAbility, bDumpItem, bDumpUnit, bDumpHeroes, bOverrideFile, bAppend_CommentedDateBeforeEOL)
    if Tooltip_Generator.DEBUG_PRINT then print(" Initializing Dump ... ") end
        -- [[ Initialize ]]
            local IsWillDumpAbility = bDumpAbility or false
            local IsWillDumpItem = bDumpItem or false
            local IsWillDumpUnit = bDumpUnit or false
            local IsWillDumpHeroes = bDumpHeroes or false
            local IsWillOverrideFile = bOverrideFile or true
            local IsWillAppendDateEOL = bAppend_CommentedDateBeforeEOL or false

            local mode = "a+" 
            local dump_queue = {}
            local queue_index = 2 -- Index 1 is defined below

            dump_queue[1] = "HEADER"
            --[[ protect KV null errors. ]]
            if IsWillDumpAbility then 
                if not Tooltip_Generator.AbilityKV then Tooltip_Generator:SetAbilityKV( Tooltip_Generator.default_AbilityKV_path  ) end
                dump_queue[queue_index] = "ABILITY"
                queue_index = queue_index + 1
            end
            if IsWillDumpItem then 
                if not Tooltip_Generator.ItemKV then Tooltip_Generator:SetItemKV( Tooltip_Generator.default_ItemKV_path  ) end 
                dump_queue[queue_index] = "ITEM"
                queue_index = queue_index + 1
            end
            if IsWillDumpUnit then 
                if not Tooltip_Generator.UnitKV then Tooltip_Generator:SetUnitKV( Tooltip_Generator.default_UnitKV_path  ) end 
                dump_queue[queue_index] = "UNIT"
                queue_index = queue_index + 1
            end
            if IsWillDumpHeroes then 
                if not Tooltip_Generator.HeroKV then Tooltip_Generator:SetHeroKV( Tooltip_Generator.default_HeroKV_path  ) end 
                dump_queue[queue_index] = "HERO"
                queue_index = queue_index + 1
            end   
            dump_queue[queue_index] = "TRAILER"


            if IsWillOverrideFile then 
                mode = "w+"
            end

            if IsWillAppendDateEOL then
                 Tooltip_Generator:Request_Date()
            end

        -- [[ Fire Operations ]]

    -- In case of latency (from Request_Date() ) Works with pause
    local latency_buffer = 0.5 -- seconds
    ThinkerEntity:SetContextThink(
        "LatencyBuffer", 
        function()                 
                for i=1, #dump_queue do
                    local overwrite_policy = mode 
                    if (( i > 1 ) and ( i < #dump_queue)) then overwrite_policy = "a+" end  
                    -- mode changes based on i ( i = 1 is header which can use a+ or w+ depend on user, everything else should use append a+)

                    if Tooltip_Generator.DEBUG_PRINT then print(" // !! [ CONSOLE ] Starting dump .. " .. dump_queue[i]) end
                    Tooltip_Generator:_DumpFunctionRouter( dump_queue[i] , overwrite_policy , bAppend_CommentedDateBeforeEOL )
                    if Tooltip_Generator.DEBUG_PRINT then print(" // !! [ CONSOLE ] Finished dumping .. " .. dump_queue[i]) end
                end
            return 
        end, latency_buffer)
end

function Tooltip_Generator:_DumpFunctionRouter( strDumpType, mode, bAppend_CommentedDateBeforeEOL )
    if strDumpType == "HEADER" then Tooltip_Generator:DumpTooltips_Header(mode, bAppend_CommentedDateBeforeEOL)
    elseif strDumpType == "ABILITY" then Tooltip_Generator:DumpTooltips_AbilityKV(bAppend_CommentedDateBeforeEOL)
    elseif strDumpType == "ITEM" then Tooltip_Generator:DumpTooltips_ItemKV(bAppend_CommentedDateBeforeEOL)
    elseif strDumpType == "UNIT" then Tooltip_Generator:DumpTooltips_UnitKV(bAppend_CommentedDateBeforeEOL)
    elseif strDumpType == "HERO" then Tooltip_Generator:DumpTooltips_HeroKV(bAppend_CommentedDateBeforeEOL)
    elseif strDumpType == "TRAILER" then Tooltip_Generator:DumpTooltips_Trailer(bAppend_CommentedDateBeforeEOL)
    end
end

function Tooltip_Generator:_CreateHeader(bAppend_CommentedDateBeforeEOL)
    local header = ""
    if bAppend_CommentedDateBeforeEOL then
        if not Tooltip_Generator.LOCAL_DATE then error("NO DATE : You have not configured the panorama js correctly. Or Try running with append Date at EOL = f") end
        if not Tooltip_Generator.LOCAL_DAY  then error("NO DAY : You have not configured the panorama js correctly. Or Try running with append Date at EOL = f") 
        else
            local date =  "[ ".. Tooltip_Generator.LOCAL_DATE .. " ] " .. Tooltip_Generator.LOCAL_DAY
            header = "//Last Updated : " .. date .. "\n"           
        end
    end
    header = header .. Tooltip_Generator.Header_BASE

    return header
end

function Tooltip_Generator:DumpTooltips_Header(mode, bAppend_CommentedDateBeforeEOL)
    if Tooltip_Generator.DEBUG_PRINT then print("Writing to file : ".. Tooltip_Generator:Get_DumpPath()) end
    if Tooltip_Generator.DEBUG_PRINT then print("using mode : " .. mode) end

    local header =Tooltip_Generator:_CreateHeader(bAppend_CommentedDateBeforeEOL)
    local file = io.open(
        Tooltip_Generator:Get_DumpPath(),
        mode)

    if Tooltip_Generator.DEBUG_PRINT then print(header) end
    file:write(header)
    file:close()
end

function Tooltip_Generator:DumpTooltips_AbilityKV(bAppend_CommentedDateBeforeEOL)
    if Tooltip_Generator.DEBUG_PRINT then print("//[CONSOLE] : Dumping Ability") end
    local mode = "a+"
    local file = io.open(
        Tooltip_Generator:Get_DumpPath(),
        mode)

    local per_line_trailer = "\n"
    local date = ""
    if Tooltip_Generator.LOCAL_DATE then date = Tooltip_Generator.LOCAL_DATE end
    if bAppend_CommentedDateBeforeEOL then per_line_trailer =  Tooltip_Generator.time_stamp_spacer_tab .. "//\t" .. date .. per_line_trailer end

    local TitleHeader = Tooltip_Generator.AbilityHeader

    if Tooltip_Generator.DEBUG_PRINT then print(TitleHeader) end
    file:write(TitleHeader)
    for ability,tAttributes in pairs(Tooltip_Generator.AbilityKV) do
        if not (ability == "Version") then
            local ability_key_header = "\n\t\t//" .. ability .. per_line_trailer .."\n"
            local ability_title = Tooltip_Generator.AbilityConst .. ability .. "\"".. Tooltip_Generator.tabs .."\"" .. ability .. "\""  .. per_line_trailer
            
            file:write(ability_key_header)
            file:write(ability_title)
            if Tooltip_Generator.DEBUG_PRINT then print(ability_key_header) end
            if Tooltip_Generator.DEBUG_PRINT then print(ability_title) end
            
            if Tooltip_Generator.dump_ability_note then 
                local ability_note0 = Tooltip_Generator.AbilityConst .. ability .. "_Note0\"".. Tooltip_Generator.tabs .."\"" .. "!ability_Note0" .. "\""  .. per_line_trailer
                file:write(ability_note0)                
                if Tooltip_Generator.DEBUG_PRINT then print(ability_note0) end
            end
            

            if Tooltip_Generator.dump_ability_lore then 
                local ability_lore = Tooltip_Generator.AbilityConst .. ability .. "_Lore\"".. Tooltip_Generator.tabs .."\"" .. "!ability_lore" .. "\""  .. per_line_trailer
                file:write(ability_lore)                
                if Tooltip_Generator.DEBUG_PRINT then print(ability_lore) end
            end


            if Tooltip_Generator.dump_ability_description then 
                local ability_description = Tooltip_Generator.AbilityConst .. ability .. "_Description\"".. Tooltip_Generator.tabs .."\"" .. " !ability_description" .. "\"" .. per_line_trailer     
                file:write(ability_description)                
                if Tooltip_Generator.DEBUG_PRINT then print(ability_description) end
            end


            if tAttributes['AbilitySpecial'] then
                if tAttributes['AbilitySpecial'] ~= "" then
                    local hTableAbilitySpecial = tAttributes['AbilitySpecial']
                    for index_special, tSpecial_table in pairs(hTableAbilitySpecial) do
                        for special_key, special_value in pairs(tSpecial_table) do
                            if special_key ~= "var_type" then
                                local tooltip = Tooltip_Generator.AbilityConst .. ability .. "_" .. special_key .."\"".. Tooltip_Generator.tabs .."\"" .. string.upper(special_key) .. ": \""
                                local tooltip = tooltip .. per_line_trailer
                                file:write(tooltip)
                                if Tooltip_Generator.DEBUG_PRINT then print(tooltip) end
                            end
                        end
                    end
                end
            end  
        end 
        
    end
    file:close()
end

function Tooltip_Generator:DumpTooltips_ItemKV(bAppend_CommentedDateBeforeEOL)
    if Tooltip_Generator.DEBUG_PRINT then print("//[CONSOLE] : Dumping Item") end
    local mode = "a+"
    local file = io.open(
        Tooltip_Generator:Get_DumpPath(),
        mode)

    local per_line_trailer = "\n"
    local date = ""
    if Tooltip_Generator.LOCAL_DATE then date = Tooltip_Generator.LOCAL_DATE end
    if bAppend_CommentedDateBeforeEOL then per_line_trailer =  Tooltip_Generator.time_stamp_spacer_tab .. "//\t" .. date .. per_line_trailer end

    local TitleHeader = Tooltip_Generator.ItemHeader

    if Tooltip_Generator.DEBUG_PRINT then print(TitleHeader) end
    file:write(TitleHeader)
    for item,tAttributes in pairs(Tooltip_Generator.ItemKV) do
        if not (item == "Version") then
            local item_key_header = "\n\t\t//" .. item .. per_line_trailer .."\n"
            local item_title = Tooltip_Generator.ItemConst .. item .. "\"".. Tooltip_Generator.tabs .."\"" .. item .. "\""  .. per_line_trailer  
            
            file:write(item_key_header)
            file:write(item_title)
            if Tooltip_Generator.DEBUG_PRINT then print(ability_key_header) end
            if Tooltip_Generator.DEBUG_PRINT then print(item_title) end
            
            if Tooltip_Generator.dump_item_note then
                local item_note0 = Tooltip_Generator.ItemConst .. item .. "_Note0\"".. Tooltip_Generator.tabs .."\"" .. "!item_Note0" .. "\""  .. per_line_trailer
                file:write(item_note0)                
                if Tooltip_Generator.DEBUG_PRINT then print(item_note0) end
            end
            

            if Tooltip_Generator.dump_item_lore then
                local item_lore = Tooltip_Generator.ItemConst .. item .. "_Lore\"".. Tooltip_Generator.tabs .."\"" .. "!item_lore" .. "\""  .. per_line_trailer
                file:write(item_lore)                
                if Tooltip_Generator.DEBUG_PRINT then print(item_lore)  end
            end


            if Tooltip_Generator.dump_item_description then
                local HasActive = false
                local IsToggle = false
                local item_description_key = Tooltip_Generator.ItemConst .. item .. "_Description\"".. Tooltip_Generator.tabs .."\""
                local item_description_value = ""
                if tAttributes['AbilityBehavior'] then

                    for ind,behavior in pairs(Tooltip_Generator.dump_active_item_skill_behavior ) do
                        if string.match(tAttributes['AbilityBehavior'], behavior) then
                            HasActive = true
                            break
                        end
                    end
                    for ind,behavior in pairs(Tooltip_Generator.dump_toggle_item_skill_behavior ) do
                        if string.match(tAttributes['AbilityBehavior'], behavior) then
                            IsToggle = true
                            break
                        end
                    end
                end

                if IsToggle then 
                    item_description_value = Tooltip_Generator:_Gen_ToggleItemString(item) .. "\"" .. per_line_trailer
                elseif HasActive then
                    item_description_value = Tooltip_Generator:_Gen_ActiveItemString(item) .. "\"" .. per_line_trailer
                else
                    item_description_value = "!item_description" .. "\"" .. per_line_trailer   
                end
                local item_description = item_description_key .. item_description_value
                file:write(item_description)                
                if Tooltip_Generator.DEBUG_PRINT then print(item_description) end
            end


            if tAttributes['AbilitySpecial'] then
                if tAttributes['AbilitySpecial'] ~= "" then
                    local hTableAbilitySpecial = tAttributes['AbilitySpecial']
                    for index_special, tSpecial_table in pairs(hTableAbilitySpecial) do
                        for special_key, special_value in pairs(tSpecial_table) do
                            if special_key ~= "var_type" then
                                local tooltip = Tooltip_Generator.AbilityConst .. item .. "_" .. special_key .."\"".. Tooltip_Generator.tabs .."\"" .. string.upper(special_key) .. ": \""
                                local tooltip = tooltip .. per_line_trailer
                                file:write(tooltip)
                                if Tooltip_Generator.DEBUG_PRINT then print(tooltip) end
                            end
                        end
                    end
                end
            end  
        end 
        
    end
    file:close()
end

function Tooltip_Generator:DumpTooltips_UnitKV(bAppend_CommentedDateBeforeEOL)
    if Tooltip_Generator.DEBUG_PRINT then print("//[CONSOLE] : Dumping Unit") end
    local mode = "a+"
    local file = io.open(
        Tooltip_Generator:Get_DumpPath(),
        mode)

    local per_line_trailer = "\n"
    local date = ""
    if Tooltip_Generator.LOCAL_DATE then date = Tooltip_Generator.LOCAL_DATE end
    if bAppend_CommentedDateBeforeEOL then per_line_trailer =  Tooltip_Generator.time_stamp_spacer_tab .. "//\t" .. date .. per_line_trailer end

    local TitleHeader = Tooltip_Generator.UnitHeader

    if Tooltip_Generator.DEBUG_PRINT then print(TitleHeader) end
    file:write(TitleHeader)
    for npc_unit_name,tAttributes in pairs(Tooltip_Generator.UnitKV) do
        if not (npc_unit_name == "Version") then
            local name_dump = Tooltip_Generator.UnitConst .. npc_unit_name .. "\"".. Tooltip_Generator.tabs .."\"" .. "!UNIT_NAME" .. "\""  .. per_line_trailer
            if Tooltip_Generator.DEBUG_PRINT then print(name_dump) end
            file:write(name_dump)            
        end
    end
    file:close()      
end

function Tooltip_Generator:DumpTooltips_HeroKV(bAppend_CommentedDateBeforeEOL)
    if Tooltip_Generator.DEBUG_PRINT then print("//[CONSOLE] : Dumping Hero") end
    
    local mode = "a+"
    local file = io.open(
        Tooltip_Generator:Get_DumpPath(),
        mode)

    local per_line_trailer = "\n"
    local date = ""
    if Tooltip_Generator.LOCAL_DATE then date = Tooltip_Generator.LOCAL_DATE end
    if bAppend_CommentedDateBeforeEOL then per_line_trailer =  Tooltip_Generator.time_stamp_spacer_tab .. "//\t" .. date .. per_line_trailer end

    local TitleHeader = Tooltip_Generator.HeroHeader

    if Tooltip_Generator.DEBUG_PRINT then print(TitleHeader) end
    file:write(TitleHeader)
    for npc_hero_name,tAttributes in pairs(Tooltip_Generator.HeroKV) do
        if not (npc_hero_name == "Version") then
            local name_dump = Tooltip_Generator.HeroConst .. npc_hero_name .. "\"".. Tooltip_Generator.tabs .."\"" .. "!HERO_NAME" .. "\""  .. per_line_trailer
            if Tooltip_Generator.DEBUG_PRINT then print(name_dump) end
            file:write(name_dump)            
        end
    end
    file:close()      
end

function Tooltip_Generator:DumpTooltips_Trailer(bAppend_CommentedDateBeforeEOL)
    if Tooltip_Generator.DEBUG_PRINT then print("//[CONSOLE] : Dumping Trailer") end
    local mode = "a+"
    local file = io.open(
        Tooltip_Generator:Get_DumpPath(),
        mode)    

    file:write(Tooltip_Generator.Trailer)
    file:close()
    if Tooltip_Generator.DEBUG_PRINT then print("[Tooltip Dump ] : Finish. Written to file : ".. Tooltip_Generator:Get_DumpPath()) end
end

-- [[ ALTERNATE call ENTRY POINT]]
function Tooltip_Generator:DumpTooltips_AllKV(bOverride, bAppend_CommentedDateBeforeEOL)
    Tooltip_Generator:DumpTooltip(true,true,true,true, bOverride, bAppend_CommentedDateBeforeEOL)
end

-- Obsolete
function Tooltip_Generator:_ParseSpecials(strSpecial)
    local special_text = strSpecial:gsub("% ", "/")
    return special_text
end


---------------------------------------------------------------------------------------------------------------------------------------------------------------------
