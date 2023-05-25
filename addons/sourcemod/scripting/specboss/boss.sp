int CurrentBoss = -1;

Handle StartBossTimer;
Handle EndBossTimer;

void BossInit()
{
    RegConsoleCmd("sm_boss", Command_Boss);
}

public Action Command_Boss(int client, int args)
{
    if(CurrentBoss == -1)
        return Plugin_Handled;

    if(UnSpectateClientBoss(client))
        return Plugin_Handled;

    if(!Configs[CurrentBoss].SpecEntityRef)
        return Plugin_Handled;

    int entity = EntRefToEntIndex(Configs[CurrentBoss].SpecEntityRef);

    if(entity == INVALID_ENT_REFERENCE)
        return Plugin_Handled;
        
    SpectateClientBoss(client, entity);
    return Plugin_Handled;
}

void BossOnMapEnd()
{
    CurrentBoss = -1;
    StartBossTimer = null;
    EndBossTimer = null;
}

void BossRoundStart()
{
    RoundStarted = true;

    int entity = INVALID_ENT_REFERENCE;

    while((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT_REFERENCE)
        HandleEntity(entity);
}

void BossRoundEnd()
{
    delete StartBossTimer;
    delete EndBossTimer;
    delete RoundStartTimer;
    RoundStarted = false;
    EndBoss();
    ClearAllEntities();
}

public void OnEntitySpawned(int entity, const char[] classname)
{
    if(!RoundStarted)
        return;

    if(!IsValidEntity(entity))
        return;

    HandleEntity(entity);
}

bool HandleEntity(int entity)
{
    if(HandleStartEntity(entity))
        return true;

    if(HandleEndEntity(entity))
        return true;

    if(HandleSpecEntity(entity))
        return true;

    return false;
}

bool HandleStartEntity(int entity)
{
    int config = FindConfigByStartEntity(entity);

    if(config == -1)
        return false;

    Configs[config].StartEntityRef = EntToRef(entity);
    HookSingleEntityOutput(entity, Configs[config].StartEntityOutput, Output_StartBoss, true);
    return true;
}

bool HandleEndEntity(int entity)
{
    int config = FindConfigByEndEntity(entity);

    if(config == -1)
        return false;

    Configs[config].EndEntityRef = EntToRef(entity);
    HookSingleEntityOutput(entity, Configs[config].EndEntityOutput, Output_EndBoss, true);
    return true;
}

stock bool HandleSpecEntity(int entity)
{
    int config = FindConfigBySpecEntity(entity);

    if(config == -1)
        return false;

    Configs[config].SpecEntityRef = EntToRef(entity);
    return true;
}

public void Output_StartBoss(const char[] output, int caller, int activator, float delay)
{
    int config = GetConfigByStartEntity(EntToRef(caller));

    if(config == -1)
        return;

    delete StartBossTimer;
    StartBossTimer = CreateTimer(Configs[config].StartEntityDelay, Timer_StartBoss, config, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_StartBoss(Handle timer, int config)
{
    StartBossTimer = null;

    StartBoss(config);
    return Plugin_Continue;
}

public void Output_EndBoss(const char[] output, int caller, int activator, float delay)
{
    int config = GetConfigByEndEntity(EntToRef(caller));

    if(config == -1)
        return;

    delete EndBossTimer;
    EndBossTimer = CreateTimer(Configs[config].EndEntityDelay, Timer_EndBoss, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_EndBoss(Handle timer)
{
    EndBossTimer = null;

    EndBoss();
    return Plugin_Continue;
}

public void OnEntityDestroyed(int entity)
{
    if(CurrentBoss == -1)
        return;

    if(Configs[CurrentBoss].SpecEntityRef == EntToRef(entity))
        EndBoss();
}

void StartBoss(int config)
{
    EndBoss();

    CurrentBoss = config;

    PrintToChatAll2("%t", "Spec availbale");
    
    #if defined COOKIE
    AutoSpectateBoss();
    #endif
}

void EndBoss()
{
    if(CurrentBoss == -1)
        return;

    for(int i = 1; i <= MaxClients; i++)
        UnSpectateClientBoss(i);

    ClearEntities(CurrentBoss);
    CurrentBoss = -1;
}

int EntToRef(int entity)
{
    if(entity > 0)
        return EntIndexToEntRef(entity);

    return entity;
}