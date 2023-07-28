-- other
type __any_function = (...any) -> ...any

-- main module
type __object = {
	cameras: __camera;
	controls: __controls;
	
	GetCameras: (self:__object) -> __camera;
	GetControls: (self:__object) -> __controls;
	GetClickToMoveController: (self:__object) -> __clickToMoveController
}
export type object = __object

-- camera
type __camera = {}
export type camera = __object

-- controls
type __controls = {
	controllers: {[__controller_module<any>]: __controller_base};
	activeControlModule: __controller_module<any>?;
	activeController: __controller_base?;
	touchJumpController: __touch_jump?;
	moveFunction: (Player, direction: Vector3, is_relative_to_camera: boolean?) 
		-> nil;
	humanoid: Humanoid?;
	lastInputType: Enum.UserInputType;
	controlsEnabled: true;
	-- For Roblox self.vehicleController
	humanoidSeatedConn: RBXScriptConnection?;
	vehicleController: __vehicle_controller?;
	touchControlFrame: Frame?;
	playerGui: PlayerGui?;
	touchGui: ScreenGui?;
	playerGuiAddedConn: RBXScriptConnection?;
	
	GetMoveVector: (self: __object) -> Vector3;
	GetActiveController: (self: __object) -> __controller_base;
	UpdateActiveControlModuleEnabled: (self: __object) -> nil;
	Enable: (self:__object, is_enabled: boolean?) -> nil;
	Disable: (self:__object) -> nil;
	SelectComputerMovementModule: (self:__object) -> ({}?, boolean); -- wtf?
	SelectTouchModule: (self:__object) -> (__controller_base?, boolean); -- touch module?
	OnRenderStepped: (self:__object, dt: number) -> nil;
	OnHumanoidSeated: (self:__object, active: boolean, currentSeatPart: BasePart) 
		-> nil;
	OnCharacterAdded: (self:__object, char: Model) -> nil;
	OnCharacterRemoving: (self:__object, char:Model) -> nil;
	UpdateTouchGuiVisibility: (self:__object) -> nil;
	SwitchToController: <A>(self:__object, __controller_module<A>) -> nil;
	OnLastInputTypeChanged: (self:__object, Enum.UserInputType) -> nil;
	OnComputerMovementModeChange: (self:__object) -> nil;
	OnTouchMovementModeChange: (self:__object) -> nil;
	CreateTouchGuiContainer: (self:__object) -> nil;
}
export type controls = __controls

type __controller_base = {
	enabled: boolean;
	moveVector: Vector3;
	moveVectorIsCameraRelative: boolean;
	isJumping: boolean;
	
	OnRenderStepped: (self:__controller_base, delta: number) -> nil;
	GetMoveVector: (self:__controller_base) -> Vector3;
	IsMoveVectorCameraRelative: (self:__controller_base) -> boolean;
	GetIsJumping: (self:__controller_base) -> boolean;
	Enable: (self:__controller_base, is_enabled: boolean) -> boolean;
}
export type controller_base = __controller_base

type __keyboard_controller = {
	CONTROL_ACTION_PRIORITY: number;
	textFocusReleasedConn: nil;
	textFocusGainedConn: nil;
	windowFocusReleasedConn: nil;
	forwardValue: number;
	backwardValue: number;
	leftValue: number;
	rightValue: number;
	jumpEnabled: boolean;
	jumpRequested: boolean;
	
	UpdateMovement: (self:__keyboard_controller, 
		inputState: Enum.UserInputState) -> nil;
	UpdateJump: (self:__keyboard_controller) -> nil;
	BindContextActions: (self:__keyboard_controller) -> nil;
	UnbindContextActions: (self:__keyboard_controller) -> nil;
	ConnectFocusEventListeners: (self:__keyboard_controller) -> nil;
	DisconnectFocusEventListeners: (self:__keyboard_controller) -> nil;
} & __controller_base

type __gamepad_controller = {
	CONTROL_ACTION_PRIORITY: number;
	forwardValue: number;
	backwardValue: number;
	leftValue: number;
	rightValue: number;
	activeGamepad: Enum.UserInputType;
	gamepadConnectedConn: RBXScriptConnection?;
	gamepadDisconnectedConn: RBXScriptConnection?;
	
	GetHighestPriorityGamepad: (self:__gamepad_controller) -> Enum.UserInputType;
	BindContextActions: (self:__gamepad_controller) -> boolean | Enum.ContextActionResult;
	UnbindContextActions: (self:__gamepad_controller) -> nil;
	OnNewGamepadConnected: (self:__gamepad_controller) -> nil;
	OnCurrentGamepadDisconnected: (self:__gamepad_controller) -> nil;
	ConnectGamepadConnectionListeners: (self:__gamepad_controller) -> nil;
	DisconnectGamepadConnectionListeners: (self:__gamepad_controller) -> nil;
} & __controller_base
export type gamepad_controller = __keyboard_controller

type __dynamic_thumbstick = {
	moveTouchObject: InputObject?;
	moveTouchLockedIn: boolean;
	moveTouchFirstChanged: boolean;
	moveTouchStartPosition: Vector3?;
	startImage: ImageLabel?;
	endImage: ImageLabel?;
	middleImages: {ImageLabel};
	startImageFadeTween: Tween?;
	endImageFadeTween: Tween?;
	middleImageFadeTweens: {Tween};
	isFirstTouch: boolean;
	thumbstickFrame: Frame?;
	onRenderSteppedConn: RBXScriptConnection?;
	onTouchEndedConn: RBXScriptConnection?;
	fadeInAndOutBalance: number;
	fadeInAndOutHalfDuration: number;
	hasFadedBackgroundInPortrait: boolean;
	hasFadedBackgroundInLandscape: boolean;
	tweenInAlphaStart: number?;
	tweenOutAlphaStart: nil;
	isJumping: boolean?;
	TouchMovedCon: RBXScriptConnection?;
	thumbstickSize: number?;
	thumbstickRingSize: number?;
	middleSize: number?;
	middleSpacing: number?;
	radiusOfDeadZone: number?;
	radiusOfMaxSpeed: number?;
	
	GetIsJumping: (self:__dynamic_thumbstick) -> boolean;
	OnInputEnded: (self:__dynamic_thumbstick) -> nil;
	FadeThumbstick: (self:__dynamic_thumbstick, boolean) -> nil;
	FadeThumbstickFrame: (self:__dynamic_thumbstick, fadeDuration: number, fadeRatio: number) 
		-> nil;
	InputInFrame: (self:__dynamic_thumbstick, InputObject) -> boolean;
	DoFadeInBackground: (self:__dynamic_thumbstick) -> nil;
	DoMove: (self: __dynamic_thumbstick, direction: Vector3) -> nil;
	LayoutMiddleImages: (self:__dynamic_thumbstick, startPos: Vector3, endPos:Vector3) -> nil;
	MoveStick: (self: __dynamic_thumbstick, pos: Vector3) -> nil;
	BindContextActions: (self:__dynamic_thumbstick) -> nil;
	Create: (self:__dynamic_thumbstick, parentFrame:GuiBase2d) -> nil;
	Enable: (self:__touch_jump, is_enabled: boolean, uiParentFrame: Frame) -> boolean;
} & __controller_base
export type dynamic_thumbstick = __dynamic_thumbstick

type __touch_thumbstick = {
	isFollowStick: boolean;
	thumbstickFrame: Frame?;
	moveTouchObject: InputObject?;
	onTouchMovedConn: RBXScriptConnection?;
	onTouchEndedConn: RBXScriptConnection?;
	screenPos: UDim2?;
	stickImage: ImageLabel;
	thumbstickSize: number?;
	
	OnInputEnded: (self: __touch_thumbstick) -> nil;
	Create: (self:__touch_thumbstick, parentFrame: GuiBase2d) -> nil;
	Enable: (self:__touch_jump, is_enabled: boolean, uiParentFrame: Frame) -> boolean;
} & __controller_base
export type touch_thumbstick = __touch_thumbstick

type __endPoint = {
	DisplayModel: Part;
	Destroyed: boolean;
	Tween: Tween;
	ClosestWayPoint: number?
}
export type endPoint = __endPoint

type __clickToMoveDisplay = {
	CreatePathDisplay: (wayPoints: {PathWaypoint}, originalEndWaypoint: Vector3) -> 
		(()->nil,(number)->nil);
	DisplayFailureWaypoint: (position: Vector3) -> nil;
	CreateEndWaypoint: (position: Vector3) -> __endPoint;
	PlayFailureAnimation: () -> nil;
	CancelFailureAnimation: () -> nil;
	SetWaypointTexture: (content:string) -> nil;
	GetWaypointTexture: () -> string;
	SetWaypointRadius: (number) -> nil;
	GetWaypointRadius: () -> number;
	SetEndWaypointTexture: (content: string) -> nil;
	GetEndWaypointTexture: () -> string;
	SetWaypointsAlwaysOnTop: (boolean)->nil;
	GetWaypointsAlwaysOnTop: () -> boolean;
}
export type clickToMoveDisplay = __clickToMoveDisplay

type __clickToMoveController = {
	fingerTouches: {[any]:any};
	numUnsunkTouches: number;
	mouse1Down: number;
	mouse1DownPos: Vector2;
	mouse2DownTime: number;
	mouse2DownPos: Vector2;
	mouse2UpTime: number;
	keyboardMoveVector: Vector3;
	tapConn: RBXScriptConnection?;
	inputBeganConn: RBXScriptConnection?;
	inputChangedConn: RBXScriptConnection?;
	inputEndedConn: RBXScriptConnection?;
	humanoidDiedConn: RBXScriptConnection?;
	characterChildAddedConn: RBXScriptConnection?;
	onCharacterAddedConn: RBXScriptConnection?;
	characterChildRemovedConn: RBXScriptConnection?;
	renderSteppedConn: RBXScriptConnection?;
	menuOpenedConnection: RBXScriptConnection?;
	running: boolean;
	wasdEnabled: boolean;
	touchJumpController: __touch_jump?;
	
	DisconnectEvents: (self: __clickToMoveController) -> nil;
	OnTouchBegan: (self: __clickToMoveController, any, boolean) -> nil;
	OnTouchChanged: (self: __clickToMoveController, any, boolean) -> nil;
	OnTouchEnded: (self: __clickToMoveController, any, boolean) -> nil;
	OnCharacterAdded: (self: __clickToMoveController, Model) -> nil;
	Start: (self:__clickToMoveController) -> nil;
	Stop: (self:__clickToMoveController) -> nil;
	CleanupPath: (self:__clickToMoveController) -> nil;
	Enable: (self:__clickToMoveController, enable: boolean, 
			enableWASD: boolean, __touch_jump) -> nil;
	OnRenderStepped: (self:__clickToMoveController, delta: number) -> nil;
	UpdateMovement: (self:__clickToMoveController, Enum.UserInputState) -> nil;
	UpdateJump: (self:__clickToMoveController) -> nil; -- is not used
	SetShowPath: (self:__clickToMoveController, boolean) -> nil;
	GetShowPath: (self:__clickToMoveController) -> boolean;
	SetWaypointTexture: (self:__clickToMoveController, content: string) -> nil;
	GetWaypointTexture: (self:__clickToMoveController) -> string;
	SetWaypointRadius: (self:__clickToMoveController, radius:number) -> nil;
	GetWaypointRadius: (self:__clickToMoveController) -> number;
	SetEndWaypointTexture: (self:__clickToMoveController, content: string) -> nil;
	GetEndWaypointTexture: (self:__clickToMoveController) -> string;
	SetWaypointsAlwaysOnTop: (self:__clickToMoveController, boolean) -> nil;
	GetWaypointsAlwaysOnTop: (self:__clickToMoveController) -> boolean;
	SetFailureAnimationEnabled: (self:__clickToMoveController, boolean) -> nil;
	GetFailureAnimationEnabled: (self:__clickToMoveController) -> boolean;
	SetIgnoredPartsTag: (self:__clickToMoveController, tag: string) -> nil;
	GetIgnoredPartsTag: (self:__clickToMoveController) -> string;
	-- needs confirmation that this uses a boolean
	SetUseDirectPath: (self:__clickToMoveController, boolean) -> nil;
	-- ditto ^^^
	GetUseDirectPath: (self:__clickToMoveController) -> boolean;
	SetAgentSizeIncreaseFactor: (self:__clickToMoveController, increaseFactorPercent: number) 
		-> nil;
	GetAgentSizeIncreaseFactor: (self:__clickToMoveController) -> number;
	SetUnreachableWaypointTimeout: (self:__clickToMoveController, seconds: number) -> nil;
	GetUnreachableWaypointTimeout: (self:__clickToMoveController) -> number;
	SetUserJumpEnabled: (self:__clickToMoveController, boolean) -> nil;
	GetUserJumpEnabled: (self:__clickToMoveController) -> boolean;
	-- needs check
	MoveTo: (self:__clickToMoveController, pos: Vector3, showPath: boolean, 
		useDirectPath: boolean) -> boolean;
} & __keyboard_controller

type __touch_jump = {
	parentUIFrame: nil;
	jumpButton: ImageButton?;
	characterAddedConn: RBXScriptConnection?;
	humanoidStateEnabledChangedConn: RBXScriptConnection?;
	humanoidJumpPowerConn: RBXScriptConnection?;
	humanoidParentConn: RBXScriptConnection?;
	externallyEnabled: boolean;
	jumpPower: number;
	jumpStateEnabled: boolean;
	isJumping: boolean;
	humanoid: Humanoid?;
	humanoidChangeConn: RBXScriptConnection?;
	
	EnableButton: (self:__touch_jump, boolean) -> nil;
	UpdateEnabled: (self:__touch_jump) -> nil;
	HumanoidChanged: (self:__touch_jump, prop: string) -> nil;
	HumanoidStateEnabledChanged: (self:__touch_jump, Enum.HumanoidStateType, 
		is_enabled: boolean) -> nil;
	CharacterAdded: (self:__touch_jump, char: Model) -> nil;
	SetupCharacterAddedFunction: (self:__touch_jump) -> nil;
	Enable: (self:__touch_jump, is_enabled: boolean, parentFrame: Frame) -> nil;
	Create: (self:__touch_jump) -> nil;
} & __controller_base
export type touch_jump = __touch_jump

type __vc_auto_pilot = {
	MaxSpeed: number;
	MaxSteeringAngle: number
}
export type vc_auto_pilot = __vc_auto_pilot

type __vehicle_controller = {
	CONTROL_ACTION_PRIORITY: number;
	enabled: boolean;
	vehicleSeat: VehicleSeat?;
	throttle: number;
	steer:number;
	acceleration:number;
	decceleration:number;
	turningRight:number;
	turningLeft:number;
	vehicleMoveVector: Vector3;
	autoPilot: __vc_auto_pilot;
	
	BindContextActions:(self:__vehicle_controller) -> nil;
	Enable:(self:__vehicle_controller, enabled: boolean, vehicleSeat:VehicleSeat) -> nil;
	OnThrottleAccel:(self:__vehicle_controller, _: any, inputState:Enum.UserInputState) 
		-> nil;
	OnThrottleDeccel:(self:__vehicle_controller, _: any, inputState:Enum.UserInputState) 
		-> nil;
	OnSteerRight:(self:__vehicle_controller, _: any, inputState:Enum.UserInputState) 
		-> nil;
	OnSteerLeft:(self:__vehicle_controller, _: any, inputState:Enum.UserInputState) 
		-> nil;
	Update:(self:__vehicle_controller, moveVector: Vector3, cameraRelative: boolean,
		usingGamepad: boolean) -> (Vector3, boolean);
	ComputeThrottle: (self:__vehicle_controller, localMoveVector: Vector3) -> number;
	ComputeSteer: (self:__vehicle_controller, localMoveVector: Vector3) -> number;
	SetupAutoPilot: (self:__vehicle_controller) -> nil;
}
export type vehicle_controller = __vehicle_controller

type __controller_module<A> = {
	new: (number) -> A & __controller_base;
	[string]: any;
}
export type controller_module<A> = __controller_module<A>

local module = {}
local PlayerScripts = game:GetService('Players')
	.LocalPlayer
	.PlayerScripts

module.get = function(): __object
	return require(
		assert(
			PlayerScripts:FindFirstChild('PlayerModule')
		)
	)
end

module.waitFor = function(): __object
	return require(PlayerScripts:WaitForChild('PlayerModule',1/0))
end

return module
