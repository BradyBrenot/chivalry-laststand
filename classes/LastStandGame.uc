class LastStandGame extends AOCLTS;

//Always begin with Agatha, go to Mason, ...
var EAOCFaction CurrentDefendingTeam;

//How long did each team last this round?
var float RoundLastStandDurations[EAOCFaction];

//How many kills did each team get? (Only kills as defender are worth anything)
var int RoundLastStandKills[EAOCFaction];

var float LastStandDuration;

var float DefenderKillTimeBonus;

var array<CMWHUDMarker> DefenderMarkers;

//LTS ignores the "GoalScore" config variable for legacy reasons. We don't have to.
event PreBeginPlay()
{
	super(AOCGame).PreBeginPlay();

	if(bCustomEnemyMarkerSettings)
	{
		fActualShowEnemyMarkersTimeLeftSeconds = fShowEnemyMarkersTimeLeftSeconds;
		fActualShowEnemyMarkersPortionPlayersAlive = fShowEnemyMarkersPortionPlayersAlive;
	}
}

function PerformOnFirstSpawn(Controller NewPlayer)
{
	if(LastStandPlayerController(NewPlayer) != none)
	{
		LastStandPlayerController(NewPlayer).ClientOnFirstSpawn();
	}

	super(AOCGame).PerformOnFirstSpawn(NewPlayer);
}


//Change ScoreKill logic: only look for "total team death" of the Defender team
function ScoreKill( Controller Killer, Controller Other )
{
	local Controller C;
	local int NumDefendersLeft;
	
	if (Killer != Other)
		LastKiller = Killer;

	super(AOCGame).ScoreKill(Killer, Other);
	
	if(Other.PlayerReplicationInfo.Team.TeamIndex == CurrentDefendingTeam)
	{
		//Mark player as out of lives, and check to see if the Defenders are all dead
		Other.PlayerReplicationInfo.bOutOfLives = true;

		foreach WorldInfo.AllControllers(class'Controller', C)
		{
			if (AOCPRI(C.PlayerReplicationInfo).bIsVoluntarySpectator)
			{
				continue;
			}

			if ( C.PlayerReplicationInfo != None && C.PlayerReplicationInfo.Team != none && C.PlayerReplicationInfo.Team.TeamIndex == CurrentDefendingTeam && C.Pawn.IsAliveAndWell() )
			{
				++NumDefendersLeft;
			}
		}

		if(float(NumDefendersLeft) / PlayersAtLastRoundStart / 2 <= fActualShowEnemyMarkersPortionPlayersAlive && !AOCGRI(GameReplicationInfo).bShowEnemyMarkers)
		{   
			ShowMarkersOnDefenders();
		}

		if ( NumDefendersLeft == 0 )
		{
			AOCEndRound();
		}
	}
	else
	{
		//An attacker died
		++RoundLastStandKills[CurrentDefendingTeam];
		LastStandDuration += DefenderKillTimeBonus;
	}
}

//Scoring doesn't work the same any longer, and EndRound also needs to flip the teams around
function AOCEndRound()
{
	local LastStandPlayerController LSPC;
	
	RoundLastStandDurations[CurrentDefendingTeam] = LastStandDuration;
	
	foreach WorldInfo.AllControllers(class'LastStandPlayerController', LSPC)
	{
		LSPC.NotifySubRoundEnded(CurrentDefendingTeam, RoundLastStandDurations[CurrentDefendingTeam], RoundLastStandKills[CurrentDefendingTeam]);
	}
	
	if(CurrentDefendingTeam == EFAC_Mason)
	{
		//Figure out who the RoundWinner is
		if(RoundLastStandDurations[EFAC_Agatha] > RoundLastStandDurations[EFAC_Mason])
		{
			RoundWinner = Teams[0];
		}
		else if(RoundLastStandDurations[EFAC_Mason] > RoundLastStandDurations[EFAC_Agatha])
		{
			RoundWinner = Teams[1];
		}
		
		RoundsPlayed++;
	
		if(RoundWinner != none)
		{
			RoundScores[RoundWinner.TeamIndex]++;
			AOCLTSGRI(GameReplicationInfo).RoundsWon[RoundWinner.TeamIndex] = RoundScores[RoundWinner.TeamIndex];
			Teams[RoundWinner.TeamIndex].Score = RoundScores[RoundWinner.TeamIndex];
			
			foreach WorldInfo.AllControllers(class'LastStandPlayerController', LSPC)
			{
				LSPC.NotifyRoundEnded(RoundWinner.TeamIndex == 0 ? EFAC_Agatha : EFAC_Mason, RoundLastStandDurations[RoundWinner.TeamIndex], RoundLastStandKills[RoundWinner.TeamIndex]);
			}

			if( RoundWinner.TeamIndex == 0 )
			{
				BroadcastSound(AgathaWinSound);
				UpdateEvents(0);
			}
			else
			{
				BroadcastSound(MasonWinSound);
				UpdateEvents(1);
			}

			if ( RoundScores[RoundWinner.TeamIndex] == GoalScore )
			{
				MatchWinner = RoundWinner;
				if (LastKiller != none && LastKiller.PlayerReplicationInfo.Team == MatchWinner )
					EndGame( LastKiller.PlayerReplicationInfo, "TeamScoreLimit" );
				else
					EndGame( GetFirstPRIFromTeam(MatchWinner), "TeamScoreLimit" );
				return;
			}
			else if (RoundScores[RoundWinner.TeamIndex] == GoalScore - 1)
			{
				BroadcastSystemMessage(8, class'AOCSystemMessages'.static.CreateLocalizationdata("Common", RoundWinner.TeamIndex == EFAC_Agatha ? "AgathaKnights" : "MasonOrder", "AOCUI"),,EFAC_ALL);
			}
		}
		else    //how in the hell did we get a draw?
		{
			BroadcastSystemMessage(9,,,EFAC_ALL);
		}
		
		CurrentDefendingTeam = EFAC_Agatha;
	}
	else
	{
		CurrentDefendingTeam = EFAC_Mason;
	}
	
	foreach WorldInfo.AllControllers(class'LastStandPlayerController', LSPC)
	{
		LSPC.NotifyCurrentDefendingTeam(CurrentDefendingTeam);
	}
	
	GotoState( 'AOCPostRound' );
}


//Flip start locations if DefendingTeam is EFAC_Mason
function PlayerStart ChoosePlayerStart( Controller Player, optional byte InTeam )
{
	local AOCPlayerStart PS;
	local Array<AOCPlayerStart> Starts;
	local EAOCFaction MyTeam;

	if (AOCPlayerController(Player) != none)
		MyTeam = AOCPlayerController(Player).CurrentFamilyInfo.FamilyFaction;
	else
		MyTeam = EAOCFaction(Player.PlayerReplicationInfo.Team.TeamIndex);
		
	if(CurrentDefendingTeam == EFAC_Mason)
	{
		MyTeam = MyTeam == EFAC_Agatha ? EFAC_Mason : EFAC_Agatha;
	}

	foreach WorldInfo.AllNavigationPoints(class'AOCPlayerStart', PS)
	{	
		if ((PS.PlayerStartFaction ==  MyTeam  || PS.PlayerStartFaction == EFAC_ALL) && !PS.bOnlyUseAsLevelLoadCamera)
		{
			if( SpawnPointClear(PS) )
				Starts.AddItem(PS);
		}	
	}
	return Starts[ Rand(Starts.Length) ];
}

function StartRound()
{
	local Controller C;
	local CMWHUDMArker DefenderMarker;
	
	super.StartRound();
	
	LastStandGRI(WorldInfo.GRI).DefendingTeam = CurrentDefendingTeam;
	
	foreach WorldInfo.AllControllers(class'Controller', C)
	{
		AOCPlayerController(C).InitializeTimer(0, true);
		C.PlayerReplicationInfo.bOutOfLives = !AOCPlayerController(C).bReady && C.PlayerReplicationInfo.Team.TeamIndex == CurrentDefendingTeam;
	}
	
	LastStandDuration = 0.f;
	
	foreach DefenderMarkers(DefenderMarker)
	{
		DefenderMarker.Destroy();
	}
	
	DefenderMarkers.Remove(0, DefenderMarkers.Length);
}

function RequestTime(AOCPlayerController PC)
{
	PC.InitializeTimer(LastStandDuration, true);
}

function RestartPlayer(Controller NewPlayer)
{
	if (NewPlayer.PlayerReplicationInfo.Team != none && NewPlayer.PlayerReplicationInfo.Team.TeamIndex == CurrentDefendingTeam)
	{
		super(AOCLTS).RestartPlayer(NewPlayer);
	}
	else
	{
		super(AOCGame).RestartPlayer(NewPlayer);
	}
}

function ShowMarkersOnDefenders()
{
	local controller C;
	local CMWHUDMarker NewMarker;
	
	foreach WorldInfo.AllControllers(class'Controller', C)
	{
		if(C.Pawn != none && C.PlayerReplicationInfo != None && C.PlayerReplicationInfo.Team != none && C.PlayerReplicationInfo.Team.TeamIndex == CurrentDefendingTeam && C.Pawn.IsAliveAndWell())
		{
			NewMarker = Spawn(class'CMWHUDMarker');

			NewMarker.bDestroySelfIfBaseKilledOrDestroyed = true;
			NewMarker.bSetRelativeLocationFromBase = false;

			NewMarker.SetLocation(C.Pawn.Location);
			NewMarker.SetBase(C.Pawn);

			NewMarker.Enabled = true;
			NewMarker.bShowProgress = false;
			NewMarker.fMaxDistanceToShow = -1;

			NewMarker.FloatTextAgatha = "Kill";
			NewMarker.FloatTextMason = "Kill";
			NewMarker.ShowToTeam = CurrentDefendingTeam == EFAC_Agatha ? EFAC_Mason : EFAC_Agatha;
			NewMarker.bUseTextAsLocalizationKey = true;
			NewMarker.SectionName = "HudMarker";
			NewMarker.PackageName = "AOCMaps";
			NewMarker.AgathaImagePath = "img://UI_HUD_SWF.icon_kill_png";
			NewMarker.MasonImagePath = "img://UI_HUD_SWF.icon_kill_png";
			
			DefenderMarkers.AddItem(NewMarker);
		}
	}
}

static event class<GameInfo> SetGameType(string MapName, string Options, string Portal)
{
	return default.class;
}

auto State AOCPreRound
{
	function BeginState( Name PreviousStateName )
	{
		local Controller PC;

		TimeToNextRound = GetTimeBetweenRounds();
		foreach WorldInfo.AllControllers(class'Controller', PC)
		{
			if (AOCPlayerController(PC) != none)
			{
				if (AOCPlayerController(PC).bReady || PC.PlayerReplicationInfo.Team.TeamIndex != CurrentDefendingTeam)
				{
					PC.PlayerReplicationInfo.bOutOfLives = false;
				}
				else if(PC.PlayerReplicationInfo.Team.TeamIndex == CurrentDefendingTeam)
				{
					PC.PlayerReplicationInfo.bOutOfLives = true;
				}
			}
			else if (AOCAICombatController(PC) != none)
			{
				PC.PlayerReplicationInfo.bOutOfLives = false;
			}
		}
	}
}

State AOCRoundInProgress
{
	function Tick (float DeltaTime)
	{
		local AOCPlayerController PC;

		super(AOCGame).Tick( DeltaTime );
		
		LastStandDuration += DeltaTime;
		
		TimeLeft = 99;

		// Kill ONLY DEFENDING players that are AFK
		if (WorldInfo.NetMode == NM_DedicatedServer && Worldinfo.TimeSeconds - GameStartTime > IdleTimeLimit)
		{
			foreach WorldInfo.AllControllers(class'AOCPlayerController', PC)
			{
				if (PC.PlayerReplicationInfo.Team.TeamIndex == CurrentDefendingTeam
					&& PC.Pawn.Health > 0.0f
					&& Worldinfo.TimeSeconds - PC.LastActiveTime > IdleTimeLimit)
				{
					LocalizedPrivateMessage(PC, 32,,,true, "#FF4040");
					PC.S_DoF10();
				}
			}
		}
	}

	function SpawnReadyPlayers()
	{
		local QueueInfo PC;
		local int Index;
		local array<QueueInfo> SpawnQueueToRemove;

		if (SpawnQueueReady.Length > 0)
		{
			// After 15 seconds, defenders can no longer spawn
			if (WorldInfo.TimeSeconds - GameStartTime > 15.0f)
			{
				foreach SpawnQueueReady(PC,Index)
				{
					if(PC.C.PlayerReplicationInfo.Team.TeamIndex == CurrentDefendingTeam)
					{
						// Mark them as dead in scoreboard
						AOCPRI(PC.C.PlayerReplicationInfo).CurrentHealth = 0.0f;
						SpawnQueueToRemove.AddItem(PC);
					}
				}
				foreach SpawnQueueToRemove(PC,Index)
				{
					SpawnQueueReady.RemoveItem(PC);
				}
			}
		}

		super(AOCGame).SpawnReadyPlayers();
	}

	function PerformOnSpawn(Controller C)
	{
		C.PlayerReplicationinfo.bOutOfLives = false;
	}

	function bool PlayerCanRestart( PlayerController aPlayer )
	{
		return aPlayer.PlayerReplicationInfo.Team.TeamIndex != CurrentDefendingTeam;
	}

	function bool AddPlayerToQueue( controller PC, optional bool bSpawnNextTime = false )
	{
		if(PC.PlayerReplicationInfo.Team.TeamIndex != CurrentDefendingTeam)
		{
			return super(AOCGame).AddPlayerToQueue(PC, bSpawnNextTime);
		}
		else
		{
			return false;
		}
	}

	function NotifyKilled(Controller Killer, Controller Killed, Pawn KilledPawn, class<DamageType> damageType )
	{
		global.NotifyKilled(Killer, Killed, KilledPawn, damageType);
		if(Killed.PlayerReplicationInfo.Team.TeamIndex == CurrentDefendingTeam)
		{
			Killed.PlayerReplicationInfo.bOutOfLives = true;
		}
	}
}

DefaultProperties
{
	DefaultAIControllerClass=class'LastStandAICombatController'
    PlayerControllerClass=class'LastStandPlayerController'
    DefaultPawnClass=class'LastStandPawn'
	PlayerReplicationInfoClass=class'LastStandPRI'
	GameReplicationInfoClass=class'LastStandGRI'
	
	CurrentDefendingTeam = EFAC_Agatha
	DefenderKillTimeBonus = 1.f
	ModDisplayString="Last Stand"
	ModeDisplayString="Last Stand"
}