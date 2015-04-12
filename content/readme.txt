this directory should be linked to (using an NTFS juntion, ideally), from UDKGame/ContentSDK/LastStand

open cmd.exe as an administrator

use mklink /j to create the junction, e.g.

mklink /j D:\SteamLibrary\SteamApps\common\chivalrymedievalwarfare\UDKGame\ContentSDK\LastStand D:\SteamLibrary\SteamApps\common\chivalrymedievalwarfare\Development\Src\LastStand\content