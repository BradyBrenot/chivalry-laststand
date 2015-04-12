class LastStandPlayerController extends AOCLTSPlayerController;

var EAOCFaction DefendingTeam;
	
reliable client function ClientOnFirstSpawn()
{
	//ReceiveChatMessage("",Localize("LastStand", "WelcomeChatText", "LastStand"),EFAC_ALL,false,false,,false);
	ReceiveChatMessage("","Last Stand: One team has infinite respawns, the other spawns only once. Teams switch after the defenders are wiped out. The defending team gets points for kills, and gets more points as they score more kills and as they last longer. The team who reaches the goal first wins! (Mason still has a chance to win if Agatha reaches the goal first)",EFAC_ALL,false,false,,false);
}

function NotifyCurrentDefendingTeam(EAOCFaction Defenders)
{
	DefendingTeam = Defenders;
	ClientNotifyCurrentDefendingTeam(Defenders);
}

//RPC because replication order matters: we need this to hit before ShowDefaultGameHeader does, otherwise the wrong header will show
reliable client function ClientNotifyCurrentDefendingTeam(EAOCFaction Defenders)
{
	DefendingTeam = Defenders;
}


reliable client function NotifySubRoundEnded(EAOCFaction Defenders, float TimeLasted, int Kills)
{
	/*ReceiveChatMessage("",
		Repl(
			Repl(
				Repl(Localize("LastStand", "SubRoundEnded", "LastStand"), "{TIMELASTED}", TimeLasted),
				"{KILLS}", Kills),
			"{FACTION}", Localize("Common", Defenders == EFAC_Agatha ? "AgathaKnights" : "MasonOrder", "AOCUI"))
		,EFAC_ALL,false,false,,false);*/
		
	ReceiveChatMessage("",
		Repl(
			Repl(
				Repl("{FACTION} eliminated. They lasted {TIMELASTED} seconds, getting {KILLS} kills in the process.", "{TIMELASTED}", Round(TimeLasted)),
				"{KILLS}", Kills),
			"{FACTION}", Localize("Common", Defenders == EFAC_Agatha ? "AgathaKnights" : "MasonOrder", "AOCUI"))
		,EFAC_ALL,false,false,,false);
}

reliable client function NotifyRoundEnded()
{
}

function TickGameTimer()
{
	//Timer goes UP
	CurrentMemTimer += 1;
	AOCBaseHUD(myHUD).DisplayMatchTime(CurrentMemTimer, true);
	
	if(bIsWarmupFrozen)
	{
		UpdateWarmupCounter();
	}
}
	
reliable client function ShowDefaultGameHeader()
{
	if (AOCGRI(Worldinfo.GRI) == none)
	{
		SetTimer(0.1f, false, 'ShowDefaultGameHeader');
		return;
	}	

	/*
	if(PlayerReplicationInfo.Team.TeamIndex == DefendingTeam)
	{
		ClientShowLocalizedHeaderText(Localize("LastStand","SpawnHeader","LastStand"),,Localize("LastStand","SpawnSubHeaderDefender","LastStand"),true,true);
	}
	else
	{
		ClientShowLocalizedHeaderText(Localize("LastStand","SpawnHeader","LastStand"),,Localize("LastStand","SpawnSubHeaderAttacker","LastStand"),true,true);
	}*/
	
	if(PlayerReplicationInfo.Team.TeamIndex == DefendingTeam)
	{
		ClientShowLocalizedHeaderText("Last Stand",,"Survive as long as possible! You will not respawn!",true,true);
	}
	else
	{
		ClientShowLocalizedHeaderText("Last Stand",,"Elminate the enemy team as quickly as possible!",true,true);
	}
}

function PawnDied(Pawn P)
{
	//Use LTS' logic if we're defenders, else use normal logic
	if(PlayerReplicationInfo.Team.TeamIndex == DefendingTeam)
	{
		super(AOCLTSPlayerController).PawnDied(P);
	}
	else
	{
		super(AOCPlayerController).PawnDied(P);
	}
}

function Reset()
{
	if(PlayerReplicationInfo.Team.TeamIndex == DefendingTeam)
	{
		super(AOCLTSPlayerController).Reset();
	}
	else
	{
		super(AOCPlayerController).Reset();
	}
}

function HandleSpawnTimer()
{	
	if(PlayerReplicationInfo.Team.TeamIndex == DefendingTeam)
	{
		super(AOCLTSPlayerController).HandleSpawnTimer();
	}
	else
	{
		super(AOCPlayerController).HandleSpawnTimer();
	}
}

reliable client function ClientPossessedPawn(EAOCFaction Fact, bool bRespawnDuringGame)
{
	super.ClientPossessedPawn(Fact, bRespawnDuringGame);

	LastStandHUD(MyHud).OnRepDefendingTeam();
}

reliable client function NotifyAgathaCanWin()
{
	ReceiveChatMessage("", "Agatha has more than"@Worldinfo.GRI.GoalScore@"points! They will win if Mason can't match or beat their score this round!",EFAC_ALL,false,false,,false);
}

exec function SpectatorNext()
{
	LastStandHUD(MyHud).HideHelp();
}

exec function ForwardSpawn()
{
	super.ForwardSpawn();
	LastStandHUD(MyHud).ShowHelp();
}

state Spectating
{
	exec function SpectatorNext()
	{
		super.SpectatorNext();
		LastStandHUD(MyHud).HideHelp();
	}
}