package soundpatchdemo {

	import Box2D.Dynamics.Contacts.b2Contact;

	import com.citrusengine.core.CitrusEngine;
	import com.citrusengine.core.CitrusObject;
	import com.citrusengine.core.State;
	import com.citrusengine.math.MathVector;
	import com.citrusengine.objects.CitrusSprite;
	import com.citrusengine.objects.platformer.box2d.Coin;
	import com.citrusengine.objects.platformer.box2d.Crate;
	import com.citrusengine.objects.platformer.box2d.Enemy;
	import com.citrusengine.objects.platformer.box2d.Hero;
	import com.citrusengine.objects.platformer.box2d.Platform;
	import com.citrusengine.objects.platformer.box2d.Sensor;
	import com.citrusengine.physics.box2d.Box2D;
	import com.citrusengine.physics.box2d.Box2DUtils;
	import com.citrusengine.physics.box2d.IBox2DPhysicsObject;
	import com.citrusengine.utils.ObjectMaker2D;

	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;

	public class DemoState extends State {

		private var _jewelMeter:JewelMeter;
		private var _objectsMC:MovieClip;
		private var _loadScreen:LoadScreen;
		private var _clickScreen:ClickScreen;
		private var _signMessage:SignMessage;
		private var _hero:Hero;
		private var _ce:CitrusEngine;
		private var _sign:Sensor;
		private var _jewels:Vector.<CitrusObject>;

		public function DemoState(objectsMC:MovieClip) {
			super();
			_ce = CitrusEngine.getInstance();
			_objectsMC = objectsMC;
			
			var objects:Array = [Platform, Hero, CitrusSprite, Sensor, Coin, Enemy, WindmillArms, Crate];
		}

		override public function initialize():void {
			super.initialize();

			_jewelMeter = new JewelMeter();
			addChild(_jewelMeter);

			_signMessage = new SignMessage();
			_signMessage.y = 80;

			_clickScreen = new ClickScreen();
			addChild(_clickScreen);
			addEventListener(MouseEvent.CLICK, handleTakeFocus);
			buttonMode = true;

			_loadScreen = new LoadScreen();
			addChild(_loadScreen);

			var box2D:Box2D = new Box2D("box2D");
			// box2D.visible = true;
			add(box2D);

			view.loadManager.onLoadComplete.addOnce(handleLoadComplete);

			ObjectMaker2D.FromMovieClip(_objectsMC);
			_hero = getFirstObjectByType(Hero) as Hero;
			_hero.onJump.add(handleHeroJump);
			_hero.onGiveDamage.add(handleHeroGiveDamage);
			_hero.onTakeDamage.add(handleHeroTakeDamage);
			_hero.onAnimationChange.add(handleHeroAnimationChange);
			_hero.controlsEnabled = false;

			view.setupCamera(_hero, new MathVector(320, 240), new Rectangle(0, 0, 3300, 417), new MathVector(.25, .05));

			_sign = getObjectByName("signSensor") as Sensor;
			_sign.onBeginContact.add(handleEnterSign);
			_sign.onEndContact.add(handleExitSign);

			_jewels = getObjectsByType(Coin);
			for each (var jewel:Coin in _jewels)
				jewel.onBeginContact.add(handleJewelCollected);
		}

		override public function update(timeDelta:Number):void {
			super.update(timeDelta);

			if (_loadScreen.parent) {
				_loadScreen.pctText.text = Math.round(view.loadManager.bytesLoaded / view.loadManager.bytesTotal * 100).toString();
			}
		}

		private function handleLoadComplete():void {
			removeChild(_loadScreen);
		}

		private function handleEnterSign(contact:b2Contact):void {
			
			var other:IBox2DPhysicsObject = Box2DUtils.CollisionGetOther(_sign, contact);
			
			if (other is Hero) {
				addChild(_signMessage);
				_signMessage.show("Welcome to the <font color='#f68e1e'>Citrus Engine!</font><br />The Citrus Engine is a side-scrolling platform game engine designed to make wonderful games like this one. If your team or company is looking to create a game that makes people say 'I didn't know Flash could do that!', then the Citrus Engine might be the right tool for you. So what are you waiting for, check out the rest of this demo, or go <a href='http://citrusengine.com/about'><font color='#9999ff'>learn more about it!</font></a>", false);
				_signMessage.x = (stage.stageWidth - _signMessage.width) / 2;
			}
		}

		private function handleExitSign(contact:b2Contact):void {
			
			var other:IBox2DPhysicsObject = Box2DUtils.CollisionGetOther(_sign, contact);
			
			if (other is Hero) {
				removeChild(_signMessage);
			}
		}

		private function handleTakeFocus(e:MouseEvent):void {
			removeEventListener(MouseEvent.CLICK, handleTakeFocus);
			removeChild(_clickScreen);
			buttonMode = false;
			_hero.controlsEnabled = true;

			_ce.sound.playSound("Song");
		}

		private function handleJewelCollected(contact:b2Contact):void {
			
			var self:IBox2DPhysicsObject;
			for each (var jewel:Coin in _jewels) {
				
				self = Box2DUtils.CollisionGetSelf(jewel, contact);
				
				if (self == jewel)
					break;
			}
					
			if (Box2DUtils.CollisionGetOther(self, contact) != _hero)
				return;

			_ce.sound.playSound("Collect", 1, 0);

			_jewelMeter.collectJewel();
			if (_jewelMeter.jewelsCollected == 5) {
				addChild(_signMessage);
				_signMessage.show("Wow, you found every jewel! The Citrus Engine is a free and open source engine, feel free to contribute!", false);
				_signMessage.x = (stage.stageWidth - _signMessage.width) / 2;
			}
		}

		private function handleHeroJump():void {
			_ce.sound.playSound("Jump", 1, 0);
		}

		private function handleHeroGiveDamage():void {
			_ce.sound.playSound("Kill", 1, 0);
		}

		private function handleHeroTakeDamage():void {
			_ce.sound.playSound("Hurt", 1, 0);
		}

		private function handleHeroAnimationChange():void {
			if (_hero.animation == "walk") {
				_ce.sound.stopSound("Skid");
				_ce.sound.playSound("Walk", 1);
				return;
			} else {
				_ce.sound.stopSound("Walk");
			}

			if (_hero.animation == "skid") {
				_ce.sound.playSound("Skid", 1, 0);
				return;
			} else {
				_ce.sound.stopSound("Skid");
			}
		}
	}
}