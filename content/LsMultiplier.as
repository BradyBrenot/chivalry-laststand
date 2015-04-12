import gfx.core.UIComponent;

class LsMultiplier extends gfx.core.UIComponent
{
	var _progress:Number;
	
	var NUM_FRAMES:Number = 100;

	[Inspectable(name="value", defaultValue="")]
	public function get progress():Number 
	{ 
		return _progress; 
	}
	public function set progress(value:Number):Void 
	{
		this._progress = value;
		gotoAndStop((NUM_FRAMES-1) * _progress);
	}
	
	function LsMultiplier()
	{
		super();
	}
}