--[[
	A personal plugin theme, with extensions and helper functions
	
	see rblxguilib (https://github.com/arch4ic/rblxguilib)
]]

local RbxGuiLibTypes = require('./@CHL>RblxGuiLibTypes')
local Class = require('./Class')
local LuaUTypes = require('./LuaUTypes')
local PluginToolset = require('./@CHL>PluginToolset')

local module = {}
local RbxGuiLib: RbxGuiLibTypes.library = nil
local widget = nil

LabeledSize = .2
disguise = LuaUTypes.disguise

function module.add_page(name: string): (RbxGuiLibTypes.PageFrame, RbxGuiLibTypes.ScrollingFrame_rgl)
	local page = assert(RbxGuiLib).Page.new({
		Name = name,
		TitlebarMenu = widget.TitleBarMenu,
		Open = true
	}, widget)

	local scrolling_frame = RbxGuiLib.ScrollingFrame.new(nil, page.Content)
	scrolling_frame:SetMain()

	return page, scrolling_frame
end

function module.init(id: string)
	local plugin = PluginToolset.promised_plugin:expect()
	RbxGuiLib = RbxGuiLibTypes.get()(plugin, id)
	module.default_lib = RbxGuiLib 
end

function module.widget_init(w: RbxGuiLibTypes.PluginWidget)
	widget = w
end

--#########################################################################################
--#########################################################################################
--#########################################################################################

local Object = require('./Object')

export type RadioInput = {
	input: RbxGuiLibTypes.InputField;
	labeled: RbxGuiLibTypes.Labeled;
}

RadioInput = {}

function RadioInput.new(txt: string, options: {any}, pick: number): RadioInput
	local input = RbxGuiLib.InputField.new({
		Items = options;
		Value = assert(options[pick]);
		ClearText = true;
		InputSize = 1
	});
	local labeled = RbxGuiLib.Labeled.new({
		Text = txt;
		Object = input;
		LabelSize = LabeledSize
	})
	input.IgnoreText = true;

	local self: RadioInput = Object.simple.new(RadioInput)
	self.input = input
	self.labeled = labeled

	return self
end

Class.make_proper_class(RadioInput, 'RadioInput')

module.radio = RadioInput
module.new_radio = RadioInput.new

--#########################################################################################
--#########################################################################################
--#########################################################################################

function module.add_section(txt: string): RbxGuiLibTypes.Section
	local section = RbxGuiLib.Section.new({Text = txt;Open = true})
	section:SetMain()
	return section
end

function module.add_action_button(text: string): RbxGuiLibTypes.Button
	return RbxGuiLib.Button.new({Text = text, ButtonSize = 1})
end

--#########################################################################################
--#########################################################################################
--#########################################################################################

local EventPackage = require('./@averlyst>NamedSignal')

type signal<FUNC> = EventPackage.Signal<FUNC>

export type NumberInput = {
	value: number;
	should_invoke_event: boolean;

	labeled: RbxGuiLibTypes.Labeled;
	slider: RbxGuiLibTypes.Slider;
	input: RbxGuiLibTypes.InputField;

	set_value: (self: NumberInput, v: number)->();

	changed: signal<(value: number)->()>;
}

NumberInput = {}

function NumberInput.new(text: string, 
	value: number, 
	min: number, 
	max: number, 
	increment: number): NumberInput
	
	local self: NumberInput = Object.simple.new(NumberInput)
	
	self.changed = EventPackage.new()
	self.should_invoke_event = true
	self.value = value
	self.slider = RbxGuiLib.Slider.new{
		Value = value;
		Min = min;
		Max = max;
		Increment = increment
	}
	self.input = RbxGuiLib.InputField.new{
		Value = self.slider.Value;
		InputSize = 1;
		NoDropdown = true;
	}
	self.labeled = RbxGuiLib.Labeled.new{
		Text = text,
		LabelSize = LabeledSize;
		Objects = {
			{
				Object = self.input;
				Name = 'input';
				Size = UDim.new(0,50)
			},{
				Name = 'slider';
				Object = self.slider;
			}
		}
	}

	self.input:LostFocus(function(a0)
		a0 = tonumber(a0)
		if not a0 then return end

		self.changed:Fire(a0)
	end)
	self.slider:Changed(function(a0: number)
		if not self.should_invoke_event then return end

		self.changed:Fire(a0)
	end)

	self.changed:Connect(function(a0: number)
		self.should_invoke_event = false
		self.value = a0
		self.input:SetValue(tostring(a0))
		self.slider:SetValue(a0)
		self.should_invoke_event = true
	end)

	return self
end

function NumberInput.set_value(self: NumberInput, v: number)
	self.changed:Fire(v)
end

Class.make_proper_class(NumberInput, 'NumberInput')

module.number = NumberInput
module.new_number_input = NumberInput.new

--#########################################################################################
--#########################################################################################
--#########################################################################################

function module.add_boolean_set(text: string, init: boolean?): RbxGuiLibTypes.CheckBox
	local Checkbox = RbxGuiLib.Checkbox.new({Value = not not init;})
	RbxGuiLib.Labeled.new({Text = text;Object = Checkbox;LabelSize = LabeledSize})
	return Checkbox
end

function module.add_text_set(text: string, init: string?): RbxGuiLibTypes.InputField
	local TextBox_args: RbxGuiLibTypes.InputField_args = {
		Value = init or '';
		ClearBackground = false;
		InputSize = 1;
		Items = {};
		Placeholder = '';
		NoDropdown = true
	}
	local TextBox = RbxGuiLib.InputField.new(TextBox_args)
	RbxGuiLib.Labeled.new({Text = text;Object = TextBox;LabelSize = LabeledSize})
	return TextBox
end

function module.add_instance_set(text: string): RbxGuiLibTypes.InstanceInputField
	local args: RbxGuiLibTypes.InstanceInputField_args = {
		ClearBackground = false,
		InputSize = 1;
		Items = {};
		Placeholder = 'Use dropdown to select instances while selecting on explorer.';
	}
	local TextBox: RbxGuiLibTypes.InstanceInputField = RbxGuiLib.InputField.new(args)
	RbxGuiLib.Labeled.new({Text = text;Object = TextBox;LabelSize = LabeledSize})
	return TextBox
end

function module.add_color_set(text: string): RbxGuiLibTypes.ColorInput
	local TextBox: RbxGuiLibTypes.ColorInput = RbxGuiLib.ColorInput.new({})
	RbxGuiLib.Labeled.new({Text = text;Object = TextBox;LabelSize = LabeledSize})
	return TextBox
end

function module.add_instance_set_2(text: string): RbxGuiLibTypes.InstanceInputField
	local args: RbxGuiLibTypes.InstanceInputField_args = {
		ClearBackground = false,
		InputSize = 1;
		Items = {};
		Placeholder = 'Select instances in explorer then click here to select them.';
	}
	local TextBox: RbxGuiLibTypes.InstanceInputField = RbxGuiLib.InstanceInputField.new(args)
	RbxGuiLib.Labeled.new({Text = text;Object = TextBox;LabelSize = LabeledSize})
	return TextBox
end

function module.prompt_notify(text: string, title: string?)
	RbxGuiLib.TextPrompt.new({
		Title = title or 'Notification';
		NoPause = true;
		Text = text;
		Buttons = {'Okay'};
	})
end

function module.prompt_copyable(text: string, title: string?)
	local input_prompt = RbxGuiLib.InputPrompt.new({
		Input = 'Ctrl + A then Ctrl + C to copy';
		Title = title or 'Copyable';
		NoPause = true;
		Text = 'Ctrl + A then Ctrl + C to copy';
		Buttons = {'Done'}
	} :: RbxGuiLibTypes.InputPrompt_args)
	
	local input_field = input_prompt.InputField
	input_field.Input.Text = text
	
	return input_prompt
end

--#########################################################################################
--#########################################################################################
--#########################################################################################

return module
