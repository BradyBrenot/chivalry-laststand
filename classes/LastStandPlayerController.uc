class LastStandPlayerController extends AOCLTSPlayerController;

var EAOCFaction DefendingTeam;
	
reliable client function ClientOnFirstSpawn()
{
	ReceiveChatMessage("",Localize("LastStand", "WelcomeChatText", "LastStand"),EFAC_ALL,false,false,,false);
}

//RPC because replication order matters: we need this to hit before ShowDefaultGameHeader does, otherwise the wrong header will show
reliable client function NotifyCurrentDefendingTeam(EAOCFaction Defenders)
{
	DefendingTeam = Defenders;
}

reliable client function NotifySubRoundEnded(EAOCFaction Defenders, float TimeLasted, int Kills)
{
	ReceiveChatMessage("",
		Repl(
			Repl(
				Repl(Localize("LastStand", "SubRoundEnded", "LastStand"), "{TIMELASTED}", TimeLasted),
				"{KILLS}", Kills),
			"{FACTION}", Localize("Common", Defenders == EFAC_Agatha ? "AgathaKnights" : "MasonOrder", "AOCUI"))
		,EFAC_ALL,false,false,,false);
}

reliable client function NotifyRoundEnded(EAOCFaction WinningFaction, float TimeLasted, int Kills)
{
	ReceiveChatMessage("",
		Repl(
			Repl(
				Repl(Localize("LastStand", "RoundEnded", "LastStand"), "{TIMELASTED}", TimeLasted),
				"{KILLS}", Kills),
			"{FACTION}", Localize("Common", WinningFaction == EFAC_Agatha ? "AgathaKnights" : "MasonOrder", "AOCUI"))
		,EFAC_ALL,false,false,,false);
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

	if(PlayerReplicationInfo.Team.TeamIndex == DefendingTeam)
	{
		ClientShowLocalizedHeaderText(Localize("LastStand","SpawnHeader","LastStand"),,Localize("LastStand","SpawnSubHeaderDefender","LastStand"),true,true);
	}
	else
	{
		ClientShowLocalizedHeaderText(Localize("LastStand","SpawnHeader","LastStand"),,Localize("LastStand","SpawnSubHeaderAttacker","LastStand"),true,true);
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
