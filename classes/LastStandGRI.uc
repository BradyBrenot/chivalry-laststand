class LastStandGRI extends AOCLTSGRI;
	
var EAOCFaction DefendingTeam;
var repnotify bool bShowDefenderHudMarkers;

replication
{
	if ( bNetDirty )
		DefendingTeam, bShowDefenderHudMarkers;
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