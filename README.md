# Dota2-Lua-Tooltip-Generator - A tooltip pre-processing tool
###### This is a very lightweight library which reads your KV and throws a tooltip file.

**It Reads ( as required ) :**
1. npc_abilities_custom
2. npc_items_custom
3. npc_units_custom
4. npc_heroes_custom
5. **customized directory** * - (for segmentation)*

**Supports :**
- Ability special value dumping
- Configurable dump settings.
- change of filename *(you probably wouldn't want to overwrite an existing addon_$language$ file yet.)*
- change of dump directory
- KV #base nested declarations
- optional timestamp marking 

###### Timestamp feature is probably not for many people. But I personally use this with sublime's multi-line edit to remove records of older date when patching.


## I. Installation
I'm Referring to several directories as follows :

- **"$GAME_HOME"** = "../game/dota_addons/ _@YOUR_ADDON_NAME_ /"
- **"$CONTENT_HOME"** = "../content/dota_addons/ _@YOUR_ADDON_NAME_ /"

A. Firstly, add 4 of these files into the correct directory. They are relatively same path in this repo.


  1. tooltip_dump_util.lua  ( _$GAME_HOME_ /scripts/vscripts/lib/**tooltip_dump_util.lua** )
  2. date_passer.js ( _$CONTENT_HOME_ /panorama/scripts/custom_game/**date_passer.js** )
  3. date_passer.xml ( _$CONTENT_HOME_ /panorama/layout/custom_game/**date_passer.xml** )
  4. custom_ui_manifest.xml ( _$CONTENT_HOME_ /panorama/layout/custom_game/**custom_ui_manifest.xml** )


 ```xml
<!-- NOTE : for #4, if your custom_ui_manifest.xml already exists, append these in the appropriate area -->
<Panel>
  <CustomUIElement type="Hud" layoutfile="file://{resources}/layout/custom_game/date_passer.xml" />
</Panel>
 ```

B. Modify your addon_game_mode.lua
Note that this only works in tools mode. The Initialize parameters is explained in the comments below.
This uses defaults, if you want to use customized parameters ( such as changing KV directory ) look at the next section.

```lua
-- The following needs to be added near the top.

if IsInToolsMode() then
	require( "lib/utils/tooltip_dump_util")
	Tooltip_Generator:Initialize_WithDefaultKV(  --> [Alternate Init] Tooltip_Generator:Initialize() CTRL+F FIND : '-- [[ INITIALIZER FUNCTIONS ]]'
		"C:/Users/User_name1/Desktop/New folder/", -- Base_Directory. Ends with '/' If base is empty, the file will be created at the Dota2.exe directory
		"addon_english_dump.txt", -- This is the filename. Try not to use the actual one. (You most likely do not want to overwrite yet.
		"English")  							-- Just a token Not the filename. Ends with extension
end

```

## II. Execution / Running
To dump your KVs to tooltips, launch your map. Most likely you will need to pass the hero selection stage if you want to use date dumping (Basically needs to prepare both client and server for event listening to pass date)

1. Launch Your Map, pause game if you need to. Ensure your event listeners are already active if you want timestamp. (In my test case this is after hero selection)
2. Open your console, fire commands.
3. Available commands are :
   - **dumptooltip** -->  _Dumps tooltip with general params. 6 params. Has default values. No override means append if exist._
   ```
     dumptooltip [bDumpAbility = f, bDumpItem = f, bDumpUnit = f, bDumpHeroes = f, bOverrideFile = t, bAppend_CommentedDateBeforeEOL = f)]
   ```
   - **dumptooltip_all** --> _Dumps all tooltips. 2 params. Has default values. No override means append if exist_
   ```
     dumptooltip_all [ bOverrideFile = t , bAppend_CommentedDateBeforeEOL = f]
   ```
   - **override_dump_filename** --> _Overrides the filename. 1 param_
   ```
     override_dump_filename [strFileName]
   ```
   - **override_dump_base_path** -->_Overrides the file base path (without the file name). 1 param_
   ```
     override_dump_base_path [strBaseFilePath]
   ```
   - **override_dump_path** --> _Specify the base_file_path and the file_name to override the entire path. 2 params_
   ```
      override_dump_path [strBaseFilePath , strFileName]
   ```
   - **override_language_token** -->_Specify the language_token. Does not affect filename ! language_token is referring to the KV for "language" in the tooltips file. 1 param - do not include escape char!_
   ```
      override_language_token [strLanguageToken]
   ```



_**Example Console commands :**_
```
dumptooltip true true true false true false
```
As referred to the details above, this will dump Ability, Items, and Unit KVs into Tooltip file. It will override if the filename exists and will not include timestamp.


Note : All these commands execute for default KV paths. if you wish to define your own KV path (i.e. specify the KV file to read, look into configurations and customizations

## III. Customizations & Configurations
1. You can easily override default definitions in the tooltip_dump_util.lua

the following segments for example, specifies the default directories.
```lua
-- [[ CONFIGURABLE DEFAULTS ]]
-- [[ DEFAULTS - configure if you want ]]
Tooltip_Generator.default_AbilityKV_path = "scripts/npc/npc_abilities_custom.txt"
Tooltip_Generator.default_UnitKV_path = "scripts/npc/npc_units_custom.txt"
Tooltip_Generator.default_HeroKV_path = "scripts/npc/npc_heroes_custom.txt"
Tooltip_Generator.default_ItemKV_path = "scripts/npc/npc_items_custom.txt"
Tooltip_Generator.default_LanguageToken = "English" -- The token at the start of the addon_$Language$
```

2. You can also use Injector functions and/or link them up to your own console to change directories while your map is actively loaded.
You may also create your own dumping sequence and queue by sequencing them in a function.
the following segment are parts of the Injector functions
```lua
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

function Tooltip_Generator:Set_DumpPath(strBasePath, strFileName) -- the final and entire filepath to write the file [Relative from] 
    if not strBasePath then error("Empty file base path dir") end
    if not strFileName then error("Empty file name") end    
    Tooltip_Generator.dump_file_base_path = strBasePath    
    Tooltip_Generator.dump_filename = strFileName
    Tooltip_Generator.dump_file_path = Tooltip_Generator.dump_file_base_path .. Tooltip_Generator.dump_filename

    return Tooltip_Generator.dump_file_path
end

function Tooltip_Generator:Set_DumpBasePath(strPath) -- the base path without the file name to write the file [Relative from] - 
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
.
.
.
.

```
## IV. Correctness checking
you may use the link to check the dump's correctness :
http://arhowk.github.io/
## V. Disclaimer
You are to use this generator at your own risk. You are advised to create a backup of your addon_$language.txt file as insurance, and to avoid using the same dump name.

