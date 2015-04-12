//Custom HUD for Last Stand. Adds the multiplier / current team / survivors remaining elements

class LastStandHUD extends AOCBaseHUD;

var SwfMovie SwfToLoad;

var AOCGFxTweenableMoviePlayer	MoviePlayer;
var GFxObject					MovieRoot;
var GFxObject					HudWidget;
var GFxObject					DescriptionMovieClip;
var bool						bHelpShowing;

exec function ShowHUD(optional bool bShowOverlay = true)
{
	local LastStandGRI LSGRI;

	super.ShowHUD(bShowOverlay);
	if (MoviePlayer != none)
	{
		return;
	}

	MoviePlayer = new class'AOCGFxTweenableMoviePlayer';
	MoviePlayer.MovieInfo = SwfToLoad;
	MoviePlayer.PlayerOwner = GetALocalPlayerController();
	MoviePlayer.SetTimingMode(TM_Real);

	MoviePlayer.bCaptureInput = false;
	MoviePlayer.SetMovieCanReceiveFocus(false);
	MoviePlayer.SetMovieCanReceiveInput(false);

	MoviePlayer.Start();

	 //force the movie one frame forward. This means it'll initialize its constituent widgets so we can manipulate them immediately
	MoviePlayer.Advance(0);

	MoviePlayer.SetViewScaleMode(SM_NoScale);
	MoviePlayer.SetAlignment(Align_TopLeft);

	//Set up the movie variables
	MovieRoot = MoviePlayer.GetVariableObject("_root");
	DescriptionMovieClip = MovieRoot.GetObject("Description");
	HudWidget = MovieRoot.GetObject("LSHud");

	//And now the text...
	DescriptionMovieClip.GetObject("description").SetString("htmlText", "Take as many enemies out with you as you can!<br/><br/>The <b>defending</b> team:<br/>is on its LAST STAND<br/>cannot respawn<br/>starts with bonus health<br/>gets points from kills, with a bonus multiplier<br/><br/>The <b>attacking</b> team:<br/>has the defenders SURROUNDED<br/>can respawn<br/>does not score points");
	DescriptionMovieClip.GetObject("instructions").SetString("htmlText", "Press <b>ATTACK</b> to close<br/>Press <b>F1</b> to show again at any time");

	LSGRI = LastStandGRI(Worldinfo.GRI);

	if(LSGRI != none)
	{
		LSGRI.Hud = self;
		LSGRI.ReplicatedEvent('DefendingTeam');
		LSGRI.ReplicatedEvent('NumDefendersAlive');
		LSGRI.ReplicatedEvent('SecondsUntilMultiplierIncrease');
		LSGRI.ReplicatedEvent('CurrentMultiplier');
		LSGRI.ReplicatedEvent('MultiplierProgress');
	}

	SetMultiplierDescriptionText("Defenders'<br/>Kill Multiplier");
}

function SetMultiplier(float Value)
{
	local ASValue ASVal;
	local array<ASValue> Args;
	ASVal.Type = AS_number;
	ASVal.n = Value;
	Args[0] = ASVal;

	HudWidget.Invoke("SetMultiplier", Args);
}

function SetMultiplierAnimateTime(float Value)
{
	local ASValue ASVal;
	local array<ASValue> Args;
	ASVal.Type = AS_number;
	ASVal.n = Value;
	Args[0] = ASVal;

	HudWidget.Invoke("SetMultiplierAnimateTime", Args);
}

function SetMultiplierProgress(float Value)
{
	local ASValue ASVal;
	local array<ASValue> Args;
	ASVal.Type = AS_number;
	ASVal.n = Value;
	Args[0] = ASVal;

	HudWidget.Invoke("SetMultiplierProgress", Args);
}

function StopMultiplierProgress()
{
	local ASValue ASVal;
	local array<ASValue> Args;
	ASVal.Type = AS_Null;
	Args[0] = ASVal;

	HudWidget.Invoke("StopMultiplierProgress", Args);
}

function SetMultiplierDescriptionText(string Value)
{
	local ASValue ASVal;
	local array<ASValue> Args;
	ASVal.Type = AS_String;
	ASVal.s = Value;
	Args[0] = ASVal;

	HudWidget.Invoke("SetMultiplierDescriptionText", Args);
}

function SetDefendersLeftText(string Value)
{
	local ASValue ASVal;
	local array<ASValue> Args;
	ASVal.Type = AS_String;
	ASVal.s = Value;
	Args[0] = ASVal;

	HudWidget.Invoke("SetDefendersLeftText", Args);
}

function SetYourTeamText(string Value)
{
	local ASValue ASVal;
	local array<ASValue> Args;
	ASVal.Type = AS_String;
	ASVal.s = Value;
	Args[0] = ASVal;

	HudWidget.Invoke("SetYourTeamText", Args);
}

function OnRepDefendingTeam()
{
	local EAOCFaction MyTeam;
	local PlayerController PC;
	
	PC = GetALocalPlayerController();
	if(AOCPawn(PC.Pawn) != none)
	{
		MyTeam = AOCPawn(PC.Pawn).GetAOCTeam();
	}
	else
	{
		MyTeam = AOCPlayerController(PC).CurrentFamilyInfo.FamilyFaction;
	}

	if(MyTeam == LastStandGRI(Worldinfo.GRI).DefendingTeam) //defending
	{
		SetYourTeamText("You are DEFENDING");
	}
	else //attacking
	{
		SetYourTeamText("You are ATTACKING");
	}
}
function OnRepNumDefendersAlive()
{
	UpdateDefendersLeftText();
}
function OnRepSecondsUntilMultiplierIncrease()
{
	SetMultiplierAnimateTime(LastStandGRI(Worldinfo.GRI).SecondsUntilMultiplierIncrease);
}
function OnRepCurrentMultiplier()
{
	SetMultiplier(LastStandGRI(Worldinfo.GRI).CurrentMultiplier);
}
function OnRepMultiplierProgress()
{
	SetMultiplierProgress(LastStandGRI(Worldinfo.GRI).MultiplierProgress);
}

function DrawHUD()
{
	super.DrawHUD();

	//Update score/defenders left
	UpdateDefendersLeftText();

	if(Worldinfo.NetMode != NM_Client)
	{
		//Hacky way of handling standlone / listen (no repnotify)
		OnRepDefendingTeam();
		OnRepNumDefendersAlive();
		OnRepSecondsUntilMultiplierIncrease();
		OnRepCurrentMultiplier();
		OnRepMultiplierProgress();
	}
}

function UpdateDefendersLeftText()
{
	local string Text;
	local int NumDefenders;
	local PlayerReplicationInfo TempPRI;

	foreach WorldInfo.GRI.PRIArray(TempPRI)
	{
		if(AOCPRI(TempPRI).CurrentHealth > 0 && AOCPRI(TempPRI).GetCurrentTeam() == LastStandGRI(Worldinfo.GRI).DefendingTeam)
		{
			++NumDefenders;
		}
	}

	Text = NumDefenders@"defenders alive";
	Text $= "<br/>Agatha:"@Round(Worldinfo.GRI.Teams[0].Score)@"points";
	Text $= "<br/>Mason:"@Round(Worldinfo.GRI.Teams[1].Score)@"points";
	Text $= "<br/>First team to"@Worldinfo.GRI.Goalscore@"points wins";
	Text $= "<br/>Press F1 for instructions";
	SetDefendersLeftText(Text);
}

function ShowHelp()
{
	if(bHelpShowing)
	{
		HideHelp();
	}
	else
	{
		DescriptionMovieClip.SetVisible(true);
	}
}
function HideHelp()
{
	DescriptionMovieClip.SetVisible(false);
	bHelpShowing = false;
}

defaultproperties
{
	SwfToLoad = SwfMovie'UI_LastStand.LSHud'
}