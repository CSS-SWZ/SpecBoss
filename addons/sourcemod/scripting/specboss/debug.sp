#if defined DEBUG
#define Debug(%0) DebugMessage(%0)

stock void DebugMessage(const char[] format, any ...)
{
    int len = strlen(format) + 255;
    char[] buffer = new char[len];
    VFormat(buffer, len, format, 2);
    PrintToConsoleAll("%f %s", GetEngineTime(), buffer);
}

stock void SendMessage(int client, char[] buffer, int iSize)
{
	//Format(buffer, iSize, "\x01\x07%s%t \x07%s%s", Colors[COLOR_TAG], "Tag", Colors[COLOR_OTHER], buffer);
	ReplaceString(buffer, iSize, "{C}", "\x07");

	
	Handle hMessage = StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	BfWrite bfWrite = UserMessageToBfWrite(hMessage);
	bfWrite.WriteByte(client);
	bfWrite.WriteByte(true);
	bfWrite.WriteString(buffer);
	EndMessage();
}

#else
#define Debug(%0) 
#endif