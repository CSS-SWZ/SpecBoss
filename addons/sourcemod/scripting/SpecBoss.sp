#include <sourcemod>
#include <sdktools>

#include <helco>

#define COOKIE

#define MAX_BOSSES_CONFIGS 20

#define HIDEHUD_PLAYERDEATH (1 << 4)

#pragma newdecls required

bool Late;

#include "specboss/debug.sp"
#include "specboss/config.sp"
#include "specboss/events.sp"
#include "specboss/client.sp"
#include "specboss/boss.sp"
#include "specboss/cookie.sp"


public Plugin myinfo =
{
    name = "SpecBoss",
    author = "hEl",
    description = "Provides the ability to spectate the boss",
    version = "1.0",
    url = "https://github.com/CSS-SWZ/SpecBoss"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	Late = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations("specboss.phrases");

    (FindConVar("mp_restartgame")).AddChangeHook(OnGameRestarted);

    BossInit();
    EventsInit();
    
    #if defined COOKIE
    CookiesInit();
    #endif

    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i))
            OnClientPutInServer(i);
    }

    BossRoundStart();
}

public void OnGameRestarted(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    if(!StringToInt(oldValue) && StringToInt(newValue))
        BossRoundEnd();
}

public void OnPluginEnd()
{
    BossRoundEnd();
}

public void OnMapStart()
{
    ConfigOnMapStart();
    BossOnMapStart();
}

public void OnMapEnd()
{
    ConfigOnMapEnd();
    BossOnMapEnd();
    EventsOnMapEnd();
}