local LuaUTypes = require('./LuaUTypes')
local Map = require('./@CHL>Map')

type empty = ()->()
type dict<T> = Map.dictionary<T>

export type module = (string) -> (any)

export type rbxgui_button = {
	Style: Enum.ButtonStyle?;
	ZIndex: number?;
	Text: string;
	Function: ()->();
}

export type rbxgui_dropdown = {
	Frame: Frame;
	CurrentSelectionButton: TextButton;
	
	IsOpen: ()->boolean;
	Close: empty;
	Reset: empty;
	SetVisible: (boolean)->();
	UpdateZIndex: (number)->();
	SetActive: (boolean)->();
	SetSelectionText: (string)->();
	CreateList: (list: {string})->();
}

export type rbxgui_tutorial = Frame & {
	TransitionFrame: Frame;
	CurrentTutorialPage: ObjectValue;
	Buttons: BoolValue;
	Pages: Frame
}

export type rbxgui_tutorial_page = Frame & {
	Header: TextLabel,
	SkipButton: TextButton;
	DoneButton: TextButton;
	ContentFrame: Frame;
	NextButton: TextButton;
	PrevButton: TextButton
}

export type rbxgui_control_frame = Frame & {
	ScrollBottom: BoolValue;
	scrollUp: BoolValue;
	ScrollUpButton: TextButton;
	scrollDownButton: TextButton;
	ScrollTrack: Frame & {
		ScrollBar: TextButton & {
			ScrollNub: Frame;
		}
	};
};

export type rbxgui_true_scrolling_frame = ScrollingFrame & {
	ControlFrame: rbxgui_control_frame
}

export type rbxgui = {
	CreateStyledMessageDialog: (
		title: string, 
		message: string,
		style: 'error' | 'Error' | 
			'notify' | 'Notify' | 
			'confirm' | 'Confirm',
		buttons: {rbxgui_button}
	) -> Frame & {
		StyleImage: ImageLabel;
		Title: TextLabel;
		Message: TextLabel
	};
	
	CreateMessageDialog: (
		title: string,
		message: string,
		buttons: {rbxgui_button}
	)-> Frame & {
		Title: TextLabel;
		Message: TextLabel;
	};
	
	CreateScrollingDropDownMenu: (
		onSelectedCallback: (string)->(),
		size: UDim2,
		position: UDim2,
		baseZ: number?
	)->rbxgui_dropdown;
	
	CreateDropDownMenu: (
		items: {string}, 
		onSelect: (string)->(),
		forRoblox: boolean?,
		whiteSkin: boolean?,
		baseZ: number?
	)->(
		Frame & {
			DropDownMenuButton: TextButton & {
				Icon: ImageLabel
			};
			List: TextButton;
		},
		(string)->()
	);
	
	CreatePropertyDropDownMenu: (
		instance: Instance,
		property: string,
		enum: Enum
	)->Frame & {
		DropDownMenuButton: TextButton & {
			Icon: ImageLabel
		};
		List: TextButton;
	};
	
	GetFontHeight: (font: Enum.Font, fontSize: Enum.FontSize)->number;
	
	LayoutGuiObjects: (
		frame: Frame,
		guiObjects: {GuiObject},
		settingsTable: {
			TextLabelSizePadY: number?;
			TextLabelPositionPadY: number?;
			TextButtonSizePadY: number?;
			TextButtonPositionPadY: number?;
		}?
	)->();
	
	CreateSlider: (
		steps: number,
		width: number?,
		position: {
			X: {
				Scale: number?;
				Offset: number?;
			}?;
			Y: {
				Scale: number?;
				Offset: number?;
			}?
		}?
	)->(
		Frame & {
			SliderSteps: IntValue;
			SliderPosition: IntValue;
			Bar: TextButton & {
				Slider: ImageButton
			};
		},
		IntValue,
		IntValue
	);
	
	CreateSliderNew: (
		steps: number,
		width: number?,
		position: {
			X: {
				Scale: number?;
				Offset: number?;
			}?;
			Y: {
				Scale: number?;
				Offset: number?;
			}?
		}?
	)->(
		Frame & {
			SliderSteps: IntValue;
			SliderPosition: IntValue;
			Bar: TextButton & {
				Slider: ImageButton
			};
			BarLeft: TextButton;
			BarRight: TextButton;
			FillLeft: TextButton;
			Fill: TextButton;
		},
		IntValue,
		IntValue
	);
	
	CreateTrueScrollingFrame: ()->(
		rbxgui_true_scrolling_frame,
		rbxgui_control_frame
	);
	
	CreateScrollingFrame: (orderList: {Instance}, scrollStyle: any?)->(
		ScrollingFrame, 
		ImageButton, 
		ImageButton, 
		empty,
		ImageButton & {ScrollDrag: ImageButton}
	);
	
	AutoTruncateTextObject: (textLabel: TextLabel)->(TextLabel, (string)->());
	
	CreateTutorial: (
		name: string, 
		tutorialKey: string, 
		createButtons: boolean
	)->(
		rbxgui_tutorial_page,
		(boolean)->(),
		empty,
		(number)->()
	);
	
	CreateTextTutorialPage: (
		name: string, 
		text: string, 
		skipTutorial: empty?
	)->(rbxgui_tutorial, Frame),
	
	CreateImageTutorialPage: (
		name: string, 
		imageAsset: string,
		x: number,
		y: number,
		skipTutorial: empty?,
		giveDoneButton: boolean?
	)->rbxgui_tutorial,
	
	AddTutorialPage: (
		tutorial: rbxgui_tutorial, 
		tutorialPage: rbxgui_tutorial_page
	)->();
	
	CreateSetPanel: (
		userIdsForSets: {number}, 
		objectSelected: (string, number, shape: number)->(),
		dialogClosed: empty?,
		size: UDim2?,
		position: UDim2?,
		showAdminCategories: boolean?,
		useAssetVersionId: boolean?
	)->(
		ScreenGui & {
			SetPanel: Frame & {
				ItemPreview: Frame & {
					TextPanel: Frame & {
						RolloverText: TextLabel
					};
					LargePreview: ImageLabel;
				},
				Sets: Frame & {
					Line: Frame,
					SetsLists: rbxgui_true_scrolling_frame;
					SetsHeader: TextLabel
				};
				CancelButton: TextButton & {
					CancelImage: ImageLabel
				}
			}
		},
		(boolean)->(),
		(boolean)->boolean,
		BindableEvent
	);
	
	CreateTerrainMaterialSelector: (size: UDim2?, position: UDim2?)->(
		Frame & {
			TerrainMaterialSelectionChanged: BindableEvent;
			ScrollingFrame: ScrollingFrame, 
			ScrollUpButton: ImageButton, 
			ScrollDownButton: ImageButton, 
		},
		BindableEvent,
		(mat: Enum.Material)->()
	);
	
	CreateLoadingFrame: (name: string, size: UDim2?, position: UDim2?)->(
		Frame & {
			LoadingBar: Frame & {
				LoadingGreenBar: ImageLabel;
				LoadingPercent: TextLabel
			};
			CancelButton: TextButton & {
				CancelButtonClicked: BindableEvent
			};
			loadingName: TextLabel;
		},
		(
			percent: number, 
			tweenAction: boolean?,
			tweenLength: number?
		)->(),
		BindableEvent
	);
	
	CreatePluginFrame: (
		name: any, 
		size: UDim2?, 
		position: UDim2?, 
		scrollable: boolean,
		parent: Instance
	)->(
		Frame & {
			BarNameLabel: TextLabel;
			CloseButton: TextButton & {
				CloseEvent: BindableEvent
			};
			HelpButton: TextButton;
			HelpFrame: Frame;
			MinimizeButton: TextButton;
			MinimizeFrame: Frame & {
				MinimizeButton: TextButton
			};
			SeparatingLine: Frame;
			WidgetContainer: Frame & {
				ScrollingFrame: rbxgui_true_scrolling_frame;
				VerticalDragger: TextButton & {
					VerticalDragger: TextButton & {
						ScrubFrame: Frame
					}
				}
			};
			ControlFrame: rbxgui_control_frame & {
				FakeLine: Frame;
			}
		},
		rbxgui_true_scrolling_frame | Frame,
		Frame,
		BindableEvent
	),
	
	Help: (name_or_func: string | <A..., B...>(A...)->B...)->string?;
}

export type rbxstamper_control = {
	Stamped: BoolValue;
	Paused: boolean;
	
	LoadNewModel: (Model)->();
	ReloadModel: empty;
	Pause: empty;
	Resume: empty;
	ResetRotation: empty;
	Destroy: empty;

}

export type rbxstamper = {
	CanEditRegion: (inst: BasePart | Model)->(boolean, boolean);
	
	GetStampModel: (
		asset: number, 
		terrainShape: number?, 
		useAssetVersionId: boolean?
	)->(Instance?, string?);
	
	SetupStamperDragger: (
		modelToStamp: BasePart,
		Mouse,
		StampInModel: Model?,
		AllowedStampRegion: BasePart?,
		StampFailedFunc: ()->()
	)->(rbxstamper_control?);
	
	Help: (name_or_func: string | <A..., B...>(A...)->B...)->string?;
}

export type rbxutility_signal<A...> = {
	connect: (self: rbxutility_signal<A...>, (A...)->())->();
	Connect: (self: rbxutility_signal<A...>, (A...)->())->();
	disconnect: (self: rbxutility_signal<A...>)->();
	Disconnect: (self: rbxutility_signal<A...>)->();
	wait: (self: rbxutility_signal<A...>)->(A...);
	Wait: (self: rbxutility_signal<A...>)->(A...);
	fire: (self: rbxutility_signal<A...>, A...)->();
	Fire: (self: rbxutility_signal<A...>, A...)->();
}

export type rbxcreate = typeof(setmetatable(
	{} :: {
		E: <A>(name: A)->{__eventname: A};
	}, 
	{} :: {
		__call: <A>(any, class: string)->(dict<any>)->A;
	}
));

export type rbxutility = {
	DecodeJSON: <A>(string)->A;
	EncodeJSON: <A>(A)->string;
	MakeWedge: (x: number, y: number, z: number)->();
	
	SelectTerrainRegion: (
		region_select: Region3, 
		color: BrickColor,
		selectEmptyCells: boolean?,
		selectionParent: Instance?
	)->(
		(Region3, Color3)->(),
		empty
	),
	
	CreateSignal: <A...>()->(rbxutility_signal<A...>);
	
	Create: rbxcreate,
	
	Help: (name_or_func: string | <A..., B...>(A...)->B...)->string?;
}

export type rbxchatadmin = {
	admin: (user_id: number)->();
	a: (Player, message: string)->();
}

export type rbxhelper = {
	ClientModule: empty;
	SilentKick: (Player)->();
	LoudKick: (Player, msg: string)->();
	ServerShutdown: empty;
	LoadChatModule: (string)->();
}

export type libs = {
	RbxGui: rbxgui;
	RbxStamper: rbxstamper;
	RbxUtility: rbxutility;
	
	RbxCreate: rbxcreate;
	
	RbxChatAdmin: rbxchatadmin;
	RbxHelper: rbxhelper;
	
}

module = {}
disguise = LuaUTypes.disguise

function module.get(): module
	return require(disguise'./@trollege1x1>LoadLibSubstitute')
end

module.libs = disguise(setmetatable({}, {__index = function(_, i: string)
	return module.get()[i]
end,})) :: libs

return module
