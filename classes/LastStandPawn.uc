class LastStandPawn extends AOCPawn;

simulated function AOCSetCharacterClassFromInfo(AOCFamilyInfo Info)
{
	super.AOCSetCharacterClassFromInfo(Info);

	if(Role == ROLE_Authority && Info.FamilyFaction == LastStandGRI(Worldinfo.GRI).DefendingTeam)
	{
		HealthMax *= 2.3;
		Health *= 2.3;
	}
}