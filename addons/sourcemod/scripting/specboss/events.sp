bool RoundStarted;
Handle RoundStartTimer;

void EventsOnMapEnd()
{
    RoundStartTimer = null;
}

void EventsInit()
{
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    BossRoundEnd();

    RoundStartTimer = CreateTimer(5.0, Timer_RoundStart, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_RoundStart(Handle timer)
{
    RoundStartTimer = null;

    BossRoundStart();
    return Plugin_Continue;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    BossRoundEnd();
}
