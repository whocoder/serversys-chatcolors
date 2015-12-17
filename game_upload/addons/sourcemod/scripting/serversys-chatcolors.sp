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
bool g_bDatabaseReady = true;

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
	LoadTranslations("serversys.chatcolors.phrases");

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
	Sys_RegisterChatCommand(g_cCommand_SetMsg, Command_SetMsg);
}

public void OnPlayerIDLoaded(int client, int playerid){
	strcopy(g_cCustomTag[client], MAX_TAG_LENGTH, "");
	strcopy(g_cCustomMsg[client], MAX_COLOR_LENGTH, "");
	
	if(g_bEnablePlugin && (playerid > -1) && (0 < client <= MaxClients)){
		char query[1024];
		Format(query, sizeof(query), "INSERT IGNORE INTO chatcolors(pid, game) VALUES(%d, %d);", playerid, view_as<int>(GetEngineVersion()));

		Sys_DB_TQuery(Colors_Insert, query, GetClientSerial(client));
	}
}

public void Colors_Insert(Handle owner, Handle hndl, const char[] error, any serial){
	if(hndl == INVALID_HANDLE){
		LogError("[serversys] chat-colors :: Error inserting users chat-colors: %s", error);
		return;
	}

	int client = GetClientFromSerial(serial);

	if((0 < client <= MaxClients)){
		char query[1024];
		Format(query, sizeof(query), "SELECT tag, msg FROM chatcolors WHERE pid='%d' AND game='%d';", Sys_GetPlayerID(client), view_as<int>(GetEngineVersion()));
		Sys_DB_TQuery(Colors_Loaded, query, GetClientSerial(client));
	}
}

public void Colors_Loaded(Handle owner, Handle hndl, const char[] error, any serial){
	if(hndl == INVALID_HANDLE){
		LogError("[serversys] chat-colors :: Error selecting users chat-colors: %s", error);
		return;
	}

	int client = GetClientFromSerial(serial);

	if((0 < client <= MaxClients) && SQL_FetchRow(hndl)){
		char tagbuffer[MAX_TAG_LENGTH];
		char msgbuffer[MAX_COLOR_LENGTH];

		SQL_FetchString(hndl, 0, tagbuffer, sizeof(tagbuffer));
		strcopy(g_cCustomTag[client], MAX_TAG_LENGTH, tagbuffer);

		SQL_FetchString(hndl, 1, msgbuffer, sizeof(msgbuffer));
		strcopy(g_cCustomMsg[client], MAX_COLOR_LENGTH, msgbuffer);

		//PrintToConsole(client, "%t", "Loaded successfully console");
	}
}

public void Generic_Callback(Handle owner, Handle hndl, const char[] error, any userid){
	if(hndl == INVALID_HANDLE){
		LogError("[serversys] chat-colors :: Generic SQL callback error: %s", error);
		return;
	}
}

public void Command_Colors(int client, const char[] command, const char[] args){
	if(!g_bEnablePlugin)
		return;

	if(!(0 < client <= MaxClients))
		return;

	CPrintToChat(client, "%t", "Listing colors");

	DataPack pack = new DataPack();
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(0);
	RequestFrame(Frame_Colors, pack);

	return;
}

public void Frame_Colors(DataPack pack){
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());

	if((0 < client <= MaxClients) && IsClientInGame(client)){
		int pos = pack.ReadCell();
		CloseHandle(pack);

		int i = pos;
		char buffer[32];
		for(; ((i < g_iColorCount) && (i < (pos + 3))); i++){
			strcopy(buffer, sizeof(buffer), (IsSource2009() ? c_Source2009[i] : c_Source2013[i]));
			CFormatColor(buffer, sizeof(buffer), 0);

			PrintToChat(client, "%t", "Single color", buffer, (IsSource2009() ? c_Source2009[i] : c_Source2013[i]));
		}

		if(i < g_iColorCount){
			DataPack newpack = new DataPack();
			newpack.WriteCell(GetClientUserId(client));
			newpack.WriteCell(i);

			RequestFrame(Frame_Colors, view_as<any>(newpack));
		}
	}
}

public void Command_SetMsg(int client, const char[] command, const char[] args){
	if(!g_bEnablePlugin)
		return;

	if(!(0 < client <= MaxClients))
		return;

	if(!CheckCommandAccess(client, "sm_sys_chatcolors", ADMFLAG_GENERIC)){
		CPrintToChat(client, "%t", "No permissions to use");
		return;
	}

	bool found = false;
	for(int i = 0; i < g_iColorCount; i++){
		if(StrEqual(args, (IsSource2009() ? c_Source2009[i] : c_Source2013[i]), false)){
			found = true;
			break;
		}
	}

	if(found){
		strcopy(g_cCustomMsg[client], MAX_COLOR_LENGTH, args);

		if(Sys_GetPlayerID(client) > -1){
			char query[1024];
			Format(query, sizeof(query), "UPDATE chatcolors SET msg='%s' WHERE pid=%d AND game=%d;", g_cCustomMsg[client], Sys_GetPlayerID(client), view_as<int>(GetEngineVersion()));

			Sys_DB_TQuery(Generic_Callback, query);
			CPrintToChat(client, "%t", "Chat settings updated");
		}
	}else
		CPrintToChat(client, "%t", "Invalid color specified");


	return;
}

public void Command_SetTag(int client, const char[] command, const char[] args){
	if(!g_bEnablePlugin)
		return;

	if(!(0 < client <= MaxClients))
		return;

	if(!CheckCommandAccess(client, "sm_sys_chatcolors", ADMFLAG_GENERIC)){
		CPrintToChat(client, "%t", "No permissions to use");
		return;
	}

	strcopy(g_cCustomTag[client], MAX_TAG_LENGTH, args);
	if(Sys_GetPlayerID(client) > -1){
		char query[1024];
		Format(query, sizeof(query), "UPDATE chatcolors SET tag='%s' WHERE pid=%d AND game=%d;", g_cCustomTag[client], Sys_GetPlayerID(client), view_as<int>(GetEngineVersion()));

		Sys_DB_TQuery(Generic_Callback, query);
		CPrintToChat(client, "%t", "Chat settings updated");
	}

	return;
}

public Action OnChatMessage(int &author, Handle recipients, char[] name, char[] message){
	if(!g_bEnablePlugin)
		return Plugin_Continue;

	if(!((0 < author <= MaxClients) && (IsClientInGame(author))))
		return Plugin_Continue;

	if(!CheckCommandAccess(author, "sm_sys_chatcolors", ADMFLAG_GENERIC))
		return Plugin_Continue;

	char name_prefix[MAXLENGTH_NAME];
	char msg_prefix[MAXLENGTH_MESSAGE];

	if(strlen(g_cCustomTag[author]) > 0){
		Format(name_prefix, MAXLENGTH_NAME, "%s", g_cCustomTag[author]);
		CFormatColor(name_prefix, MAXLENGTH_NAME, 0);
		Format(name, MAXLENGTH_NAME, "%s%s", name_prefix, name);
	}

	if(strlen(g_cCustomMsg[author]) > 0){
		Format(msg_prefix, MAXLENGTH_MESSAGE, "%s", g_cCustomMsg[author]);
		CFormatColor(msg_prefix, MAXLENGTH_MESSAGE, 0);
		Format(message, MAXLENGTH_MESSAGE, "%s%s", msg_prefix, message);
	}

	return Plugin_Changed;
}
