enum struct Client
{
    bool Spectating;

    #if defined COOKIE
    bool AutoSpectating;
    #endif
}

Client Clients[MAXPLAYERS + 1];

public void OnClientPutInServer(int client)
{
    if(IsFakeClient(client))
        return;

    #if defined COOKIE
    if(ClientCookiesCached(client))
        ReadClientCookies(client);
    #endif
}

public void OnClientDisconnect(int client)
{
    #if defined COOKIE
    Clients[client].AutoSpectating = false;
    #endif

    UnSpectateClientBoss(client);
}

bool SpectateClientBoss(int client, int specEntity)
{
    if(Clients[client].Spectating)
        return true;

    SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDEHUD_PLAYERDEATH);
    SetClientViewEntity(client, specEntity);
    Clients[client].Spectating = true;

    return true;
}

bool UnSpectateClientBoss(int client)
{
    if(Clients[client].Spectating)
    {
        Clients[client].Spectating = false;
        SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") & ~(HIDEHUD_PLAYERDEATH));
        SetClientViewEntity(client, client);
        return true;
    }

    return false;
}