package  {
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.display.MovieClip;
	
	public class Main extends MovieClip {
		//state/object tracking arrays
		var objList:Array = new Array();	//tracks all active objects
		var selectList:Array = new Array();	//tracks what the player has selected
		var moveList:Array = new Array(); //tracks moving units
		var keyList:Array = new Array(); //tracks pushed keys
		
		//static keys
		const UP:uint = 38;	
		const DOWN:uint = 40;
		const LEFT:uint = 37;
		const RIGHT:uint = 39;
		const SHIFT:uint = 16;
		const CTRL:uint = 17;
		const ESCAPE:uint = 27;
		const ONE:uint = 49;
		const TWO:uint = 50;
		const THREE:uint = 51;
		const M_KEY:uint = 77;
		
		//initial objects
		var boundBox:Box;
		var miniMap:MiniMap;
		var testmap:Map = new Map();
		var base:Base = new Base();	//test objects
		var worker:Worker = new Worker();
		var cam:Cam = new Cam();
		
		//misc helper vars
		var moveCnt:int = 0;	//buffer for boundBox on mouse move
		var mButton:int = 0; //distinguish between mouse buttons
		
		public function Main() {
			//manageObjList(objList, testmap, 0, 1);
			manageObjList(objList, base, 1, 1);
			manageObjList(objList, worker, 1, 1);
			
			testmap.x=-100;
			testmap.y=-100;
			cam.startX=-100;
			cam.startY=-100;
			base.x = 670;
			base.y = 590;
			worker.x = 530;
			worker.y = 390;
			addChildAt(testmap, 0);
			testmap.addChild(worker);
			testmap.addChild(base);
			miniMap = new MiniMap(testmap);
			addChildAt(miniMap, 1);
			miniMap.y = stage.stageHeight - miniMap.height;
			miniMap.x = 0;
			
			addEventListener(Event.ENTER_FRAME, Engine);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPushed);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyReleased);
			addEventListener(MouseEvent.MOUSE_MOVE, mouseMoved);
			testmap.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent){mapClick(e,0)});		//remove dragbox
			testmap.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent){mapClick(e,1)});		//initialize dragbox
			testmap.addEventListener(MouseEvent.RIGHT_CLICK, function(e:MouseEvent){mapClick(e,2)});		//unit movement
		}
		
		//begin event listener functions
		private function Engine(e:Event) {	//ENTER_FRAME
			checkForScroll();
			updateCameras();
			checkForBoxSelect();
			moveUnits();
		}
		
		private function updateCameras() {
			var movedX = false;
			var movedY = false;
			
			if (miniMap.isClicked) {
				if (miniMap.clickX > (testmap.width-stage.stageWidth)) {	//constrain extents
					testmap.x = -(testmap.width-stage.stageWidth+1);
					movedX = true;
				}
				if (miniMap.clickY > (testmap.height-stage.stageHeight)) {
					testmap.y = -(testmap.height-stage.stageHeight+1);
					movedY = true;
				}
				if (miniMap.clickY < stage.stageHeight) {
					testmap.y = -1;
					movedY = true;
				}
				if (miniMap.clickX < stage.stageWidth) {
					testmap.x = -1;
					movedX = true;
				}
				//if (miniMap.cam.clickX < (stage.stageWidth)) {miniMap.cam.clickX = testmap.width-stage.stageWidth-1;}
				
					trace(miniMap.cam.startX+","+miniMap.cam.endX+" mid: "+(miniMap.cam.startX+miniMap.cam.endX)/2);
					trace("X: " + (-(miniMap.clickX-((miniMap.cam.startX+miniMap.cam.endX)/2))));
					//testmap.x = -(miniMap.clickX-((miniMap.cam.startX+miniMap.cam.endX)/2));
					//testmap.y = -(miniMap.clickY-((miniMap.cam.startY+miniMap.cam.endY)/2));
					if (!movedX) {testmap.x = -miniMap.clickX;}
					if (!movedY) {testmap.y = -miniMap.clickY;}
					
				
				miniMap.isClicked = false;
			}
			
			cam.updatePos(testmap.x, testmap.y, Math.abs(testmap.x) + stage.stageWidth, Math.abs(testmap.y) + stage.stageHeight);
			//trace(testmap.x + ", " + testmap.y + " : " + testmap.x + stage.stageWidth + ", " + testmap.y + stage.stageHeight);
			
			miniMap.cam.updatePos(cam.startX, cam.startY, cam.endX, cam.endY);
		}
		
		private function keyPushed(e:KeyboardEvent) {	//KEY_DOWN
			if (keyList.indexOf(e.keyCode) === -1) {	//if it's not already in there
				keyList.push(e.keyCode);	//append to pushed keys array
			}
			
			switch(e.keyCode) {
				case ONE:
					spawn("Worker");
					break;
				case TWO:
					spawn("Base");
					break;
				case THREE:
					spawn("Resource");
					break;
				case ESCAPE:
					clearAllSelections();
					break;
				case M_KEY:
					mapClick(null,2);
					break;
			}
		}
		
		private function keyReleased(e:KeyboardEvent) {		//KEY_UP
			keyList.splice(keyList.indexOf(e.keyCode), 1);		//remove from pushed keys array
		}
		
		private function mouseMoved(e:MouseEvent) {		//MOUSE_MOVE
			if (e.buttonDown && mButton && isPressed(CTRL)) {
				mapClick(null,2);
			}
			else if (e.buttonDown && mButton) {	//if left button clicked
				moveCnt++;	//boundBox spawn buffer
				if (moveCnt > 3) {	//wait until the mouse has been moved at least 5 units
					if (boundBox) {	//if boundbox hasn't yet been initialized, ignore the .isActive attribute
						if (!boundBox.isActive) {
							boundBox = new Box(testmap);
						}
					}
					else {
						boundBox = new Box(testmap); //initialize
					}
				}
			}
			if (!e.buttonDown || !mButton) {
				moveCnt = 0;
			}
		}
		
		private function mapClick(e:MouseEvent, State:uint) {		//MOUSE -- DOWN/UP/RIGHT_CLICK
			if (State == 0) {	//mouseup
				if (boundBox) {	//if boundbox has been initialized
					if (boundBox.isActive) {	//and is active
						boundBox.finishSelect(objList);	//send it the current object list
					}
				}
				
				mButton = 0;
			}
			else if (State == 1) {	//mousedown
				mButton = 1;
			}
			else if (State == 2) {	//right mousedown
				mButton = 2;
				populateMoveList(1);
			}
		}
		//end event listener functions
		
		private function populateMoveList(map:uint) {
			trace('yup');
		if (selectList.length > -1) { //if something is selected
				for(var i:uint = 0; i < selectList.length; i++) {
					if (selectList[i].isMoveable) {	//if moveable
						//move it there
						if (!selectList[i].isMoving) {	//if it isn't already moving, add to the move list
							moveList.push(selectList[i]);
							//trace(selectList[i].dX + ":" + selectList[i].dY);
						}
						else {
							selectList[i].clearMove();
						}
						
						if (!map) {		//if the minimap was clicked
							selectList[i].moveToDest(miniMap.clickX, miniMap.clickY);
						}
						else {		//if the map was clicked
							selectList[i].moveToDest(testmap.mouseX, testmap.mouseY);
						}
					}
				}
			}
		}
		private function objClick(e:MouseEvent) {
			if (!isPressed(SHIFT)) {clearAllSelections();}

			if (e.currentTarget.isSelected) {
				rmSelection(e.currentTarget);
			}
			else {
				newSelection(e.currentTarget);
			}
			trace(selectList.length);
		}
		
		private function moveUnits() {
			if (miniMap.isRightClicked) {	//if the minimap was clicked, proceed with the moving
				populateMoveList(0);
				miniMap.isRightClicked = false;
			}
			
			if (moveList.length > -1) {
				for(var i:uint = 0; i < moveList.length; i++) {
					if (withinArea(moveList[i], 0.4)) {		//if we've reached our destination
						moveList[i].clearMove();
						moveList.splice(i, 1);
						continue;
					}
					else {
						moveList[i].x += moveList[i].xStep;
						moveList[i].y += moveList[i].yStep;
						if (moveList[i].selectRef != null) {
							moveList[i].selectRef.x += moveList[i].xStep;
						    moveList[i].selectRef.y += moveList[i].yStep;
						}
					}
				}
			}
		}
		
		private function spawn(type:String) {
			var newUnit:MovieClip;
			switch(type) {
				case "Worker":
					newUnit = new Worker();
					break;
				case "Base":
					newUnit = new Base();
					break;
				case "Resource":
					newUnit = new Resource();
					break;
			}
			newUnit.x = testmap.mouseX;
			newUnit.y = testmap.mouseY;
			manageObjList(objList, newUnit, 1, 1);
			testmap.addChild(newUnit);
			//trace(objList.length);
		}
		
		private function checkForScroll() {
			var val:uint = 10;
			if ((stage.mouseX <= 1 || keyList.indexOf(LEFT) !== -1) && testmap.x < 0) {
				testmap.x += val;
			}
			
			if ((stage.mouseX >= stage.stageWidth-3 || keyList.indexOf(RIGHT) !== -1) && testmap.x > (testmap.width - stage.stageWidth)*-1) {
				testmap.x -= val;
			}
			
			if ((stage.mouseY <= 1 || keyList.indexOf(UP) !== -1) && testmap.y < 0) {
				testmap.y += val;
			}
			
			if ((stage.mouseY >= stage.stageHeight-3 || keyList.indexOf(DOWN) !== -1) && testmap.y > (testmap.height - stage.stageHeight)*-1) {
				testmap.y -= val;
			}
		}
	
		private function newSelection(tar:Object) {
			if (!tar.isSelected) {
				tar.select(testmap);
				//trace("selected " + target);
				selectList.push(tar);
			}
		}
		
		private function rmSelection(tar:Object) {
			//trace(tar.isSelected);
			if (tar.isSelected) {
				tar.clearSelect(testmap);
				selectList.splice(selectList.indexOf(tar),1);
			}
		}
		
		public function checkForBoxSelect() {
			if (boundBox) {
				if (boundBox.isReady) {
					boundBox.isReady = false;
					if (!isPressed(SHIFT)) {
						clearAllSelections();
					}
					
					for(var i:uint = 0; i < boundBox.selectList.length; i++) {		//build list of selected objects
						if (isPressed(SHIFT)) {
							if (selectList.indexOf(boundBox.selectList[i]) === -1) {	//if it's not already there, add it
								//trace("not in there");
								newSelection(boundBox.selectList[i]);
							}
							else {	//it's already in there, remove it
								//trace("in there");
								rmSelection(boundBox.selectList[i]);
							}
						}
						else {
							newSelection(boundBox.selectList[i]);
						}
					}
				}
			}
		}
		
		//ease of use functions
		private function manageObjList(list:Array, obj:Object, modifyListener:int, fate:int) {		//generic array management
			var index = list.indexOf(obj);
			if (fate) {	//add to list
				list.push(obj);
				if (modifyListener) {obj.addEventListener(MouseEvent.MOUSE_DOWN, objClick);}
			}
			else {	//remove from list
				if (modifyListener) {list[index].removeEventListener(MouseEvent.MOUSE_DOWN, objClick);}
				list.splice(list[index], 1);
			}
		}
		
		private function clearAllSelections() {
			for(var i:uint = 0; i < selectList.length; i++) {
				selectList[i].clearSelect(testmap);
			}
			selectList = new Array();
			//trace(selectList.length);
		}
		
		private function withinArea(obj:Object, area:Number) {
			return (Math.abs(obj.x - obj.xD) < area || Math.abs(obj.y - obj.yD) < area) ;
		}
		
		private function isPressed(key:uint) {
			return !keyList.indexOf(key);
		}
	}
}
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.display.DisplayObjectContainer;
import flash.events.MouseEvent;
import flash.events.Event;
import flash.display.Shape;


//generic declarations
class Map extends MovieClip {	//only need one of these!
	var visual:MovieClip = new MCTestMap();
	
	public function Map() {
		this.addChildAt(visual, 0);
		this.height = visual.height;
		this.width = visual.width;
	}
}

class Cam extends MovieClip {
	var startX:int, startY:int;
	var endX:int, endY:int;
	
	public function Cam() {
		
	}
	
	public function updatePos(_startX, _startY, _endX, _endY) {
		startX = Math.abs(_startX);
		endX = Math.abs(_endX);
		startY = Math.abs(_startY);
		endY = Math.abs(_endY);
	}
}

class Doodad extends MovieClip {
	public var isMoveable:Boolean = false;
	public var isSelected:Boolean = false;
	public var isMoving:Boolean = false;
	public var isAttackable:Boolean = false;
	var selectRef:MovieClip;
	var amount:Number = 2000;
	var type:int = 2;	//0 = building, 1 = unit, 2 = doodad
	var size:Number = 1;
	
	public function Doodad() {
	}
	
	public function select(addTo:MovieClip) {
		selectRef = new MCSelect;
		selectRef.x = this.x;
		selectRef.y = this.y;
		selectRef.width *= size;
		selectRef.height *= size;
		addTo.addChild(selectRef);
		isSelected = true;
	}
	
	public function clearSelect(removeFrom:MovieClip) {
		removeFrom.removeChild(selectRef);
		isSelected = false;
	}
}

class Building extends MovieClip {		//basic building declaration
	public var isMoveable:Boolean = false;
	public var isSelected:Boolean = false;
	public var isMoving:Boolean = false;
	public var isAttackable:Boolean = true;
	var selectRef:MovieClip;
	var hp:Number = 150;
	var shields:Number = 0;
	var armor:Number = 0;
	var type:int = 0;	//0 = building, 1 = unit
	var size:Number = 1.5;
	
	public function Building() {
	}
	
	public function select(addTo:MovieClip) {
		selectRef = new MCSelect;
		selectRef.x = this.x;
		selectRef.y = this.y;
		selectRef.width *= size;
		selectRef.height *= size;
		addTo.addChild(selectRef);
		isSelected = true;
	}
	
	public function clearSelect(removeFrom:MovieClip) {
		removeFrom.removeChild(selectRef);
		isSelected = false;
	}
}

class Unit extends MovieClip {		//basic unit declaration
	public var isMoveable:Boolean = true;
	public var isSelected:Boolean = false;
	public var isMoving:Boolean = false;
	public var isAttackable:Boolean = true;
	var speed:Number = 1;
	var xD:int, yD:int;		//destination coordinates
	var xStep:Number, yStep:Number;		//steps at each iteration accounting speed
	
	var selectRef:MovieClip;
	var combatType:int = 0;	//0 = melee, 1 = air
	var hp:Number = 50;
	var shields:Number = 0;
	var armor:Number = 0;
	var dps:Number = 5;
	var type:int = 1;	//0 = building, 1 = unit
	var size:Number = 1;
	
	public function Unit() {
	}
	
	public function moveToDest(posX:int, posY:int) {
		xD = posX;
		yD = posY;
		var angle:Number = Math.atan2(posY - this.y, posX - this.x);
		
		xStep = Math.cos(angle) * this.speed;
		yStep = Math.sin(angle) * this.speed;
		//trace(xD + ":" + this.x + ", " + xStep);
		//trace(yD + ":" + this.y + ", " + yStep);
		isMoving = true;
	}
	
	public function clearMove() {
		xD = 0;
		yD = 0;
		xStep = 0;
		yStep = 0;
		isMoving = false;
	}
	
	public function select(addTo:MovieClip) {
		selectRef = new MCSelect;
		selectRef.x = this.x;
		selectRef.y = this.y;
		selectRef.width *= size;
		selectRef.height *= size;
		addTo.addChild(selectRef);
		isSelected = true;
	}
	
	public function clearSelect(removeFrom:MovieClip) {
		removeFrom.removeChild(selectRef);
		isSelected = false;
	}
}

class Box extends Sprite {
	private var canvas:DisplayObjectContainer;
	private var startX:Number;
	private var startY:Number;
	private var endX:Number;
	private var endY:Number;
	private var objList:Array;
	var isActive:Boolean = true;
	var isReady:Boolean = false;
	var selectList:Array = new Array();

	public function Box(_canvas:DisplayObjectContainer)
	{			
		canvas = _canvas;
		startX = canvas.mouseX;
		startY = canvas.mouseY;
		endX = startX;
		endY = startY;
		
		canvas.addChild(this);
		canvas.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveHandler);
		canvas.addEventListener(MouseEvent.MOUSE_UP, onMouseUpHandler);
		canvas.addEventListener(Event.ENTER_FRAME, onEnterFrameHandler);
	}
	
	private function onMouseMoveHandler(event:MouseEvent):void
	{
		endX = canvas.mouseX;
		endY = canvas.mouseY;
	}
	
	public function finishSelect(list:Array) {
		objList = list;
	}
	
	private function onMouseUpHandler(event:MouseEvent):void
	{	
		selectList = new Array();
		//trace("start");
		for(var i:uint = 0; i < objList.length; i++) {		//build list of selected objects
			//trace(i + ":" + startX + "<" + objList[i].x + "<" + endX + ", " + startY + "<" + objList[i].y + "<" + endY);
			//trace(startX < objList[i].x && objList[i].x < endX && startY < objList[i].y && objList[i].y < endY);
			if (startX < objList[i].x && objList[i].x < endX && startY < objList[i].y && objList[i].y < endY ||	//top left to bottom right
			objList[i].x < startX && endX < objList[i].x && objList[i].y < startY && endY < objList[i].y || //bottom right to top left
			objList[i].x < startX && objList[i].x > endX && objList[i].y > startY && objList[i].y < endY || //top right to bottom left
			objList[i].x > startX && objList[i].x < endX && objList[i].y < startY && objList[i].y > endY) {	//bottom left to top right
				selectList.push(objList[i]);
			}
		}
		if (selectList.length > 0) {isReady = true;}
		isActive = false;
		//trace("end");

		canvas.removeChild(this);
		canvas.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveHandler);			
		canvas.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpHandler);
		canvas.removeEventListener(Event.ENTER_FRAME, onEnterFrameHandler);
	}
	
	private function onEnterFrameHandler(event:Event):void 
	{
		graphics.clear();
		graphics.lineStyle(2, 0x88B1CC);
		graphics.moveTo(startX, startY);
		graphics.beginFill(0x88B1CC, .25);
		graphics.lineTo(endX, startY);
		graphics.lineTo(endX, endY);
		graphics.lineTo(startX, endY);
		graphics.lineTo(startX, startY);
		graphics.endFill();
	}
	
}

//specific declarations
class MiniMap extends Map {
	var outline:Sprite = new Sprite();
	var clickX:Number, clickY:Number;
	var isClicked:Boolean = false;
	var isRightClicked:Boolean = false;
	var cam:Cam = new Cam();
	var mButton:int = 0;	//distinguish mouse buttons
	var moveCnt:int = 0;	//buffer for miniMap on mouse move
	
	public function MiniMap(_map:MovieClip) {
		var ratio:Number;
		
		if (this.height > this.width) {
			ratio = this.width / this.height;
			this.width = 170;
			this.height = 170 * ratio;
		}
		else {
			ratio = this.height / this.width;
			this.height = 170;
			this.width = 170 * ratio;
		}

		this.addChildAt(outline, 1);
		this.addEventListener(Event.ENTER_FRAME, onEnterFrameHandler);
		this.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent) {onClickHandler(e,0)});
		this.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent) {onClickHandler(e,1)});
		this.addEventListener(MouseEvent.RIGHT_CLICK, function(e:MouseEvent) {onClickHandler(e,2)});
		this.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveHandler);
	}

	private function onClickHandler(e:MouseEvent, btn:uint) {
		clickX = this.mouseX;
		clickY = this.mouseY;
		
		if (btn == 0) {	//mouse up;
			//trace(clickX + ", " + clickY);
			if (mButton != 2) {isClicked = true;}
			mButton = 0;
		}
		else if (btn == 1) {	//left mouse down
			mButton = 1;
		}
		else if (btn == 2) {	//right click
			mButton = 2
			trace("irg");
			isRightClicked = true;
		}
	}
	
	private function onMouseMoveHandler(e:MouseEvent) {
		moveCnt++;
		
		if (e.buttonDown && moveCnt == 5) {
			moveCnt = 0;
			clickX = this.mouseX;
			clickY = this.mouseY;
			isClicked = true;
		}
	}
	
	private function onEnterFrameHandler(e:Event) {
		//trace(cam.startX + "," + cam.startY + " : " + cam.endX + "," + cam.endY);
		drawOutline();
	}
	
	public function drawOutline() {
		outline.graphics.clear();
		outline.graphics.lineStyle(1, 0x000000);
		outline.graphics.moveTo(cam.startX, cam.startY);
		outline.graphics.beginFill(0x88B1CC, 0.25);
		outline.graphics.lineTo(cam.endX, cam.startY);
		outline.graphics.lineTo(cam.endX, cam.endY);
		outline.graphics.lineTo(cam.startX, cam.endY);
		outline.graphics.lineTo(cam.startX, cam.startY);
		outline.graphics.endFill();
	}
}

class Worker extends Unit {		//specific unit
	var visual:MovieClip = new MCWorker();
	
	public function Worker() {
		this.addChild(visual);
		this.height = visual.height;
		this.width = visual.width;
	}
}

class Base extends Building {	//specific building
	var visual:MovieClip = new MCBase();
	
	public function Building() {
		this.addChild(visual);
		this.height = visual.height;
		this.width = visual.width;
		hp = 500;
	}
}

class Resource extends Doodad {
	var visual:MovieClip = new MCResource();
	
	public function Resource() {
		size = 2;
		this.addChild(visual);
		this.height = visual.height;
		this.width = visual.width;
	}
}

