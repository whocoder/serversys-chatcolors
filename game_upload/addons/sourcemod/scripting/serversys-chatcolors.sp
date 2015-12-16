#include <sourcemod>
#include <serversys-chatcolors>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[Server-Sys] Chat Colors",
	description = "Server-Sys chat colors and tag handler.",
	author = "whocodes",
	version = SERVERSYS_VERSION,
	url = SERVERSYS_URL
}

int g_iColorCount = 18;

bool g_bEnablePlugin = true;
bool g_bDatabaseReady = false;

char g_cCommand_SetTag[64];
char g_cCommand_SetMsg[64];
char g_cCommand_Colors[64];

char g_cCustomMsg[MAXPLAYERS+1][MAX_COLOR_LENGTH];
char g_cCustomTag[MAXPLAYERS+1][MAX_TAG_LENGTH];

#include "serversys/validcolors.sp"

public void OnDatabaseLoaded(bool success){
	g_bDatabaseReady = success;
}

public void OnPluginStart(){
	if(IsSource2009()){
		g_iColorCount = 173;
	}

	LoadConfig();
}

void LoadConfig(){
	Handle kv = CreateKeyValues("Chat-Colors");
	char Config_Path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Config_Path, sizeof(Config_Path), "configs/serversys/chatcolors.cfg");

	if(!(FileExists(Config_Path)) || !(FileToKeyValues(kv, Config_Path))){
		Sys_KillHandle(kv);
		SetFailState("[serversys] chat-colors :: Cannot read from configuration file: %s", Config_Path);
	}

	g_bEnablePlugin = view_as<bool>(KvGetNum(kv, "enabled", 1));

	KvGetString(kv, "command_colors", g_cCommand_Colors, sizeof(g_cCommand_Colors), "!colors /colors");
	KvGetString(kv, "command_settag", g_cCommand_SetTag, sizeof(g_cCommand_SetTag), "!ctag /ctag");
	KvGetString(kv, "command_setmsg", g_cCommand_SetMsg, sizeof(g_cCommand_SetMsg), "!cmsg /cmsg");

	Sys_KillHandle(kv);
}

public void OnAllPluginsLoaded(){
	Sys_RegisterChatCommand(g_cCommand_Colors, Command_Colors);
	Sys_RegisterChatCommand(g_cCommand_SetTag, Command_SetTag);
	Sys_RegisterChatCommand(g_cCommand_SetMsg, Command_SetMessage);
}

public void OnPlayerIDLoaded(int client, int playerid){
	if(g_bEnablePlugin && (playerid != 0) && (0 < client <= MaxClients)){
		// sql shit
	}
}

public void Command_Colors(int client, const char[] command, const char[] args){
	if(!g_bEnablePlugin)
		return;

	if(!(0 < client <= MaxClients))
		return;

	char buffer[32];
	for(int i = 0; i < g_iColorCount; i++){
		strcopy(buffer, sizeof(buffer), (IsSource2009() ? c_Source2009[i] : c_Source2013[i]));
		CFormatColor(buffer, sizeof(buffer), client);

		PrintToChat(client, " > %s%s", buffer, (IsSource2009() ? c_Source2009[i] : c_Source2013[i]));
	}


	return;
}

public void Command_SetTag(int client, const char[] command, const char[] args){
	if(!g_bEnablePlugin)
		return;

	if(!(0 < client <= MaxClients))
		return;

	if(!CheckCommandAccess(client, "sm_sys_chatcolors", ADMFLAG_GENERIC))
		return;

	bool found = false;
	for(int i = 0; i < g_iColorCount; i++){
		if(StrEqual(args, (IsSource2009() ? c_Source2009[i] : c_Source2013[i]), false)){
			found = true;
			break;
		}
	}

	if(found){
		strcopy(g_cCustomMsg[client], MAX_COLOR_LENGTH, args);
		CPrintToChat(client, "Success!");
		// sql shit
	}


	return;
}

public void Command_SetMessage(int client, const char[] command, const char[] args){
	if(!g_bEnablePlugin)
		return;

	if(!(0 < client <= MaxClients))
		return;

	if(!CheckCommandAccess(client, "sm_sys_chatcolors", ADMFLAG_GENERIC))
		return;

	strcopy(g_cCustomTag[client], MAX_TAG_LENGTH, args);
	CPrintToChat(client, "Success!");
	// sql shit

	return;
}

public Action OnChatMessage(int &author, Handle recipients, char[] name, char[] message){
	if(!g_bEnablePlugin)
		return Plugin_Continue;

	if(!((0 < author <= MaxClients) && (IsClientInGame(author))))
		return Plugin_Continue;

	if(!CheckCommandAccess(author, "sm_sys_chatcolors", ADMFLAG_GENERIC))
		return Plugin_Continue;

	char name_prefix[MAX_NAME_LENGTH];
	char msg_prefix[MAX_MESSAGE_LENGTH];

	if(strlen(g_cCustomTag[author]) > 0){
		FormatEx(name_prefix, MAX_NAME_LENGTH, "%s", g_cCustomTag[author]);
		CFormatColor(name_prefix, MAX_NAME_LENGTH, author);
		FormatEx(name, MAX_NAME_LENGTH, "%s%s", name_prefix, name);
	}

	if(strlen(g_cCustomMsg[author]) > 0){
		FormatEx(msg_prefix, MAX_MESSAGE_LENGTH, "%s", g_cCustomMsg[author]);
		CFormatColor(msg_prefix, MAX_MESSAGE_LENGTH, author);
		FormatEx(message, MAX_MESSAGE_LENGTH, "%s%s", msg_prefix, message);
	}

	return Plugin_Changed;
}
