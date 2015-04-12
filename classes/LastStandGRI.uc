class LastStandGRI extends AOCLTSGRI;
	
var repnotify EAOCFaction DefendingTeam;
var repnotify bool bShowDefenderHudMarkers;

var repnotify float MultiplierProgress;
var repnotify float SecondsUntilMultiplierIncrease;
var repnotify int CurrentMultiplier;

var LastStandHUD Hud;

replication
{
	if ( bNetDirty || bNetInitial )
		DefendingTeam, bShowDefenderHudMarkers, SecondsUntilMultiplierIncrease, CurrentMultiplier,MultiplierProgress;
}

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	Hud = LastStandHUD(GetALocalPlayerController().myHUD);
	if(Hud != none)
	{
		ReplicatedEvent('DefendingTeam');
		ReplicatedEvent('SecondsUntilMultiplierIncrease');
		ReplicatedEvent('CurrentMultiplier');
		ReplicatedEvent('MultiplierProgress');
	}
}

simulated event ReplicatedEvent(name VarName)
{
	super.ReplicatedEvent(VarName);

	if (VarName == 'bShowDefenderHudMarkers')
	{
		if(Role != ROLE_Authority)
		{
			//hack to only show HUD markers on defenders
			bShowEnemyMarkers = bShowDefenderHudMarkers && LastStandPlayerController(GetALocalPlayerController()).DefendingTeam != LastStandPlayerController(GetALocalPlayerController()).PlayerReplicationInfo.Team.TeamIndex;
		}
	}
	
	if(Hud == none)
	{
		return;
	}

	if(VarName == 'DefendingTeam')
	{
		Hud.OnRepDefendingTeam();
	}
	else if(VarName == 'SecondsUntilMultiplierIncrease')
	{
		Hud.OnRepSecondsUntilMultiplierIncrease();
	}
	else if(VarName == 'CurrentMultiplier')
	{
		Hud.OnRepCurrentMultiplier();
	}
	else if(VarName == 'MultiplierProgress')
	{
		Hud.OnRepMultiplierProgress();
	}
}

simulated function string RetrieveObjectiveTitle(EAOCFaction Faction)
{
	//return Localize("LastStand", "ObjectiveName" ,"LastStand");
	return "Last Stand";
}

simulated function string RetrieveObjectiveDescription(EAOCFaction Faction)
{
	//return Localize("LastStand", Faction == DefendingTeam ? "ObjectiveDescriptionDefenders" : "ObjectiveDescriptionAttackers", "LastStand");
	return Faction == DefendingTeam ? "Survive!" : "Eliminate the other team!";
}

simulated function string RetrieveObjectiveStatusText(EAOCFaction Faction)
{
	local int NumDefenders;
	local PlayerReplicationInfo TempPRI;
	
	foreach AOCBaseHUD(AOCPlayerController(GetALocalPlayerController()).myHUD).AllPRI(TempPRI)
	{
		if(AOCPRI(TempPRI).CurrentHealth > 0 && AOCPRI(TempPRI).GetCurrentTeam() == DefendingTeam)
		{
			++NumDefenders;
		}
	}

	//return Repl(Localize("LastStand", "StatusText" ,"LastStand"), "{NUMDEFENDERS}", NumDefenders);
	return Repl("{NUMDEFENDERS} defenders left", "{NUMDEFENDERS}", NumDefenders);
}

defaultproperties
{
	SecondsUntilMultiplierIncrease = 30
}