#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

ConVar g_cvModelPath;
char g_sBotModel[PLATFORM_MAX_PATH];

public Plugin myinfo = 
{
    name = "Skin bots bhop",
    author = "kliganN",
    description = "Applies custom models to bots",
    version = PLUGIN_VERSION,
    url = "https://github.com/kliganN"
};

public void OnPluginStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn);
    
    RegAdminCmd("sm_setbotmodel", Command_SetBotModel, ADMFLAG_ROOT, "Set custom model for bots");
    
    g_cvModelPath = CreateConVar("sm_bot_model", "models/player/custom_player/new_model.mdl", "Path to bot model");
    g_cvModelPath.AddChangeHook(OnModelChanged);
    
    AutoExecConfig(true, "bot_models");
}

public void OnMapStart()
{
    // Прекеш модели и обновление для всех ботов
    char buffer[PLATFORM_MAX_PATH];
    g_cvModelPath.GetString(buffer, sizeof(buffer));
    
    if(strlen(buffer) > 0 && FileExists(buffer, true))
    {
        PrecacheModel(buffer);
        strcopy(g_sBotModel, sizeof(g_sBotModel), buffer);
        RequestFrame(ApplyModelToAllBots); // Применить после полной загрузки карты
    }
}

public void OnModelChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if(IsModelPrecached(newValue))
    {
        strcopy(g_sBotModel, sizeof(g_sBotModel), newValue);
        ApplyModelToAllBots();
    }
}

void ApplyModelToAllBots()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsValidClient(client) && IsFakeClient(client))
        {
            SetEntityModel(client, g_sBotModel);
        }
    }
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if(IsValidClient(client) && IsFakeClient(client))
    {
        CreateTimer(0.1, Timer_ApplyModel, GetClientUserId(client));
    }
}

public Action Timer_ApplyModel(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    
    if(IsValidClient(client) && strlen(g_sBotModel) > 0)
    {
        SetEntityModel(client, g_sBotModel);
    }
    
    return Plugin_Stop;
}

public Action Command_SetBotModel(int client, int args)
{
    if(args < 1)
    {
        ReplyToCommand(client, "Usage: sm_setbotmodel <model path>");
        return Plugin_Handled;
    }

    char model[PLATFORM_MAX_PATH];
    GetCmdArg(1, model, sizeof(model));

    if(!FileExists(model, true))
    {
        ReplyToCommand(client, "Model file %s not found!", model);
        return Plugin_Handled;
    }

    PrecacheModel(model);
    g_cvModelPath.SetString(model);
    ApplyModelToAllBots(); // Немедленно применить ко всем ботам
    ReplyToCommand(client, "Bot model changed to: %s", model);

    return Plugin_Handled;
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}
