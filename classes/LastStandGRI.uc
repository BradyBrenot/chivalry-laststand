class LastStandGRI extends AOCLTSGRI;
	
var EAOCFaction DefendingTeam;

replication
{
	if ( bNetDirty )
		DefendingTeam;
}

simulated function string RetrieveObjectiveTitle(EAOCFaction Faction)
{
	return Localize("LastStand", "ObjectiveName" ,"LastStand");
}

simulated function string RetrieveObjectiveDescription(EAOCFaction Faction)
{
	return Localize("LastStand", Faction == DefendingTeam ? "ObjectiveDescriptionDefenders" : "ObjectiveDescriptionAttackers", "LastStand");
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

	return Repl(Localize("LastStand", "StatusText" ,"LastStand"), "{NUMDEFENDERS}", NumDefenders);
}