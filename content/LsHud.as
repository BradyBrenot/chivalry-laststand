import gfx.core.UIComponent;
import gfx.motion.Tween;
import mx.transitions.easing.*;

class LsHud extends gfx.core.UIComponent
{
	var yourTeamText:TextField;
	var defendersLeftText:TextField;
	var multiplierDescriptionText:TextField;
	var multiplierText:TextField;

	var multiplier:MovieClip;
	var MultiplierExploder:MovieClip;

	var _lastMultiplier:Number;

	//Time in seconds before the multiplier progress indicator goes from 0% to 100%
	var _multiplierAnimateTime:Number = 5.0;

	function LsHud()
	{
		super();
		Tween.init();
	}

	function SetMultiplier(value:Number)
	{
		if (_lastMultiplier < value)
		{
			MultiplierExploder.gotoAndPlay("animate");
		}

		_lastMultiplier = value;

		multiplierText.htmlText = int(value) + "x";
	}

	function SetMultiplierAnimateTime(value:Number)
	{
		_multiplierAnimateTime = value;
	}

	function SetMultiplierProgress(value:Number)
	{
		multiplier["progress"] = value;
		multiplier.tweenEnd(false);
		var timeToAnimate:Number = _multiplierAnimateTime * (1.0 - value);
		MovieClip(multiplier).tweenTo(timeToAnimate,{progress:1.0},None.easeOut);
	}

	function StopMultiplierProgress()
	{
		multiplier.tweenEnd(false);
	}

	function SetMultiplierDescriptionText(value:String)
	{
		multiplierDescriptionText.htmlText = value;
	}
	
	function SetDefendersLeftText(value:String)
	{
		defendersLeftText.htmlText = value;
	}
	
	function SetYourTeamText(value:String)
	{
		yourTeamText.htmlText = value;
	}
}