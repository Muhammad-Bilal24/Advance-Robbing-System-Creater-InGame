//==============================includes ======================================//
#include <a_samp>
#include <foreach>
#include <zcmd>
#include <sscanf2>
#include <YSI\y_ini>
#include <streamer>
//================================Define ======================================//
#define SCM 	 			SendClientMessage
#define SCMToAll 			SendClientMessageToAll
#define MAX_ROBABLE_SHOPS 	100
//================================Color ======================================//
#define 	COLOR_YELLOW	0xFFFF00AA
#define     COLOR_GREEN     0x33AA33AA
//==============================Varaibles=====================================//
new CP[MAX_ROBABLE_SHOPS]; 
new IsPlaceRobbedAlready[MAX_ROBABLE_SHOPS];
new Captured[MAX_PLAYERS][MAX_ROBABLE_SHOPS];
new PlayerWasInShop[MAX_PLAYERS][MAX_ROBABLE_SHOPS];
new	TIMER[MAX_PLAYERS][MAX_ROBABLE_SHOPS];
new	RobbingTimer[MAX_PLAYERS];
new CountDown[MAX_PLAYERS];
new RandomCash[] = {1000,700,1200,1300,500};
new RobPlaceAvailableTimer[MAX_ROBABLE_SHOPS];
new Rstr[128];
new ID;
new ShopActor[MAX_ROBABLE_SHOPS];

enum Shops
{
	Float:ShopX,
	Float:ShopY,
	Float:ShopZ,
	Float:ShopA,
	ShopInt,
	ShopVw,
	ShopName[30]
};
new sInfo[MAX_ROBABLE_SHOPS][Shops];

//CreateDynamicCP(Float:x, Float:y, Float:z, Float:size, worldid = -1, interiorid = -1, playerid = -1,Float:distance = 100.0);

#if defined FILTERSCRIPT

public OnFilterScriptInit()
{
	for(new i  = 0 ; i < MAX_ROBABLE_SHOPS; i++)
	{
		new gFile[35];
		format(gFile, 35, "RobSystem/%d.ini" ,i);
		if(fexist(gFile))
		{
		INI_ParseFile(gFile, "LoadShops", .bExtra = true, .extra = i);
		CP[i] = CreateDynamicCP(sInfo[i][ShopX],sInfo[i][ShopY],sInfo[i][ShopZ], 3.0, -1, sInfo[i][ShopInt], -1, 100.0);
		ShopActor[i] = CreateActor(275,sInfo[i][ShopX],sInfo[i][ShopY],sInfo[i][ShopZ],sInfo[i][ShopA]+180);
		}
	}
	print("\n--------------------------------------");
	print(" FILTERSCRIPT ROB SYSTEM LOADED			");
	print(" CREATED BY MUHAMMAD BILAL				");
	print("--------------------------------------\n");
	return 1;
}

public OnFilterScriptExit()
{
	for(new i  = 0 ; i < MAX_ROBABLE_SHOPS; i++)
	{
	    IsPlaceRobbedAlready[i] = 0 ;
		DestroyActor(ShopActor[i]);
	}
	print("\n--------------------------------------");
	print(" FILTERSCRIPT ROB SYSTEM UNLOADED		");
	print(" CREATED BY MUHAMMAD BILAL				");
	print("--------------------------------------\n");
	return 1;
}

#else

main()
{
	print("\n----------------------------------");
	print(" FILTERSCRIPT RACE SYSTEM LOADED		");
	print(" CREATED BY MUHAMMAD BILAL			");
	print("----------------------------------\n");
}

#endif

GetName(playerid)
{
	new Name[MAX_PLAYER_NAME];
	GetPlayerName(playerid,Name,MAX_PLAYER_NAME);
	return Name;
}

forward OnPlayerEnterDynamicCP(playerid, checkpointid);
public OnPlayerEnterDynamicCP(playerid, checkpointid)
{
	for (new i = 0; i < MAX_ROBABLE_SHOPS ; i++ )
	{
		if(checkpointid == CP[i])
	    {
		    if(GetPlayerState(playerid)  != 9)
		    {
		        if(GetPlayerWeapon(playerid) != 0)
		        {
		            if(IsPlaceRobbedAlready[i] != 1)
		            {
		                CheckPlayerShop(playerid,i);
		                break;
		            }
					else
					{
						GameTextForPlayer( playerid, "~r~This shop is not available~n~to Rob at this moment", 3000, 5 );
						break;
					}
				}
				else
				{
					GameTextForPlayer( playerid, "~r~You're not allowed to rob~n~You have no weapon to aim at ~n~security guard.", 3000, 5 );//here i'm sending message if that player is robbed already than show him that message only.
					break;
				}
			}
			else
			{
				GameTextForPlayer( playerid, "~r~You're not allowed to rob when you're spectating.", 3000, 5 );
				break;
			}
	    }
	}
    return 1;
}

CheckPlayerShop(playerid,ShopID)
{
    ApplyActorAnimation(ShopActor[ShopID], "ped","handsup",4.1,0,1,1,1,0);
	IsPlaceRobbedAlready[ShopID] = 1;
	ApplyAnimation(playerid, "SHOP", "ROB_Loop_Threat", 4.0, 1, 0, 0, 0, 0);
	PlayerWasInShop[playerid][ShopID] = 1;
	Captured[playerid][ShopID] = 0;
	CountDown[playerid] = 25;
	TIMER[playerid][ShopID] 	= SetTimerEx("OnPlayerStartRobbingShop",25000, false,"di",playerid,ShopID);
	RobbingTimer[playerid] 		= SetTimerEx("OnPlayerRobCountDown", 1000, true,"d",playerid);
	SCM(playerid,COLOR_YELLOW,"-|stay in this checkpoint for 25 seconds to rob this place.|-");
	return 1;
}

forward OnPlayerRobCountDown(playerid);
public OnPlayerRobCountDown(playerid)
{
	for (new i = 0; i < MAX_ROBABLE_SHOPS ; i++ )
	{
		if(IsPlayerInDynamicCP(playerid, CP[i]) && IsPlaceRobbedAlready[i] == 1 && GetPlayerState(playerid)  != 9 )
		{
	 			OnPlayerRobTimeLeft(playerid);
				break;
		}
	}
    return 1;
}

OnPlayerRobTimeLeft(playerid)
{
		switch(CountDown[playerid])
		{
			case 1..25:
			{
			format(Rstr, sizeof(Rstr),"~y~To Complete~n~~r~Robbing ~n~~y~Time Left ~n~~b~%d",CountDown[playerid]);
			GameTextForPlayer(playerid,Rstr,1000,3);
			PlayerPlaySound(playerid, 4203, 0.0, 0.0, 0.0);
			}
	  	}
  		CountDown[playerid]--;
 		return 1;
}

forward OnPlayerStartRobbingShop(playerid,ShopID);
public OnPlayerStartRobbingShop(playerid,ShopID)
{
    ClearAnimations(playerid);
	ClearActorAnimations(ShopActor[ShopID]);
    KillTimer(TIMER[playerid][ShopID]);
	KillTimer(RobbingTimer[playerid]);
    Captured[playerid][ShopID] = 1;
    SetPlayerScore(playerid, GetPlayerScore(playerid) + 2);
    new Money = RandomCash[random(5)];
    GivePlayerMoney(playerid, Money);
    PlayerPlaySound(playerid,17802,0.0,0.0,0.0);
    format(Rstr,sizeof(Rstr),"-| %s has Robbed %d $ from %s |-",GetName(playerid),Money,sInfo[ShopID][ShopName]);
    SCMToAll(COLOR_GREEN,Rstr);
	IsPlaceRobbedAlready[ShopID] = 1;
	PlayerWasInShop[playerid][ShopID] = 0;
 	RobPlaceAvailableTimer[ShopID] = SetTimerEx("PlaceAlreadyRobbed", 25*60*1000, 0 ,"i",ShopID);
    return 1;
}

forward PlaceAlreadyRobbed(ShopID);
public PlaceAlreadyRobbed(ShopID)
{
	KillTimer(RobPlaceAvailableTimer[ShopID]);
	IsPlaceRobbedAlready[ShopID] = 0;
}

forward OnPlayerLeaveDynamicCP(playerid, checkpointid);
public OnPlayerLeaveDynamicCP(playerid, checkpointid)
{
	for (new i = 0; i < MAX_ROBABLE_SHOPS ; i++ )
	{
	    if(checkpointid == CP[i] && Captured[playerid][i] == 0 && !IsPlayerInDynamicCP(playerid, CP[i] && PlayerWasInShop[playerid][i] == 1))
	    {
	        FailToRob(playerid,i);
	        break;
	    }
    }
}

FailToRob(playerid,ShopID)
{
	ClearAnimations(playerid);
	ClearActorAnimations(ShopActor[ShopID]);
    KillTimer(RobbingTimer[playerid]);
    KillTimer(TIMER[playerid][ShopID]);
    Captured[playerid][ShopID] = 0;
    IsPlaceRobbedAlready[ShopID] = 0;
    PlayerWasInShop[playerid][ShopID] = 0;
    format(Rstr, sizeof(Rstr),"~r~You are failed to rob ~b~~n~%s", sInfo[ShopID][ShopName]);
	GameTextForPlayer( playerid, Rstr, 5000, 3 );
	return 1;
}

OnPlayerLeaveShop(playerid)
{
	for (new i = 0; i < MAX_ROBABLE_SHOPS ; i++ )
	{
	    if(Captured[playerid][i] == 0 && PlayerWasInShop[playerid][i] == 1 && IsPlaceRobbedAlready[i] == 1)
	    {
	        FailToRob(playerid , i);
	        break;
	    }
	}
	return 1;
}

public OnPlayerDisconnect(playerid,reason)
{
	OnPlayerLeaveShop(playerid);
	return 1;
}

public OnPlayerConnect(playerid)
{
	OnPlayerLeaveShop(playerid);
	return 1;
}

public OnPlayerSpawn(playerid)
{
	OnPlayerLeaveShop(playerid);
	return 1;
}

CMD:cancelrob(playerid)return OnPlayerLeaveShop(playerid);

CMD:crobcp(playerid,params[])
{
	new string[30];
	if(!IsPlayerAdmin(playerid))return SCM(playerid,COLOR_GREEN,"[MB-RACE SYSTEM]: You need to be rcon admin to use this cmd.");
	if(sscanf(params,"s[30]",string))return SCM(playerid,COLOR_YELLOW,"/crobcp [Shop Name]");
 	new Float:CpPos[4],Int,Vw,dFile[32];
	GetPlayerPos(playerid,CpPos[0],CpPos[1],CpPos[2]);
	GetPlayerFacingAngle(playerid,CpPos[3]);
	Int = GetPlayerInterior(playerid);
	Vw = GetPlayerVirtualWorld(playerid);
	format(dFile, 35, "RobSystem/%d.ini", ID);
	new INI:File = INI_Open(dFile);
 	INI_SetTag(File,"Shop");
	INI_WriteFloat(File,"CpX",CpPos[0]);
	INI_WriteFloat(File,"CpY",CpPos[1]);
	INI_WriteFloat(File,"CpZ",CpPos[2]);
	INI_WriteFloat(File,"CpA",CpPos[3]);
	INI_WriteInt(File,"CpInt",Int);
	INI_WriteInt(File,"CpVw",Vw);
	INI_WriteInt(File,"CpID",ID);
	INI_WriteString(File,"CpName",string);
	INI_Close(File);
	SCM(playerid,COLOR_YELLOW,"You have successfully saved the position of the rob point.");
	CP[ID] = CreateDynamicCP(CpPos[0],CpPos[1],CpPos[2], 3.0, -1, Int, -1, 100.0);
 	ShopActor[ID] = CreateActor(275,CpPos[0],CpPos[1],CpPos[2],CpPos[3]+180);
 	SetPlayerPos(playerid,CpPos[0],CpPos[1]+2,CpPos[2]);
 	sInfo[ID][ShopName] = string;
	ID++;
	return 1;
}

forward LoadShops(id, name[], value[]);
public LoadShops(id, name[], value[])
{
	INI_Float("CpX", sInfo[id][ShopX]);
	INI_Float("CpY", sInfo[id][ShopY]);
	INI_Float("CpZ", sInfo[id][ShopZ]);
	INI_Float("CpA", sInfo[id][ShopA]);
	INI_Int("CpInt", sInfo[id][ShopInt]);
	INI_Int("CpVw", sInfo[id][ShopVw]);
	INI_Int("CpID", ID);
	INI_String("CpName",sInfo[id][ShopName],30);
    return 1;
}

CMD:giveweapon(playerid)
{
	GivePlayerWeapon(playerid,31,100000);
	return 1;
}
