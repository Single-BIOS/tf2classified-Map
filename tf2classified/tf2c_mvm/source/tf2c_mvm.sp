// TO Fix
// 1. Setup time after the wave begins ✔️
// 2. Robots Invulnerability  ✔️
// 3. Jarate & Mad Milk don't work ✔️
// 4. After the wave fails there is no prepare time  ✔️
// 5. Refund button crashes the game
// 6. Round restart bugs after the wave is failed ✔️
// 6. Forced round restart after all the players press f4 with further upgrades & buildings reset
// 7. The buildings for an engineer cost $0 and upgraded instantly up to lvl3 after the wave begins. 
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>


#define PLUGIN_VERSION "0.2.5.1"

ConVar g_hConVarTFFastBuild;

Handle g_enableRefunds = null;

StringMap robotsJarateMap = null;
StringMap robotsMadMilkMap = null;

float g_PlayerPositions[MAXPLAYERS+1][3];
float g_PlayerAngles[MAXPLAYERS+1][3];

bool flagsSet = false;
int oldFlags = -1;


public Plugin myinfo =
{
	name = "[TF2C] Mann vs Machine: Game Mode Fix",
	author = "Glaster",
	description = "Makes Mann vs Machine game mode playable again",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	g_enableRefunds = FindConVar("tf_mvm_respec_enabled");
	if (g_enableRefunds != INVALID_HANDLE) {
		SetConVarInt(g_enableRefunds, 0);
	}

	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("teamplay_restart_round", Event_RoundRestart, EventHookMode_Pre);
	HookEvent("teamplay_broadcast_audio", Ev_Game_PlayBroadcastAudio, EventHookMode_Post);
	HookEvent("player_chargedeployed", Event_OnUbercharge, EventHookMode_Pre);

	g_hConVarTFFastBuild = FindConVar("tf_fastbuild");
	g_hConVarTFFastBuild.BoolValue = false;

	robotsJarateMap = new StringMap();
	robotsMadMilkMap = new StringMap();
}




public void OnMapStart()
{
	if (!IsMvMActive()) {
		SetFailState("Not a MvM map. Disabling...");
	} else {
		CreateEntityByName("info_populator");
		DispatchSpawn(CreateEntityByName("func_upgradestation"));
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (IsMvMRobot(victim)) {
		StripStuckRobotInvulnerability(victim);
	}
	return Plugin_Continue;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (condition == TFCond_Ubercharged || condition == TFCond_UberchargedHidden || condition == TFCond_UberchargedCanteen || condition == TFCond_UberchargedOnTakeDamage)
	{
		if (IsMvMRobot(client)) {
			StripStuckRobotInvulnerability(client);
		}
	}

	if (IsMvMRobot(client)) {
		char sKey[16];
		IntToString(client, sKey, sizeof(sKey));
		StripStuckRobotInvulnerability(client);

		if (condition == TFCond_Jarated) {
			if (!robotsJarateMap.ContainsKey(sKey)) {
				float JarExpirationTime = GetGameTime() + 10.0;
				robotsJarateMap.SetValue(sKey, JarExpirationTime);
			}
		}
		if (condition == TFCond_Milked) {
			if (!robotsMadMilkMap.ContainsKey(sKey)) {
				float milkExpirationTime = GetGameTime() + 10.0;
				robotsMadMilkMap.SetValue(sKey, milkExpirationTime);
			}
		}
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if (IsMvMRobot(client)) {
		char sKey[16];
		IntToString(client, sKey, sizeof(sKey));

		if (condition == TFCond_Jarated) {
			if (!IsPlayerAlive(client)) {
				robotsJarateMap.Remove(sKey);
			} else {
				float expirationTime = 0.0;
				robotsJarateMap.GetValue(sKey, expirationTime);
				if (GetGameTime() > expirationTime) {
					robotsJarateMap.Remove(sKey);
				} else {
					TF2_AddCondition(client, TFCond_Jarated, expirationTime - GetGameTime());
				}
			}
		}
		if (condition == TFCond_Milked) {
			if (!IsPlayerAlive(client)) {
				robotsMadMilkMap.Remove(sKey);
			} else {
				float expirationTime = 0.0;
				robotsMadMilkMap.GetValue(sKey, expirationTime);
				if (GetGameTime() > expirationTime) {
					robotsMadMilkMap.Remove(sKey);
				} else {
					TF2_AddCondition(client, TFCond_Milked, expirationTime - GetGameTime());
				}
			}
		}
	}
}


bool IsMvMActive()
{
	static char map_name[PLATFORM_MAX_PATH];
	GetCurrentMap(map_name, sizeof(map_name));

	if (StrContains(map_name, "mvm_", false) == 0) {
		return true;
	}

	return FindEntityByClassname(-1, "tf_logic_mann_vs_machine") != -1;
}

bool IsMvMRobot(int client)
{
	if (!IsMvMActive()) {
		return false;
	}

	if (client <= 0 || client > MaxClients || !IsClientInGame(client)) {
		return false;
	}

	if (!IsFakeClient(client) || IsClientSourceTV(client) || IsClientReplay(client)) {
		return false;
	}

	return GetClientTeam(client) == view_as<int>(TFTeam_Blue);
}


void StripStuckRobotInvulnerability(int client)
{
	if (TF2_IsPlayerInCondition(client, TFCond_Ubercharged)) {
		TF2_RemoveCondition(client, TFCond_Ubercharged);
	}

	if (TF2_IsPlayerInCondition(client, TFCond_UberchargeFading)) {
		TF2_RemoveCondition(client, TFCond_UberchargeFading);
	}

	if (TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden)) {
		TF2_RemoveCondition(client, TFCond_UberchargedHidden);
	}

	if (TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen)) {
		TF2_RemoveCondition(client, TFCond_UberchargedCanteen);
	}

	if (TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage)) {
		TF2_RemoveCondition(client, TFCond_UberchargedOnTakeDamage);
	}

	if (GetEntProp(client, Prop_Data, "m_takedamage") != 2) {
		SetEntProp(client, Prop_Data, "m_takedamage", 2);
	}
}


public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	int entityTimer = FindEntityByClassname(-1, "team_round_timer");
	if (entityTimer > -1)
	{
		SetVariantInt(StringToInt("1"));
		AcceptEntityInput(entityTimer, "SetTime");
	}
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	char sKey[16];
	IntToString(client, sKey, sizeof(sKey));
	if (IsMvMRobot(client)) {
		if (robotsJarateMap.ContainsKey(sKey)) {
			robotsJarateMap.Remove(sKey);
		}
		if (robotsMadMilkMap.ContainsKey(sKey)) {
			robotsMadMilkMap.Remove(sKey);
		}
	}
}

public Action Event_RoundRestart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, g_PlayerPositions[i]);
			GetClientEyeAngles(i, g_PlayerAngles[i]);
			CreateTimer(0.1, Timer_RestoreProgress, i);
		}
	}
}

public Action Ev_Game_PlayBroadcastAudio(Event event, const char[] name, bool dontBroadcast)
{
	char soundBroadcasted[128];
	event.GetString("sound", soundBroadcasted, sizeof(soundBroadcasted));
	char soundExpected[128] = "music.mvm_lost_wave";
	if (StrEqual(soundBroadcasted, soundExpected)) {
		JumpToWave(GetEntProp(FindEntityByClassname(-1, "tf_objective_resource"), Prop_Send, "m_nMannVsMachineWaveCount"));
	}
}

public Action Event_OnUbercharge(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsMvMRobot(client)) {
		StripStuckRobotInvulnerability(client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Timer_RestoreProgress(Handle timer, int client)
{
	g_hConVarTFFastBuild.BoolValue = false;
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client)) {
			TeleportEntity(client, g_PlayerPositions[client], g_PlayerAngles[client], NULL_VECTOR);
		}
	}
}

public void JumpToWave(int wave_number)
{
	if (!flagsSet) {
		oldFlags = GetCommandFlags("tf_mvm_jump_to_wave");
		SetCommandFlags("tf_mvm_jump_to_wave", oldFlags & ~FCVAR_CHEAT);
		flagsSet = true;
	}
	ServerCommand("tf_mvm_jump_to_wave %d", wave_number);
}
