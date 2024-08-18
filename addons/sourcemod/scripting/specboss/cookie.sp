#if !defined COOKIE
    #endinput
#endif

#include <clientprefs>

Handle AutoSpecCookie;
ConVar AutoSpecDefValue;

void CookiesInit()
{
    AutoSpecDefValue = CreateConVar("sm_specboss_auto_default", "0");
    AutoExecConfig(true, "plugin.SpecBoss");

    AutoSpecCookie = RegClientCookie("AutoSpecBoss", "", CookieAccess_Private);
    SetCookieMenuItem(CookieMenuHandler, 0, "AutoSpecBoss");
}

public void OnClientCookiesCached(int client)
{
    if(!IsClientInGame(client) || IsFakeClient(client))
        return;

    ReadClientCookies(client);
}

void ReadClientCookies(int client)
{
    char value[4];
    GetClientCookie(client, AutoSpecCookie, value, sizeof(value));

    if(value[0])
    {
        Clients[client].AutoSpectating = !!(StringToInt(value));
        return;
    }

    Clients[client].AutoSpectating = AutoSpecDefValue.BoolValue;
    
}

public void CookieMenuHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
    switch(action)
    {
        case CookieMenuAction_DisplayOption:
        {
            FormatEx(buffer, maxlen, "AutoSpecBoss: [%s]", Clients[client].AutoSpectating ? "✔":"×");
        }
        case CookieMenuAction_SelectOption:
        {
            ToggleClientAutoSpec(client);
            ShowCookieMenu(client);
        }
    }
}

stock void ToggleClientAutoSpec(int client)
{
    Clients[client].AutoSpectating = !Clients[client].AutoSpectating;
    SetClientCookie(client, AutoSpecCookie, Clients[client].AutoSpectating ? "1":"0");
}

stock void AutoSpectateBoss()
{
    int entity = BossGetSpecEntity();

    if(entity == INVALID_ENT_REFERENCE)
        return;

    for(int i = 1; i <= MaxClients; i++)
    {
        if(Clients[i].AutoSpectating)
        {
            if(BossClientCanSpec(i) == CLIENT_SPEC_SUCCESS)
                SpectateClientBoss(i, entity);
        }
    }
}

bool ClientCookiesCached(int client)
{
    return AreClientCookiesCached(client);
}