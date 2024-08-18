#define ADMIN_FLAG (ADMFLAG_BAN | ADMFLAG_RCON | ADMFLAG_ROOT)

#define CLIENT_SPEC_SUCCESS             0
#define CLIENT_SPEC_FAILURE_HUMAN       1
#define CLIENT_SPEC_FAILURE_NOT_SPEC    2

int CurrentBoss = -1;

Handle StartBossTimer;
Handle EndBossTimer;

void BossInit()
{
    RegConsoleCmd("sm_boss", Command_Boss);
}

void BossOnMapStart()
{
    if(!Late)
        return;

    Late = false;
    BossRoundStart();
}

public Action Command_Boss(int client, int args)
{
    if(!client)
        return Plugin_Handled;

    if(!ConfigIsLoaded())
    {
        PrintToChat2(client, "%t", "No config");
        return Plugin_Handled;
    }
    if(!BossIsCurrentBoss())
    {
        PrintToChat2(client, "%t", "No currentboss");
        return Plugin_Handled;
    }

    int entity = BossGetSpecEntity();

    if(entity == INVALID_ENT_REFERENCE)
    {
        PrintToChat2(client, "%t", "No currentboss");
        return Plugin_Handled;
    }

    if(args > 0 && GetUserFlagBits(client) & ADMIN_FLAG)
    {
        char buffer[64];
        char target_name[MAX_TARGET_LENGTH];
        int targets[MAXPLAYERS];
        int targets_count;
        int real_targets_count;
        int target;
        bool tn_is_ml;

        GetCmdArg(1, buffer, sizeof(buffer));
        
        if((targets_count = ProcessTargetString(buffer, client, targets, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
        {
        	ReplyToTargetError(client, targets_count);
        	return Plugin_Handled;
        }

        for(int i = 0; i < targets_count; i++)
        {
            target = targets[i];
            
            if(Clients[target].Spectating)
                continue;
            
            if(BossClientCanSpec(target) == CLIENT_SPEC_SUCCESS)
            {
                if(SpectateClientBoss(target, entity))
                    ++real_targets_count;
            }

        }

        if(!real_targets_count)
            return Plugin_Handled;

        ShowActivity2(client, "\x01[SM] \x04", "\x01Set boss spectating on target \x04%s", target_name);

        if(real_targets_count > 1)
        	LogAction(client, -1, "\"%L\" set boss spectating on target \"%s\"", client, target_name);
        else
        	LogAction(client, targets[0], "\"%L\" set boss spectating on target \"%L\"", client, targets[0]);

        return Plugin_Handled;
    }

    if(UnSpectateClientBoss(client))
    {
        PrintToChat2(client, "%t", "Specboss off");
        return Plugin_Handled;
    }

    switch(BossClientCanSpec(client))
    {
        case CLIENT_SPEC_FAILURE_NOT_SPEC:
        {
            PrintToChat2(client, "%t", "Only specs");
            return Plugin_Handled;
        }
        case CLIENT_SPEC_FAILURE_HUMAN:
        {
            PrintToChat2(client, "%t", "Humans cant use");
            return Plugin_Handled;
        }

        case CLIENT_SPEC_SUCCESS:
        {
            if(SpectateClientBoss(client, entity))
                PrintToChat2(client, "%t", "Specboss on");
        }
    }
        

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
    if(!ConfigsCount)
        return;

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

    //Debug("OnEntitySpawned(entity = %i, classname = %s)", entity, classname)
    HandleEntity(entity);
}

bool HandleEntity(int entity)
{
    static int config;
    config = HandleStartEntity(entity);
    HandleEndEntity(entity, config);
    HandleSpecEntity(entity, config);
    return true;
}

int HandleStartEntity(int entity)
{
    int config = FindConfigByStartEntity(entity);

    switch(config)
    {
        case -1: return -1;

        default:
        {
            //Debug("HandleStartEntity(entity = %i) - config id = %i", entity, config)
            Configs[config].StartEntityRef = EntToRef(entity);
            HookSingleEntityOutput(entity, Configs[config].StartEntityOutput, Output_StartBoss, true);
        }
    }

    return config;
}

void HandleEndEntity(int entity, int& config)
{
    switch(config)
    {
        case -1:
        {
            config = FindConfigByEndEntity(entity);

            switch(config)
            {
                case -1: return;

                default:
                {
                    //Debug("HandleEndEntity(entity = %i) - config id = %i", entity, config)
                    Configs[config].EndEntityRef = EntToRef(entity);
                    HookSingleEntityOutput(entity, Configs[config].EndEntityOutput, Output_EndBoss, true);
                }
            }

        }
        default:
        {
            if(IsEntityForConfigEnd(entity, config))
            {
                Configs[config].EndEntityRef = EntToRef(entity);
                HookSingleEntityOutput(entity, Configs[config].EndEntityOutput, Output_EndBoss, true);
            }
        }
    }
}

void HandleSpecEntity(int entity, int config)
{
    switch(config)
    {
        case -1:
        {
            config = FindConfigBySpecEntity(entity);

            switch(config)
            {
                case -1: return;

                default:
                {
                    //Debug("HandleSpecEntity(entity = %i) - config id = %i", entity, config)
                    Configs[config].SpecEntityRef = EntToRef(entity);
                }
            }
        }
        default:
        {
            if(IsEntityForConfigSpec(entity, config))
            {
                Configs[config].SpecEntityRef = EntToRef(entity);
            }
        }
    }
}

public void Output_StartBoss(const char[] output, int caller, int activator, float delay)
{
    //Debug("Output_StartBoss(output = %s, caller = %i, activator = %i, delay = %.2f)", output, caller, activator, delay)

    int config = GetConfigByStartEntity(EntToRef(caller));

    if(config == -1)
        return;

    //Debug(">Output_StartBoss() - config id = %i (StartEntityDelay = %.2f)", config, Configs[config].StartEntityDelay)
    delete StartBossTimer;
    StartBossTimer = CreateTimer(Configs[config].StartEntityDelay, Timer_StartBoss, config, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_StartBoss(Handle timer, int config)
{
    //Debug("Timer_StartBoss(config = %i)", config)

    StartBossTimer = null;

    StartBoss(config);
    return Plugin_Continue;
}

public void Output_EndBoss(const char[] output, int caller, int activator, float delay)
{
    //Debug("Output_EndBoss(output = %s, caller = %i, activator = %i, delay = %.2f)", output, caller, activator, delay)

    int config = GetConfigByEndEntity(EntToRef(caller));

    if(config == -1)
        return;

    //Debug(">Output_EndBoss() - config id = %i (EndEntityDelay = %.2f)", config, Configs[config].EndEntityDelay)

    delete EndBossTimer;
    EndBossTimer = CreateTimer(Configs[config].EndEntityDelay, Timer_EndBoss, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_EndBoss(Handle timer)
{
    //Debug("Timer_EndBoss()")

    EndBossTimer = null;

    EndBoss();
    return Plugin_Continue;
}

public void OnEntityDestroyed(int entity)
{
    if(CurrentBoss == -1)
        return;

    //Debug("OnEntityDestroyed(entity = %i) - boss id = %i (ent = %i)", entity, CurrentBoss, EntRefToEntIndex(Configs[CurrentBoss].SpecEntityRef))

    if(Configs[CurrentBoss].SpecEntityRef == EntToRef(entity))
        EndBoss();
}

void StartBoss(int config)
{
    //Debug("StartBoss(config = %i)", config)

    EndBoss();

    CurrentBoss = config;

    if(Configs[config].Alert)
        PrintToChatAll2("%t", "Spec availbale");
    
    #if defined COOKIE
    AutoSpectateBoss();
    #endif
}

void EndBoss()
{
    if(CurrentBoss == -1)
        return;

    //Debug("EndBoss(CurrentBoss = %i)", CurrentBoss)

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

stock int BossGetSpecEntity()
{
    if(!Configs[CurrentBoss].SpecEntityRef)
        return INVALID_ENT_REFERENCE;

    return EntRefToEntIndex(Configs[CurrentBoss].SpecEntityRef);
}

stock int BossClientCanSpec(int client)
{
    switch(GetClientTeam(client))
    {
        case 2:
        {
            if(Configs[CurrentBoss].Flags & FLAG_SPECTATORS_ONLY)
            {
                return CLIENT_SPEC_FAILURE_NOT_SPEC;
            }
        }
        case 3:
        {
            if(!(Configs[CurrentBoss].Flags & FLAG_HUMANS_CAN_USE))
            {
                return CLIENT_SPEC_FAILURE_HUMAN;
            }
        }
    }
    
    return CLIENT_SPEC_SUCCESS;
}

stock bool BossIsCurrentBoss()
{
    return (CurrentBoss != -1);
}

stock int BossGetCurrentBoss()
{
    return CurrentBoss;
}