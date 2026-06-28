--[[
	API:
		Cmd bar:
			The source code of this utility can be copied all, pasted under cmd bar and allows api to be used. names are purposely kept short since autocomplete doesn't 
			detect shared globals as well:
		
			si_exp(): exports all instances with attribute si_order

		ModuleScript:
			.import()

]]

local module = {}

btest = bit32.btest

IN_SCRIPT = not not script

module.flags = {}
module.flags.attempt_distribute    = 0b_0000_0000_0000_0001
module.flags.invoke_require        = 0b_0000_0000_0000_0010
module.flags.reject_export_destroy = 0b_0000_0000_0000_0100

function module.eval_breadcrumb(bc: string)
	local split = bc:split('.')
	
	local current = game:GetService(split[1])
	
	for i = 2, #split do
		current = current:FindFirstChild(split[i])
		
		if not current then 
			print(split)
			return warn('failed to eval breadcrumb')
		end
	end
	
	return current
end

module.local_script_source = "local gui=script.Parent;local player_scripts=game:GetService'Players'.LocalPlayer:WaitForChild'PlayerScripts'\z
for _,v in gui:GetChildren()do v.Parent=player_scripts;end;for _,v in game:GetService'CollectionService':GetTagged'si_enabled' do if v:IsA'\z
LocalScript'and v:IsDescendantOf(player_scripts)then v.Enabled=true;end;end"
module.transfer_message = `Missing player scripts transfer: Run following command, then parent screengui under SingletonImporter: \nlocal g\z
ui=Instance.new('ScreenGui', workspace)gui.Name='player_scripts_transfer_holder'gui.ResetOnSpawn=false;local local_script=Instance.new('Loc\z
alScript',gui)local_script.Source=[[{module.local_script_source}]]game:GetService'Selection':Set\{gui}\z`

function module.get_player_scripts_transfer(instance: Instance)
	local found = script:FindFirstChild('player_scripts_transfer_holder')
	
	if not found then
		warn(module.transfer_message)
		error('^')
	end
	
	local result = found:Clone()
	instance.Parent = result
	
	for _, v in instance:GetDescendants() do
		if v:IsA('LocalScript') and v.Enabled then
			v:AddTag('si_enabled')
			v.Enabled = false
		end
	end
	
	return result
end

export type import_arg = {
	respawn_player: boolean;
}

function module.import(arg: import_arg)
	if not IN_SCRIPT then return end
	
	local should_respawn = arg.respawn_player
	
	local instances = script.Parent:FindFirstChildWhichIsA('Folder'):GetChildren()
	local rejected = {}
	
	table.sort(instances, function(a0, a1): boolean
		local order0 = a0:GetAttribute('si_order')
		local order1 = a1:GetAttribute('si_order')
		
		return order0 < order1
	end)
	
	local player = game:GetService('Players'):GetPlayers()[1]
	local character = player and player.Character
	
	for _, instance in instances do
		local flags = instance:GetAttribute('si_flags') or 0
		
		if btest(flags, module.flags.invoke_require) then
			require(instance)
			continue
		end
		
		local parent: Instance = module.eval_breadcrumb(assert(instance:GetAttribute('si_breadcrumb')))
		
		local did_distribute = false
		
		if btest(flags, module.flags.attempt_distribute) then
			local present = parent:FindFirstChild(instance.Name)
			
			if present then
				for _, v in instance:GetChildren() do
					if present:FindFirstChild(v.Name) then
						continue
					end
					v.Parent = present
				end
				
				did_distribute = true
			end
		end
		
		if not did_distribute then
			instance.Parent = parent
		end
		
		if parent:IsA('StarterCharacterScripts') and not should_respawn and character then
			instance:Clone().Parent = character
		elseif parent:IsA('StarterPlayerScripts') and player then
			module.get_player_scripts_transfer(instance).Parent = player.PlayerGui
		elseif parent:IsA('StarterPack') and player then
			instance:Clone().Parent = player.Backpack
		end
	end
	
	if should_respawn and character then
		player:LoadCharacterAsync()
	end
end

function si_exp()
	if IN_SCRIPT then return warn('attempting to use cmd bar script in script') end
	
	local folder = Instance.new('Folder')
	folder.Name = '__si_export'
	folder.Parent = game:GetService('ServerStorage')
	
	for _, v in game:GetDescendants() do
		if v:GetAttribute('si_order') and not v:FindFirstAncestor('__si_export') then
			v:Clone().Parent = folder
		end
	end
	
	game:GetService('Selection'):Set({folder})
end



return module
