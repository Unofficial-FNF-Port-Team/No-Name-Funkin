package funkin.ui.modmenu;

import funkin.ui.MusicBeatState;
import funkin.ui.options.OptionsState;
import funkin.modding.PolymodHandler;
import funkin.save.Save;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import polymod.Polymod.ModMetadata;
#if FEATURE_TOUCH_CONTROLS
import funkin.mobile.ui.FunkinBackButton;
import funkin.util.SwipeUtil;
#end

class ModMenuState extends MusicBeatState {
  var grpMods:FlxTypedGroup<ModMenuItem>;
  var enabledMods:Array<ModMetadata> = [];
  var detectedMods:Array<ModMetadata> = [];

  var curSelected:Int = 0;

  override public function create():Void
  {
    super.create();

    var bg = new FlxSprite(Paths.image('menuBG'));
    bg.scrollFactor.x = #if !mobile 0 #else 0.17 #end; // we want a lil x scroll on mobile
    bg.scrollFactor.y = 0.17;
    bg.setGraphicSize(Std.int(FlxG.width * 1.2));
    bg.updateHitbox();
    bg.screenCenter();
    add(bg);

    grpMods = new FlxTypedGroup<ModMenuItem>();
    add(grpMods);

   #if FEATURE_TOUCH_CONTROLS
    var backButton:FunkinBackButton = new FunkinBackButton(FlxG.width - 230, FlxG.height - 200, FlxColor.WHITE, exitModMenu, 1.0);
    add(backButton);
   #end
    refreshModList();
  }

  override function update(elapsed:Float)
  {
    if (FlxG.keys.justPressed.R) refreshModList();

    selections();

  #if FEATURE_TOUCH_CONTROLS
    if (SwipeUtil.justSwipedUp) selections(-1);
    if (SwipeUtil.justSwipedDown) selections(1);
  #end

    if (controls.UI_UP_P) selections(-1);
    if (controls.UI_DOWN_P) selections(1);

    if (FlxG.keys.justPressed.SPACE) grpMods.members[curSelected].modEnabled = !grpMods.members[curSelected].modEnabled;

    if (FlxG.keys.justPressed.I && curSelected != 0)
    {
      var oldOne = grpMods.members[curSelected - 1];
      grpMods.members[curSelected - 1] = grpMods.members[curSelected];
      grpMods.members[curSelected] = oldOne;
      selections(-1);
    }

    if (FlxG.keys.justPressed.K && curSelected < grpMods.members.length - 1)
    {
      var oldOne = grpMods.members[curSelected + 1];
      grpMods.members[curSelected + 1] = grpMods.members[curSelected];
      grpMods.members[curSelected] = oldOne;
      selections(1);
    }

    super.update(elapsed);
  }

  function selections(change:Int = 0):Void
  {
    curSelected += change;

    if (curSelected >= detectedMods.length) curSelected = 0;
    if (curSelected < 0) curSelected = detectedMods.length - 1;

    for (txt in 0...grpMods.length)
    {
      if (txt == curSelected)
      {
        grpMods.members[txt].color = FlxColor.YELLOW;
      }
      else
        grpMods.members[txt].color = FlxColor.WHITE;
    }

    organizeByY();
  }

  function refreshModList():Void
  {
    while (grpMods.members.length > 0)
    {
      grpMods.remove(grpMods.members[0], true);
    }

    #if sys
    detectedMods = PolymodHandler.getAllMods();

    trace('ModMenu: Detected ${detectedMods.length} mods');

    for (index in 0...detectedMods.length)
    {
      var modMetadata = detectedMods[index];
      var modItem = new ModMenuItem(-40, 40 + (50 * index), 0, modMetadata.title, 32, modMetadata);
      modItem.setFormat(Paths.font('vcr.ttf'), 58);

      var delay:Float = index * 0.05;
      FlxTween.tween(modItem, {x: 40}, 1, {startDelay: delay, ease: FlxEase.cubeOut});

      modItem.modEnabled = Save.instance.enabledModIds.indexOf(modMetadata.id) != -1;

      grpMods.add(modItem);
    }
    #end
  }

  function organizeByY():Void
  {
    for (i in 0...grpMods.length)
    {
      grpMods.members[i].y = 10 + (40 * i);
    }
  }

  public function exitModMenu():Void
  {
    PolymodHandler.forceReloadAssets();
    FlxG.switchState(new OptionsState());
  }
}

class ModMenuItem extends FlxText
{
  public var modEnabled:Bool = false;
  public var daMod:String;
  public var modMetadata:ModMetadata;
  public var defaultColor:FlxColor = FlxColor.WHITE;

  public function new(x:Float, y:Float, w:Float, str:String, size:Int, metadata:ModMetadata)
  {
    super(x, y, w, str, size);
    daMod = metadata.id;
    modMetadata = metadata;
    modEnabled = false;
  }

  override function update(elapsed:Float)
  {
    if (modEnabled) alpha = 1;
    else
      alpha = 0.5;

    super.update(elapsed);
  }
}
