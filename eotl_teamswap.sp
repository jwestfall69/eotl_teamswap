#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include "../eotl_vip_core/eotl_vip_core.inc"

#define PLUGIN_AUTHOR  "ack"
#define PLUGIN_VERSION "2.01"

public Plugin myinfo = {
	name = "eotl_teamswap",
	author = PLUGIN_AUTHOR,
	description = "eotl team swap plugin, allow forced team swaps for vips",
	version = PLUGIN_VERSION,
	url = ""
};

enum struct PlayerState {
    int lastSwap;
}

PlayerState g_playerStates[MAXPLAYERS + 1];
bool g_roundOver;
ConVar g_cvVipOnly;
ConVar g_cvMinTime;
ConVar g_cvDenyFull;

public void OnPluginStart() {
    LogMessage("version %s starting", PLUGIN_VERSION);

    g_cvVipOnly = CreateConVar("eotl_teamswap_viponly", "1", "Restrict team swaps 1=Vips 0=All", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvMinTime = CreateConVar("eotl_teamswap_mintime", "120", "Number of seconds player must wait between team swaps", FCVAR_NOTIFY, true, 0.0, false);
    g_cvDenyFull = CreateConVar("eotl_teamswap_deny_full", "1", "Deny teamswap if team is full (maxplayers / 2) 1=On, 0=Off", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    RegConsoleCmd("sm_teamswap", CommandTeamSwap);
}

public void OnMapStart() {
    g_roundOver = false;

    for (int client = 1; client <= MaxClients; client++) {
        g_playerStates[client].lastSwap = 0;
	}

    HookEvent("teamplay_round_start", EventRoundStart, EventHookMode_PostNoCopy);

    HookEvent("teamplay_round_stalemate", EventRoundEnd, EventHookMode_PostNoCopy);
    HookEvent("teamplay_round_win", EventRoundEnd, EventHookMode_PostNoCopy);
    HookEvent("teamplay_game_over", EventRoundEnd, EventHookMode_PostNoCopy);
}

public void OnClientConnected(int client) {
    g_playerStates[client].lastSwap = 0;
}

public Action EventRoundStart(Handle event, const char[] name, bool dontBroadcast) {
    g_roundOver = false;
    return Plugin_Continue;
}

public Action EventRoundEnd(Handle event, const char[] name, bool dontBroadcast) {
    g_roundOver = true;
    return Plugin_Continue;
}

public Action CommandTeamSwap(int client, int args) {

    if(IsFakeClient(client)) {
        return Plugin_Handled;
    }

    if(GetConVarBool(g_cvVipOnly) && !EotlIsClientVip(client)) {
        PrintToChat(client, "!teamswap requires vip status and you aren't a vip");
        return Plugin_Handled;
    }

    TFTeam team = TF2_GetClientTeam(client);
    if(team != TFTeam_Blue && team != TFTeam_Red) {
        PrintToChat(client, "can't swap teams when you aren't on a team");
        return Plugin_Handled;
    }
    TFTeam want_team = (team == TFTeam_Blue ? TFTeam_Red : TFTeam_Blue);

    if(g_roundOver) {
        PrintToChat(client, "team swap not allowed during end of round");
        return Plugin_Handled;
    }

    if(g_cvDenyFull.BoolValue) {
        int max_allowed = MaxClients / 2;
        int team_player_count = GetTeamPlayerCount(want_team);
        if(team_player_count >= max_allowed) {
            PrintToChat(client, "team swap not allowed because other team is full");
            return Plugin_Handled;
        }
        LogMessage("client %N allowing teamswap only %d of %d allowed on want team", client, team_player_count, max_allowed);
    }
    int swapAge = GetTime() - g_playerStates[client].lastSwap;
    int minAge = GetConVarInt(g_cvMinTime);

    if(swapAge < minAge) {
        PrintToChat(client, "team swaps are only allowed every %d seconds, you last swapped %d seconds ago", minAge, swapAge);
        return Plugin_Handled;
    }

    g_playerStates[client].lastSwap = GetTime();

    if(!ChangeClientTeam(client, view_as<int>(want_team))) {
        LogError("failed to switch client %N to other team", client);
        return Plugin_Handled;
    }
    TF2_RespawnPlayer(client);

    LogMessage("client %N !teamswap'd to %s", client, (team == TFTeam_Blue ? "RED" : "BLUE"));
    return Plugin_Handled;
}

int GetTeamPlayerCount(TFTeam team) {
    int team_player_count = 0;

    for(int client = 1;client <= MaxClients;client++) {
        if(!IsClientConnected(client)) {
            continue;
        }

        if(!IsClientInGame(client)) {
            continue;
        }

        if(TF2_GetClientTeam(client) != team) {
            continue;
        }

        team_player_count++;
    }
    return team_player_count;
}
