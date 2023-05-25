#if !defined COOKIE
    #endinput
#endif

#include <clientprefs>

Handle AutoSpecCookie;

void CookiesInit()
{
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
        Clients[client].AutoSpectating = !!(StringToInt(value));
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
    if(!Configs[CurrentBoss].SpecEntityRef)
        return;

    int entity = EntRefToEntIndex(Configs[CurrentBoss].SpecEntityRef);

    if(entity == INVALID_ENT_REFERENCE)
        return;

    for(int i = 1; i <= MaxClients; i++)
    {
        if(Clients[i].AutoSpectating)
        {
            SpectateClientBoss(i, entity);
        }
    }
}