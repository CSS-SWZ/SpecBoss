#define FLAG_SPECTATORS_ONLY (1 << 0)
#define FLAG_HUMANS_CAN_USE (1 << 1)

enum struct Config
{
    int StartEntityRef;
    int StartEntityHammerID;
    char StartEntityTargetname[64];
    char StartEntityOutput[64];
    float StartEntityDelay;

    int EndEntityRef;
    int EndEntityHammerID;
    char EndEntityTargetname[64];
    char EndEntityOutput[64];
    float EndEntityDelay;

    int SpecEntityRef;
    int SpecEntityHammerID;
    char SpecEntityTargetname[64];

    bool Alert;
    int Flags;
}

int ConfigsCount;
Config Configs[MAX_BOSSES_CONFIGS];

void ConfigOnMapStart()
{
    LoadConfig();
}

void ConfigOnMapEnd()
{
    ClearAllEntities();
    ClearConfigs();
}

void LoadConfig()
{
    char map[64];
    GetCurrentMap(map, sizeof(map));

    char buffer[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, buffer, sizeof(buffer), "configs/specboss/%s.cfg", map);

    KeyValues kv = new KeyValues("bosses");

    if(!kv.ImportFromFile(buffer) || !kv.GotoFirstSubKey())
    {
        delete kv;
        return;
    }

    int alert = kv.GetNum("alert", 1);
    int flags = kv.GetNum("flags", 0);

    char start[256];
    char end[256];
    char spec[64];

    do
    {
        kv.GetString("start", start, sizeof(start));
        kv.GetString("end", end, sizeof(end));
        kv.GetString("spec", spec, sizeof(spec));

        if(!ParseStartString(start))
            continue;

        ParseEndString(end);

        if(!ParseSpecString(spec))
            continue;

        Configs[ConfigsCount].Alert = !!(kv.GetNum("alert", alert));
        Configs[ConfigsCount].Flags = kv.GetNum("flags", flags);
        ++ConfigsCount;
    }
    while(kv.GotoNextKey() && ConfigsCount < MAX_BOSSES_CONFIGS);

    delete kv;
}

bool ParseStartString(const char[] start)
{
    if(!start[0])
        return false;

    char buffers[3][64];

    int count = ExplodeString(start, ":", buffers, sizeof(buffers), sizeof(buffers[]));

    if(count < 2)
        return false;

    int config = ConfigsCount;

    if(buffers[0][0] == '#')
        Configs[config].StartEntityHammerID = StringToInt(buffers[0][1]);
    else
        strcopy(Configs[config].StartEntityTargetname, sizeof(Configs[].StartEntityTargetname), buffers[0]);
        
    strcopy(Configs[config].StartEntityOutput, sizeof(Configs[].StartEntityOutput), buffers[1]);

    if(count > 2)
        Configs[config].StartEntityDelay = StringToFloat(buffers[2]);

    return true;
}

void ParseEndString(const char[] end)
{
    if(!end[0])
        return;

    char buffers[3][64];

    int count = ExplodeString(end, ":", buffers, sizeof(buffers), sizeof(buffers[]));

    if(count < 2)
        return;

    int config = ConfigsCount;

    if(buffers[0][0] == '#')
        Configs[config].EndEntityHammerID = StringToInt(buffers[0][1]);
    else
        strcopy(Configs[config].EndEntityTargetname, sizeof(Configs[].EndEntityTargetname), buffers[0]);
        
    strcopy(Configs[config].EndEntityOutput, sizeof(Configs[].EndEntityOutput), buffers[1]);

    if(count > 2)
        Configs[config].EndEntityDelay = StringToFloat(buffers[2]);

    return;
}

bool ParseSpecString(const char[] spec)
{
    if(!spec[0])
        return false;

    int config = ConfigsCount;

    if(spec[0] == '#')
        Configs[config].SpecEntityHammerID = StringToInt(spec);
    else
        strcopy(Configs[config].SpecEntityTargetname, sizeof(Configs[].SpecEntityTargetname), spec);
    
    return true;
}

int GetConfigByStartEntity(int entity)
{
    for(int i = 0; i < ConfigsCount; i++)
    {
        if(Configs[i].StartEntityRef && Configs[i].StartEntityRef == entity)
            return i;
    }

    return -1;
}

int GetConfigByEndEntity(int entity)
{
    for(int i = 0; i < ConfigsCount; i++)
    {
        if(Configs[i].EndEntityRef && Configs[i].EndEntityRef == entity)
            return i;
    }

    return -1;
}

stock int GetConfigBySpecEntity(int entity)
{
    for(int i = 0; i < ConfigsCount; i++)
    {
        if(EntRefToEntIndex(Configs[i].SpecEntityRef) == entity)
            return i;
    }

    return -1;
}

int FindConfigByStartEntity(int entity)
{
    char targetname[64];
    GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

    if(targetname[0])
    {
        int symbol = FindCharInString(targetname, '&');

        if(symbol > 0)
            targetname[symbol] = 0;

        for(int i = 0; i < ConfigsCount; i++)
        {
            if(!strcmp(targetname, Configs[i].StartEntityTargetname, false))
                return i;
        }
     }

     
    int hammerid = GetEntProp(entity, Prop_Data, "m_iHammerID");

    switch(hammerid)
    {
        case 0: return -1;

        default:
        {
            for(int i = 0; i < ConfigsCount; i++)
            {
                if(Configs[i].StartEntityHammerID == hammerid)
                    return i;
            }

        }
    }

    return -1;
}

int FindConfigByEndEntity(int entity)
{
    char targetname[64];
    GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

    if(targetname[0])
    {
        int symbol = FindCharInString(targetname, '&');

        if(symbol > 0)
            targetname[symbol] = 0;

        for(int i = 0; i < ConfigsCount; i++)
        {
            if(!strcmp(targetname, Configs[i].EndEntityTargetname, false))
                return i;
        }
     }

     
    int hammerid = GetEntProp(entity, Prop_Data, "m_iHammerID");

    switch(hammerid)
    {
        case 0: return -1;

        default:
        {
            for(int i = 0; i < ConfigsCount; i++)
            {
                if(Configs[i].EndEntityHammerID == hammerid)
                    return i;
            }

        }
    }

    return -1;
}

int FindConfigBySpecEntity(int entity)
{
    char targetname[64];
    GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

    if(targetname[0])
    {
        int symbol = FindCharInString(targetname, '&');

        if(symbol > 0)
            targetname[symbol] = 0;

        for(int i = 0; i < ConfigsCount; i++)
        {
            if(!strcmp(targetname, Configs[i].SpecEntityTargetname, false))
                return i;
        }
     }

     
    int hammerid = GetEntProp(entity, Prop_Data, "m_iHammerID");

    switch(hammerid)
    {
        case 0: return -1;

        default:
        {
            for(int i = 0; i < ConfigsCount; i++)
            {
                if(Configs[i].SpecEntityHammerID == hammerid)
                    return i;
            }

        }
    }

    return -1;
}

bool IsEntityForConfigEnd(int entity, int config)
{
    int hammerid = GetEntProp(entity, Prop_Data, "m_iHammerID");

    switch(hammerid)
    {
        case 0:
        {
            char targetname[64];
            GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

            if(targetname[0] && !strcmp(targetname, Configs[config].EndEntityTargetname, false))
                return true;
        }

        default:
        {
            if(Configs[config].EndEntityHammerID == hammerid)
                return true;
        }
    }

    return false;
}

bool IsEntityForConfigSpec(int entity, int config)
{
    int hammerid = GetEntProp(entity, Prop_Data, "m_iHammerID");

    switch(hammerid)
    {
        case 0:
        {
            char targetname[64];
            GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

            if(targetname[0] && !strcmp(targetname, Configs[config].SpecEntityTargetname, false))
                return true;
        }

        default:
        {
            if(Configs[config].SpecEntityHammerID == hammerid)
                return true;
        }
    }

    return false;
}

stock bool ConfigIsLoaded()
{
    return (ConfigsCount > 0);
}

void ClearConfigs()
{
    for(int i = 0; i < ConfigsCount; i++)
    {
        Configs[i].StartEntityHammerID = 0;
        Configs[i].StartEntityTargetname[0] = 0;
        Configs[i].StartEntityOutput[0] = 0;
        Configs[i].StartEntityDelay = 0.0;

        Configs[i].EndEntityHammerID = 0;
        Configs[i].EndEntityTargetname[0] = 0;
        Configs[i].EndEntityOutput[0] = 0;
        Configs[i].EndEntityDelay = 0.0;

        Configs[i].SpecEntityHammerID = 0;
        Configs[i].SpecEntityTargetname[0] = 0;

        Configs[i].Alert = true;
        Configs[i].Flags = 0;
    }

    ConfigsCount = 0;
}

void ClearAllEntities()
{
    for(int i = 0; i < ConfigsCount; i++)
    {
        ClearEntities(i);
    }
}

void ClearEntities(int config)
{
    Configs[config].StartEntityRef = 0;
    Configs[config].EndEntityRef = 0;
    Configs[config].SpecEntityRef = 0;
}