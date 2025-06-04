local Objects = script.Parent
local Map = require('./@CHL>Map')
local LuaUTypes = require('./LuaUTypes')

type empty = typeof(LuaUTypes.empty)

export type GUIElement<A> = {
	Arguments: A;
	Parent: GUIElement<A>?
}

type module_base<Object, Args> = {
	new: (Args, GUIElement<any>)->Object;
}

--#############################################################################################
--#############################################################################################
--#############################################################################################

-- Objects
export type GUIObject<A> = {
	Object: GuiObject;
	MainMovable: GuiObject;
	
	Move: (self: GUIObject<A>, new: GuiObject, with: GuiObject)->();
} & GUIElement<A>
export type GUIObject_module<A> = module_base<GUIObject<A>, A>;

--[[
	Denotes button from simple click
--]]
export type Button_args = {
	Textbox: Textbox_rgl?;
	Text: string?;
	Disabled: boolean;
	ButtonSize: legitimate_scale_args;
}
export type Button = {
	TextboxTable: Textbox_rgl;
	ButtonFrame: Frame;
	Button: ImageButton;
	ButtonBackground: ImageLabel;
	Toggleable: boolean;
	CursorIcon: string;
	
	SetDisabled: (self: Button, isDisabled: boolean)->();
	ToggleDisable: (self: Button)->();
	Clicked: (self: Button, f: empty)->();
	Released: (self: Button, f: empty)->();
} & GUIObject<Button_args>
export type Button_module = module_base<Button, Button_args>

export type Checkbox_args = {
	Value: boolean;
	Disabled: boolean;
}
export type CheckBox = {
	Value: boolean;
	CursorIcon: string;
	Disabled: boolean;
	CheckboxFrame: Frame;
	Checkbox: TextButton;
	CheckImage: ImageLabel;
	
	SetDisabled: (self:CheckBox, isDisabled: boolean)->();
	ToggleDisable: (self: CheckBox)->();
	Toggle: (self: CheckBox)->();
	SetValue: (self: CheckBox, boolean)->();
	Clicked: (self: CheckBox, empty)->();
} & GUIObject<Checkbox_args>
export type CheckBox_module = module_base<CheckBox, Checkbox_args>

export type ColorInput_args = {
	Disabled: boolean;
	Color: Color3?;
	Value: Color3?;
	NoPause: boolean;
}
export type ColorInput = {
	CursorIcon: string;
	IgnoreText: boolean;
	Disabled: boolean;
	ColorInputContainer: Frame;
	ColorInputFrame: Frame;
	ColorInputLayout: UIListLayout;
	ColorButton: TextButton;
	DefaultValue: Color3;
	ColorInput: InputField;
	Value: Color3;
	Action: ((Color3)->())?;
	
	SetDisable: (self: ColorInput, isDisabled: boolean)->();
	ToggleDisable: (self: ColorInput)->();
	SetValue: (self: ColorInput, v: Color3, IgnoreText:boolean?)->();
	Changed: (self: ColorInput, (Color3)->())->();
} & GUIObject<ColorInput_args>
export type ColorInput_module = module_base<ColorInput, ColorInput_args>

-- treat as multiple choice, radio type input
export type InputField_args = {
	NoFiltering: boolean?;
	InputSize: legitimate_scale_args;
	ClearBackground: boolean;
	NoDropdown: boolean?;
	DisableEditing: boolean?;
	Placeholder: string;
	Value: any;
	CurrentItem: any;
	Items: {any};
}
export type InputField = {
	MouseInDropdownButton: boolean;
	MouseInDropdownMenu: boolean;
	DropdownFrame: Frame;
	DropdownImage: ImageLabel;
	DropdownButton: TextButton;
	MouseInInput:boolean;
	Focusable: boolean;
	TextEditable: boolean;
	Input: TextBox;
	Disabled: boolean;
	DropdownOpen: boolean;
	SelectedItem: boolean;
	Value: any;
	DefaultEmpty: string;
	Action: ((any)->())?;
	ItemEnterAction: ((any)->())?;
	ItemLeaveAction: ((any)->())?;
	DropdownAction: ((any)->())?;
	LostFocusAction: ((any)->())?;
	FocusedAction: ((any)->())?;
	Filtering: boolean;
	InputFieldContainer: Frame;
	InputFieldFrame: Frame;
	DropdownScroll: ScrollingFrame_rgl;
	DropdownMaxY: number;
	
	SetDisabled: (self: InputField, boolean)->();
	ToggleDisable: (self: InputField)->();
	ToggleDropdown: (self: InputField)->();
	SetDropdown: (self: InputField, boolean)->();
	AddItem: (self: InputField, any, empty?)->();
	AddItems: (self: InputField, {any}, empty?)->();
	ClearItems: (self: InputField)->();
	RemoveItem: (self: InputField, any)->();
	RemoveItems: (self: InputField, {any})->();
	SetValue: (self: InputField, any)->();
	Changed: (self: InputField, (any)->())->();
	MouseEnterItem: (self: InputField, (any)->())->();
	MouseLeaveItem: (self: InputField, (any)->())->();
	DropdownToggled: (self: InputField, (any)->())->();
	LostFocus: (self: InputField, (any)->())->();
	GainedFocus: (self: InputField, (any)->())->();
} & GUIObject<InputField_args>
export type InputField_module = {
	GenerateInstanceList: (Instance | {Instance})->string;
	GetItemInfo: (any)->{
		Value: any;
		Name: any;
	}
} & module_base<InputField, InputField_args>

export type InstanceInputField_args = {
	Placeholder: string?;
} & InputField_args
export type InstanceInputField = {
	IgnoreText: boolean;
	DefaultEmpty: {};
} & InputField;
export type InstanceInputField_module = module_base<InstanceInputField, InstanceInputField_args>

export type KeybindInputField_args = {
	Placeholder: string?;
	Holdable: boolean?;
	Binds: any?;
	Items: any?;
	Bind: any?;
	CurrentBind: any?;
} & InputField_args
export type KeybindInputField = {
	IgnoreText: boolean;
	Holdable: boolean;
	Unrestricted: boolean;
	DefaultEmpty: {{}};
	ID: number;
	Focused: boolean;
	
	UpdateValues: (self: KeybindInputField, any)->();
	UpdateBind: (self: KeybindInputField, any)->();
	SetBind: (self: KeybindInputField, any?)->();
	AddBind: (self: KeybindInputField, any)->();
	AddBinds: (self: KeybindInputField, {any})->();
	EditKeybind: (self: KeybindInputField, any, boolean?)->();
	RemoveKeybind: (self: KeybindInputField, number)->();
	UnfocusInputField: (self: KeybindInputField, boolean?)->();
	Pressed: (self: KeybindInputField, empty)->();
	Released: (self: KeybindInputField, empty)->();
} & InputField
export type KeybindInputField_module = module_base<KeybindInputField, KeybindInputField_args>

--[[
	Textlabel for any interactable
--]]
export type Labeled_args_Object_entry = {
	Object: GUIObject<any>;
	Name: string;
	Size: legitimate_scale_args?;
}
export type Labeled_args = {
	Textbox: Textbox_rgl?;
	Text: string?;
	LabelSize: legitimate_scale_args?;
	Objects: {Labeled_args_Object_entry};
	Object: Labeled_args_Object_entry;
	Disabled: boolean;
}
export type Labeled = {
	Disabled: boolean;
	Objects: {GUIObject<any>};
	TotalUsedScale: number;
	TotalUsedOffset: number;
	MainFrame: Frame;
	MainLayout: UIListLayout;
	MainPadding: UIPadding;
	Label: TextBox;
	Content: Frame;
	-- TextboxTable: tbmod
	
	SetDisabled: (self: Labeled, boolean)->();
	ToggleDisable: (self: Labeled)->();
	AddObject: (self: Labeled, GUIObject<any>, string,legitimate_scale_args?)->();
	
} & GUIObject<Labeled_args>
export type Labeled_module = module_base<Labeled, Labeled_args>

export type ProgressBar_args = {
	BarSize: legitimate_scale_args?;
	Disabled: boolean?;
	Value: number;
}
export type ProgressBar = {
	Disabled: boolean;
	ProgressBarContainer: Frame;
	ProgressBar: Frame;
	ProgressIndicator: Frame;
	
	SetDisabled: (self: ProgressBar, boolean)->();
	ToggleDisable: (self: ProgressBar)->();
	SetValue: (self: ProgressBar, number)->();
} & GUIObject<ProgressBar_args>
export type ProgressBar_module = module_base<ProgressBar, ProgressBar_args>

export type Slider_args = {
	Increment: number?;
	Value: number?;
	Min: number;
	Max: number;
	SliderSize: legitimate_scale_args?;
	Disabled: boolean;
}
export type Slider = {
	Disabled: boolean;
	CursorIcon: string;
	Value: number;
	Min: number;
	Max: number;
	PreviousValue: number;
	Action: ((number)->())?;
	PressedAction: empty?;
	ReleasedAction: empty?;
	Increment: number;
	SliderFrame: Frame;
	SlideBar: Frame;
	SlideButton: TextButton;
	SliderSelected: boolean;
	InitialX: number;
	
	Released: (self: Slider, empty)->();
	Pressed: (self: Slider, empty)->();
	Changed: (self: Slider, (number)->())->();
	ToggleDisable: (self: Slider)->();
	UpdatePosition: (self: Slider)->();
	SetRange: (self: Slider, min: number, max: number)->();
	SetValue: (self: Slider, number)->();
	SetDisabled: (self: Slider, boolean)->()
} & GUIObject<Slider_args>
export type Slider_module = module_base<Slider, Slider_args>

export type Textbox_args = {
	Alignment: Enum.TextXAlignment?;
	Font: Enum.Font?;
	TextSize: number?;
	FontSize: number?;
	Text: string;
}
export type Textbox_rgl = {
	Textbox: TextLabel;
} & GUIObject<Textbox_args>
export type Textbox_module = module_base<Textbox_rgl, Textbox_args>

--[[
	Button sharing the same row as pages, invokes options and can have serveral suboptions 
	via `plugin:CreatePluginMenu`
--]]
export type TitleBarButton_args = {
	Name: string;
	PluginMenu: PluginMenu;
	TabSize: number;
	Disabled: boolean;
}
export type TitleBarButton = {
	Disabled: boolean;
	CursorIcon: string;
	Action: empty?;
	PluginMenu: PluginMenu;
	TitleBarMenuSelectedAction: (PluginAction)->();
	Name: string;
	TabSize: number;
	Buttons: {TextButton};
	
	CreateCopy: (self: TitleBarButton, any)->();
	SelectedAction: (self: TitleBarButton, f: (PluginAction)->())->();
	Clicked: (self: TitleBarButton, empty)->();
	ToggleDisable: (self: TitleBarButton)->();
	SetDisabled: (self: TitleBarButton, boolean)->();
} & GUIObject<TitleBarButton_args>
export type TitleBarButton_module = module_base<TitleBarButton, TitleBarButton_args>

export type ToggleableButton_args = Button_args;
export type ToggleableButton = {
	Value: boolean;
	Toggleable: boolean;
	
	SetValue: (self: ToggleableButton, boolean)->();
	Toggle: (self: ToggleableButton)->boolean;
	Update: (self: ToggleableButton)->();
} & Button
export type ToggleableButton_module = module_base<ToggleableButton, ToggleableButton_args>

export type ViewButton_args = TitleBarButton_args
export type ViewButton = {
	PluginMenu: PluginMenu;
	LayoutsMenu: PluginMenu;
	WidgetsMenu: PluginMenu;
	ThemesMenu: PluginMenu;
	
	RefreshMenu: (self: ViewButton)->();
	LoadWidgetOption: (self: ViewButton, any, any)->PluginMenu;
	CreateThemeEditor: (self: ViewButton, (string)->())->();
	LoadLayoutOption: (self: ViewButton, any, any)->PluginMenu;
	LoadThemeOption: (self: ViewButton, any, any)->PluginMenu;
	CreateMenu: (self: ViewButton)->();
} & TitleBarButton
export type ViewButton_module = module_base<ViewButton, ViewButton_args>
--#############################################################################################
--#############################################################################################
--#############################################################################################

export type GUIFrame<C, A> = {
	Content: C?;
	
	SetMain: (self: GUIFrame<C, A>) ->();
} & GUIElement<A>
export type GUIFrame_module = module_base<GUIFrame<any, any>, any>

export type BackgroundFrame = GUIFrame<Frame, {}>
export type BackgroundFrame_module = module_base<BackgroundFrame, {}>

export type ListFrame_args = {
	Height: number?;
	Name: string?
}
export type ListFrame = {
	Layout: UIGridLayout;
	Padding: UIPadding;
} & GUIFrame<Frame, ListFrame_args>
export type ListFrame_module = module_base<ListFrame, ListFrame_args>

--[[
	Page used for secondary ui storage, can be referred to as a tab.
--]]
export type PageFrame_args = {
	ID: string?;
	Name: string?;
}
export type PageFrame = {
	TitleBarMenu: TitleBarMenu;
	ID: string;
	TabFrame: Frame;
	Tab: TextButton;
	InsideWidget: boolean;
	TabDragging: boolean;
	InitialX: number;
	TopBorder: Frame;
	LeftBorder: Frame;
	RightBorder: Frame;
	Open: boolean;
	
	State: (self: PageFrame, boolean)->()
} & GUIFrame<Frame, PageFrame_args>
export type PageFrame_module = module_base<PageFrame, PageFrame_args>

--[[
	Primary widget for creating a roblox window.
	
	Can have it's own tabs, prompting options via `plugin:CreatePluginMenu`, atm, idk how to change the title
--]]
export type PluginWidget_args = {
	ID: string?;
	DockState: Enum.InitialDockState;
	Enabled: boolean?;
	Title: string?;
	OverrideRestore: boolean?;
	NoTitleBarMenu: boolean?;
}
export type PluginWidget = {
	ID: string;
	WidgetObject: DockWidgetPluginGui;
	BackgroundFrame: BackgroundFrame;
	InputFrame: Frame;
	TitleBarMenu: TitleBarMenu;
	Index: number;
	
	Delete: (self: PluginWidget)->();
	Rename: (self: PluginWidget)->();
} & GUIFrame<DockWidgetPluginGui, PluginWidget_args>
export type PluginWidget_module = module_base<PluginWidget, PluginWidget_args>

export type ScrollingFrame_args = {
	BarSize: number?;
}
export type ScrollingFrame_rgl = {
	ScrollbarBackground: Frame;
	Layout: UIListLayout;
	
	UpdateFrameSize: (self: ScrollingFrame_rgl)->();
} & GUIFrame<ScrollingFrame, ScrollingFrame_args>
export type ScrollingFrame_module = module_base<ScrollingFrame_rgl, ScrollingFrame_args>

--[[
	Denotes a collapsable section
--]]
export type Section_args = {
	Open: boolean;
	TextBox: Textbox_rgl?;
	Text: string;
}
export type Section = {
	Open: boolean;
	Collapse: Frame;
	CollapseLayout: UIListLayout;
	Label: TextButton;
	LabelLayout: UIListLayout;
	LabelFrame: Frame;
	CollapseImageFrame: Frame;
	CollapseTextboxFrame: Frame;
	CollapseImage: ImageLabel;
	TextboxTable: Textbox_rgl;
	Textbox: TextLabel;
	Layout: UIListLayout;
	
	SetState: (self: Section, boolean)->();
	Toggle: (self: Section)->();
} & GUIFrame<Frame, Section_args>
export type Section_module = module_base<Section, Section_args>

export type TitleBarMenu_args = {
	ID: string?;
}
export type TitleBarMenu = {
	Pages: {any};
	TitlebarMenu: Frame;
	ButtonsFrame: Frame;
	ButtonContainer: Frame;
	ScrollingMenu: ScrollingFrame;
	TabContainer: Frame;
	ContentContainers: Frame;
	
	BeingDragged: (self: TitleBarMenu, string)->();
	MovePage: (self: TitleBarMenu, string, number, string)->();
	FixPageLayout: (self: TitleBarMenu, string)->();
	SetActive: (self: TitleBarMenu, string)->();
	RemovePage: (self: TitleBarMenu, page: any)->();
	AddPage: (self: TitleBarMenu, page: any)->();
	RecievePage: (self: TitleBarMenu, page: any)->();
	GetIDIndex: (self: TitleBarMenu, string)->number?;
	GetIDTab: (self: TitleBarMenu, string)->any?;
} & GUIFrame<GUIElement<any>, TitleBarMenu_args>
export type TitleBarMenu_module = module_base<TitleBarMenu, TitleBarMenu_args>

--#############################################################################################
--#############################################################################################
--#############################################################################################

-- prompts

--[[
	Direct prompt invoke by construction, invokes a dedicated window
--]]
export type Prompt_args = {
	NoPause: boolean?;
	Title: string?;
	Width: number?;
	Height: number?;
}
export type Prompt = {
	CloseAction: empty;
	Resetting: boolean;
	Widget: DockWidgetPluginGui;
	
	Reset: (self: Prompt, title: string?, width: number?, height: number?)->();
	Destroy: (self: Prompt)->();
	OnWindowClose: (self: Prompt, empty) -> ();
} & GUIElement<Prompt_args>
export type Prompt_module = module_base<Prompt, Prompt_args>

export type ColorPrompt_args = Prompt_args
export type ColorPrompt = {
	Value: Color3;
	HSVValue: {H: number, S: number, V: number};
	ChangedAction: ((Color3)->())?;
	ColorComponents: Frame;
	ColorPalate: Frame;
	ColorGraidentFrame: Frame;
	ColorGradient: UIGradient;
	LightnessGradientFrame: Frame;
	LightnessGradient: UIGradient;
	PalateIndicator: ImageLabel;
	HueGradientFrame: Frame;
	HueGradient: UIGradient;
	LeftHueIndicator: ImageLabel;
	RightHueIndicator: ImageLabel;
	ColorPickerOptions: Frame;
	ColorPreview: Frame;
	RGBInput: InputField;
	HexInput: InputField;
	OKButton: Button;
	CancelButton: Button;
	OriginalValue: Color3;
	
	UpdatePreview: (self: ColorPrompt)->();
	SetPalatePos: (self: ColorPrompt, x: number, y: number)->();
	SetHuePos: (self: ColorPrompt, number)->();
	SetValue: (self: ColorPrompt, value: Color3?, ignoreText: boolean?, ignoreHSV: boolean?)->();
	Changed: (self: ColorPrompt, (Color3)->())->();
	Done: (self: ColorPrompt, (Color3)->())->();
}
export type ColorPrompt_module = module_base<ColorPrompt, ColorInput_args>

export type InputPrompt_args = {
	InputField: InputField?;
	Input: string?;
} & TextPrompt_args
export type InputPrompt = {
	Input: TextBox;
} & TextPrompt
export type InputPrompt_module = module_base<InputPrompt, InputPrompt_args>

export type TextPrompt_args = {
	Buttons: {string}?;
	Textbox: Textbox_rgl?;
	Text: string?;
	
} & Prompt_args
export type TextPrompt = {
	Action: ((number)->())?;
	TextPromptContainer: Frame;
	TextPromptLayout: UIListLayout;
	TextFrame: Frame;
	TextboxTable: Textbox_rgl;
	Textbox: TextLabel;
	ButtonsFrame: Frame;
	ButtonsFrameLayout: UIListLayout;
	
	Clicked: (self: TextPrompt, (number)->())->();
} & Prompt
export type TextPrompt_module = module_base<TextPrompt, TextPrompt_args>

--#############################################################################################
--#############################################################################################
--#############################################################################################

-- modules
type color3_operation = (c1: Color3, c2: Color3)->Color3;
type color3_table = {R:number;G:number;B:number};

export type legitimate_scale_args = UDim | number

export type GUIUtil = {
	AppendTable: <A, B>(A, B)->A;
	DumpTable: <A>(A, step: number?)->string;
	HoverIcon: (element: GuiObject, icon: string?)->();
	CopyTable: typeof(table.clone);
	GetScale: (Scale: legitimate_scale_args) -> UDim?;
	RoundNumber: (n: number, f: number)->number;
	PauseAll: ()->();
	UnpauseAll: ()->();
	AddColor: color3_operation;
	SubColor: color3_operation;
	MulitplyColor: color3_operation;
	Color3ToText: (Color3)->string;
	TextToColor3: (string)->Color3;
	Color3ToTable: (Color3)->color3_table;
	TableToColor3: (color3_table)->Color3;
}

--#############################################################################################
--#############################################################################################
--#############################################################################################

export type library = {
	Button: Button_module;
	Checkbox: CheckBox_module;
	ColorInput: ColorInput_module;
	GUIObject: GUIObject_module<any>;
	InputField: InputField_module;
	InstanceInputField: InstanceInputField_module;
	KeybindInputField: KeybindInputField_module;
	Labeled: Labeled_module;
	ProgressBar: ProgressBar_module;
	Slider: Slider_module;
	TextBox: Textbox_module;
	TitleBarButton: TitleBarButton_module;
	ToggleableButton: ToggleableButton_module;
	ViewButton: ViewButton_module;
	
	GUIUtil: GUIUtil;
	
	BackgroundFrame: BackgroundFrame_module;
	GUIFrame: GUIFrame_module;
	ListFrame: ListFrame_module;
	Page: PageFrame_module;
	PluginWidget: PluginWidget_module;
	ScrollingFrame: ScrollingFrame_module;
	Section: Section_module;
	TitleBarMenu: TitleBarMenu_module;
	
	Prompt: Prompt_module;
	InputPrompt: InputPrompt_module;
	ColorPrompt: ColorPrompt_module;
	TextPrompt: TextPrompt_module;
}
export type initialize = (Plugin, id: string)->library


--#############################################################################################
--#############################################################################################
--#############################################################################################

local module = {}

function module.get(): initialize
	local dep = script.Parent:FindFirstChild('@arch4ic>rblxguilib')
	assert(dep,'Attempting to use get function without installing dependency.')
	return require(dep.rblxgui.initialize)
end

return module
