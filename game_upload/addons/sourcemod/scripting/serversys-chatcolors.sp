#include <sourcemod>
#include <multicolors>
#include <scp>

#include <serversys>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[Server-Sys] Chat Colors",
	description = "Server-Sys chat colors and tag handler.",
	author = "cam",
	version = SERVERSYS_VERSION,
	url = SERVERSYS_URL
}

bool g_bEnablePlugin = true;
bool g_bDatabaseReady = false;

// Longest a color translation should be
#define MAX_COLOR_LENGTH 32

char g_cCustomMsgColor[MAXPLAYERS+1][MAX_COLOR_LENGTH];
char g_cCustomNameColor[MAXPLAYERS+1][MAX_COLOR_LENGTH];
char g_cCustomTagMessage[MAXPLAYERS+1][MAX_TAG_LENGTH];

public void OnDatabaseLoaded(bool success){
	g_bDatabaseReady = success;
}

public void OnPlayerIDLoaded(int client, int playerid){
	if(g_bEnablePlugin){

	}
}

public Action OnChatMessage(int &author, Handle recipients, char[] name, char[] message){
	if(!g_bEnablePlugin)
		return Plugin_Continue;

	if(!((0 < author <= MaxClients) && (IsClientInGame(author))))
		return Plugin_Continue;

	char name_prefix[MAX_NAME_LENGTH];
	char msg_prefix[MAX_MESSAGE_LENGTH];

	if(strlen(g_cCustomTagMessage[author]) > 0)
		FormatEx(name_prefix, MAX_NAME_LENGTH, "%s", g_cCustomTagMessage[author], name)

	if(strlen(g_cCustomNameColor[author]) > 0)
		FormatEx(name_prefix, MAX_NAME_LENGTH, "%s%s", name_prefix, g_cCustomNameColor[author]);

	if(strlen(g_cCustomMsgColor[author]) > 0)
		FormatEx(msg_prefix, MAX_MESSAGE_LENGTH, "%s", g_cCustomMsgColor[author]);

	CFormatColor(name_prefix, MAX_NAME_LENGTH, author);
	CFormatColor(msg_prefix, MAX_MESSAGE_LENGTH, author);
	FormatEx(name, MAX_NAME_LENGTH, "%s%s", name_prefix, name);
	FormatEx(message, MAX_MESSAGE_LENGTH, "%s%s", msg_prefix, message);

	return Plugin_Changed;
}
