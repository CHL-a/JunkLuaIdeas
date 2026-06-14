--[[
	intends to typify startergui
]]

local module = {}


--############################################################################################################################################
--############################################################################################################################################
--############################################################################################################################################

local PromiseTypes = require('@game/ReplicatedStorage/Objects/@CHL>PromiseTypes')
local Promise = PromiseTypes.modified.get()
local Dash = require('@game/ReplicatedStorage/Objects/@CHL>DashSingular')

type promise<T...> = PromiseTypes.modified_object<T...>

service = game:GetService('StarterGui')
compose = Dash.compose

module.core = {}
module.core.get = {}

export type get_core_type = 
	'PointsNotificationsActive' | -- Returns true if player point notifications are enabled.
	'BadgesNotificationsActive' | -- Returns true if badge notifications are enabled.
	'AvatarContextMenuEnabled'  | -- Returns true if the Avatar Context Menu is enabled.
	'ChatActive'                | -- Returns whether the chat is active or not. This is indicated by the selection state of the top bar's 
	                              -- chat icon.
	'ChatWindowSize'            | -- Returns the size of the chat window as a UDim2.
	'ChatBarDisabled'           | -- Returns true if the chat bar is disabled.
	'GetBlockedUserIds'         | -- Returns a list of UserIds associated with users that have been blocked by the local player.
	'PlayerBlockedEvent'        | -- Returns a BindableEvent that is fired whenever a player is blocked by the local player.
	'PlayerUnblockedEvent'      | -- Returns a BindableEvent that is fired whenever a player is unblocked by the local player.
	'PlayerMutedEvent'          | -- Returns a BindableEvent that is fired whenever a player is muted by the local player.
	'PlayerUnmutedEvent'        | -- Returns a BindableEvent that is fired whenever a player is unmuted by the local player.
	'PlayerFriendedEvent'       | -- Returns a BindableEvent that is fired whenever a player is connected by the local player.
	'PlayerUnfriendedEvent'     | -- Returns a BindableEvent that is fired whenever a player is unconnected by the local player.
	'DevConsoleVisible'         | -- Returns true if the Developer Console is visible.
	'VRRotationIntensity'         -- Returns a string describing the camera rotation sensitivity in VR: Low, High and Smooth. This will 
	                              -- not be available unless VRService.VREnabled is true.
--[[
	from:
	https://create.roblox.com/docs/en-us/reference/engine/classes/StarterGui#GetCore"
	
]]
function module.core.get.default_invoke<T>(parameter: get_core_type): T return service:GetCore(parameter) end

module.core.get.default_invoke_promise = Promise.promisify(module.core.get.default_invoke) :: <T>(parameter: get_core_type) -> promise<T>

function invokable_get_core<T...>(parameter: get_core_type)
	return compose(
		function()return parameter end,
		module.core.get.default_invoke_promise
	)
end

module.core.get.points_notifications_active = invokable_get_core('PointsNotificationsActive') :: () -> promise<boolean>
module.core.get.badges_notifications_active = invokable_get_core('BadgesNotificationsActive') :: () -> promise<boolean>
module.core.get.avatar_context_menu_enabled = invokable_get_core('AvatarContextMenuEnabled') :: () -> promise<boolean>
module.core.get.chat_active = invokable_get_core('ChatActive') :: () -> promise<boolean>
module.core.get.chat_window_size = invokable_get_core('ChatWindowSize') :: () -> promise<UDim2>
module.core.get.chat_bar_disabled = invokable_get_core('ChatBarDisabled') :: () -> promise<boolean>
module.core.get.blocked_user_ids = invokable_get_core('GetBlockedUserIds') :: () -> promise<{number}>
module.core.get.player_blocked_event = invokable_get_core('PlayerBlockedEvent') :: () -> promise<BindableEvent>
module.core.get.player_unblocked_event = invokable_get_core('PlayerUnblockedEvent') :: () -> promise<BindableEvent>
module.core.get.player_muted_event = invokable_get_core('PlayerMutedEvent') :: () -> promise<BindableEvent>
module.core.get.player_unmuted_event = invokable_get_core('PlayerUnmutedEvent') :: () -> promise<BindableEvent>
module.core.get.player_friended_event = invokable_get_core('PlayerFriendedEvent') :: () -> promise<BindableEvent>
module.core.get.player_unfriended_event = invokable_get_core('PlayerUnfriendedEvent') :: () -> promise<BindableEvent>
module.core.get.dev_console_visible = invokable_get_core('DevConsoleVisible') :: () -> promise<boolean>
module.core.get.vr_rotation_intensity = invokable_get_core('VRRotationIntensity') :: () -> promise<string>

--############################################################################################################################################
--############################################################################################################################################
--############################################################################################################################################

export type set_core_type = 
	'ChatActive'                    |
	'PointsNotificationsActive'     |
	'BadgesNotificationsActive'     |
	'ResetButtonCallback'           |
	'ChatMakeSystemMessage'         |
	'SendNotification'              |
	'TopbarEnabled'                 |
	'DevConsoleVisible'             |
	'PromptSendFriendRequest'       |
	'PromptUnfriend'                |
	'PromptBlockPlayer'             |
	'PromptUnblockPlayer'           |
	'AvatarContextMenuEnabled'      |
	'AvatarContextMenuTarget'       |
	'AddAvatarContextMenuOption'    |
	'RemoveAvatarContextMenuOption' |
	'AvatarContextMenuTheme'        |
	'CoreGuiChatConnections'

module.core.set = {}

function module.core.set.default_invoke<T>(set_core_type: set_core_type, arg: T) service:SetCore(set_core_type, arg) end

function invokable_set_core<T...>(parameter: set_core_type)
	return compose(
		function()return parameter end,
		module.core.set.default_invoke
	)
end

module.core.set.chat_active = invokable_set_core('ChatActive') :: (boolean) -> ()
module.core.set.points_notifications_active = invokable_set_core('PointsNotificationsActive') :: (boolean) -> ()
module.core.set.badges_notifications_active = invokable_set_core('BadgesNotificationsActive') :: (boolean) -> ()
module.core.set.reset_button_callback = invokable_set_core('ResetButtonCallback') :: (boolean | BindableEvent) -> ()

export type legacy_system_message = {
	Text: string,
	Color: Color3?,
	Font: Enum.Font?,
	TextSize: number?,
}

module.core.set.chat_make_system_message = invokable_set_core('ChatMakeSystemMessage') :: (legacy_system_message) -> ()

export type notification = {
	Title: string,
	Text: string,
	Icon: string?,
	Duration: number?,
	Callback: BindableFunction?,
	Button1: string?,
	Button2: string?,
}

module.core.set.send_notification = invokable_set_core('SendNotification') :: (notification) -> ()

module.core.set.topbar_enabled = invokable_set_core('TopbarEnabled') :: (boolean) -> ()
module.core.set.devconsole_visible = invokable_set_core('DevConsoleVisible') :: (boolean) -> ()
module.core.set.prompt_send_friend_request = invokable_set_core('PromptSendFriendRequest') :: (Player) -> ()
module.core.set.prompt_unfriend = invokable_set_core('PromptUnfriend') :: (Player) -> ()
module.core.set.prompt_block_player = invokable_set_core('PromptBlockPlayer') :: (Player) -> ()
module.core.set.prompt_unblock_player = invokable_set_core('PromptUnblockPlayer') :: (Player) -> ()
module.core.set.avatar_context_menu_enabled = invokable_set_core('AvatarContextMenuEnabled') :: (boolean) -> ()
module.core.set.avatar_context_menu_target = invokable_set_core('AvatarContextMenuTarget') :: (Player?) -> ()
module.core.set.add_avatar_context_menu_option = invokable_set_core('AddAvatarContextMenuOption') 
	:: (Enum.AvatarContextMenuOption | {any}) -> ()
module.core.set.remove_avatar_context_menu_option=invokable_set_core('RemoveAvatarContextMenuOption') 
	:: (string|Enum.AvatarContextMenuOption)->()

export type avatar_context_menu_theme = {
	BackgroundColor: Color3?;
	BackgroundTransparency: number?;
	BackgroundImage: string?;
	BackgroundImageTransparency: number?;
	BackgroundImageScaleType: Enum.ScaleType?;
	BackgroundImageSliceCenter: Rect?;

	NameTagColor: Color3?;
	NameUnderlineColor: Color3?;

	ButtonFrameColor: Color3?;
	ButtonFrameTransparency: number?;

	ButtonColor: Color3?;
	ButtonTransparency: number?;
	ButtonHoverColor: Color3?;
	ButtonHoverTransparency: number?;
	ButtonUnderlineColor: Color3?;
	ButtonImage: string?;
	ButtonImageScaleType: Enum.ScaleType?;
	ButtonImageSliceCenter: Rect?;

	Font: Enum.Font?;
	TextColor: Color3?;
	TextScale: number?;

	LeaveMenuImage: string?;
	ScrollLeftImage: string?;
	ScrollRightImage: string?;

	SelectedCharacterIndicator: MeshPart?;
	Size: UDim2?;
	MinSize: Vector2?;
	MaxSize: Vector2?;
	AspectRatio: number?;
	AnchorPoint: Vector2?;
	OnScreenPosition: UDim2?;
	OffScreenPosition: UDim2?;
}

module.core.set.avatar_context_menu_theme = invokable_set_core('AvatarContextMenuTheme') :: (avatar_context_menu_theme) -> ()

module.core.set.core_gui_chat_connections = invokable_set_core('CoreGuiChatConnections') :: <T>(T) -> ()

--############################################################################################################################################
--############################################################################################################################################
--############################################################################################################################################

module.core.notification = {}

module.core.notification.send = module.core.set.send_notification

--############################################################################################################################################
--############################################################################################################################################
--############################################################################################################################################

module.core.avatar_context_menu = {}

module.core.avatar_context_menu.enable = module.core.set.avatar_context_menu_enabled
module.core.avatar_context_menu.is_enabled = module.core.get.is_avatar_context_menu_enabled
module.core.avatar_context_menu.use_onto = module.core.set.avatar_context_menu_target
module.core.avatar_context_menu.add_blind_option = module.core.set.add_avatar_context_menu_option
module.core.avatar_context_menu.remove_option = module.core.set.remove_avatar_context_menu_option

--[[
	Non blind version where parameters are specific
]]
function module.core.avatar_context_menu.add_option(id: string, bindable_event: BindableEvent)
	module.core.avatar_context_menu.add_blind_option({id, bindable_event})
end

module.core.avatar_context_menu.set_theme = module.core.set.avatar_context_menu_theme


--############################################################################################################################################
--############################################################################################################################################
--############################################################################################################################################

module.service = service

return module
