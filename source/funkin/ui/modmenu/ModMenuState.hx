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

   // Hello PeakSlice
  var lastTapTime:Float = 0;
  var lastTapIndex:Int = -1;
  var DOUBLE_TAP_THRESHOLD:Float = 0.3; // 300ms

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
    organizeByY();
  }

  override function update(elapsed:Float)
  {
    if (FlxG.keys.justPressed.R) refreshModList();

    selections();

  #if FEATURE_TOUCH_CONTROLS
    if (SwipeUtil.justSwipedUp) selections(-1);
    if (SwipeUtil.justSwipedDown) selections(1);
  #end
    organizeByY();

    if (controls.UI_UP_P) selections(-1);
    if (controls.UI_DOWN_P) selections(1);

    if (FlxG.keys.justPressed.SPACE) grpMods.members[curSelected].modEnabled = !grpMods.members[curSelected].modEnabled;

     //Thanks PeakSlice LOL
    if (FlxG.mouse.justPressed)
    {
      var currentTime = Sys.time();
      var tappedIndex = -1;

      for (i in 0...grpMods.length)
      {
        var item = grpMods.members[i];
        if (FlxG.mouse.overlaps(item))
        {
          tappedIndex = i;
          break;
        }
      }

      if (tappedIndex >= 0)
      {
        if (tappedIndex == lastTapIndex && (currentTime - lastTapTime) < DOUBLE_TAP_THRESHOLD)
        {
          toggleModState(tappedIndex);
          //grpMods.members[curSelected].modEnabled = !grpMods.members[curSelected].modEnabled;
        }
        else
        {
          curSelected = tappedIndex;
          selections(0); // Just update selection visuals
        }

        lastTapTime = currentTime;
        lastTapIndex = tappedIndex;
      }
    }

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

  function toggleModState(index:Int):Void
  {
    if (index < 0 || index >= detectedMods.length) return;

    var modMetadata = detectedMods[index];
    var modItem = grpMods.members[index];
    var isEnabled = Save.instance.enabledModIds.indexOf(modMetadata.id) != -1;

    if (isEnabled)
    {
      // Disable mod
      var newIds = Save.instance.enabledModIds.copy();
      newIds.remove(modMetadata.id);
      Save.instance.enabledModIds = newIds; // Use setter
      modItem.setModState(false);
      //statusText.text = "$modMetadata.title disabled";
    }
    else
    {
      // Enable mod
      var newIds = Save.instance.enabledModIds.copy();
      if (newIds.indexOf(modMetadata.id) == -1) newIds.push(modMetadata.id);
      Save.instance.enabledModIds = newIds; // Use setter
      modItem.setModState(true);
      //statusText.text = "$modMetadata.title enabled";
    }
    //Save.instance.debug_dumpSave();
    // Show restart prompt
    //statusText.text = "Changes saved!";
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
      //modItem.setFormat(Paths.font('vcr.ttf'), 58);
      modItem.font = "5by7";

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
      grpMods.members[i].y = 210 + (50 * i);
      grpMods.members[i].x = 40;
    }
  }

  public function exitModMenu():Void
  {
    PolymodHandler.forceReloadAssets();
    FlxG.switchState(new OptionsState());
  }
}

//PeakSlice
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
    setModState(false);
  }

  public function setModState(enabled:Bool):Void
  {
    modEnabled = enabled;
    if (enabled)
    {
      color = FlxColor.LIME;
      alpha = 1.0;
      text = modMetadata.title + " (Enabled)";
      defaultColor = FlxColor.LIME;
    }
    else
    {
      color = FlxColor.WHITE;
      alpha = 0.5;
      text = modMetadata.title;
      defaultColor = FlxColor.WHITE;
    }
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);
  }
}
