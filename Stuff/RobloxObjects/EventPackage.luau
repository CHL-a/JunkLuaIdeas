local module = {}
local NamedSignal = require('./@averlyst>NamedSignal')

export type signal<func_sig = () -> ()> = {
	get_connections: index<NamedSignal.Signal, 'GetConnections'>;
	once_now: index<NamedSignal.Signal, 'OnceNow'>;
	once: index<NamedSignal.Signal, 'Once'>;
	connect_now: index<NamedSignal.Signal, 'ConnectNow'>;
	connect: index<NamedSignal.Signal, 'Connect'>;
	destroy_now: index<NamedSignal.Signal, 'DestroyNow'>;
	destroy: index<NamedSignal.Signal, 'Destroy'>;
	disconnect_all_now: index<NamedSignal.Signal, 'DisconnectAllNow'>;
	disconnect_all: index<NamedSignal.Signal, 'DisconnectAll'>;
	cancel_all_mutations: index<NamedSignal.Signal, 'CancelAllMutations'>;
	
	fire: index<NamedSignal.Signal, 'Fire'>;
	fire_now: index<NamedSignal.Signal, 'FireNow'>;
	wait: index<NamedSignal.Signal, 'Wait'>;
	wait_now: index<NamedSignal.Signal, 'WaitNow'>;
} & NamedSignal.Signal<func_sig>

function module.init()
	local signal = NamedSignal.new()
	
	local metatable = getmetatable(signal)
	
	for i, v in module.index_add do
		metatable[v] = metatable[i]
	end
	
	signal:Destroy()
end

module.index_add = {
	GetConnections = 'get_connections';
	OnceNow = 'once_now';
	Once = 'once';
	ConnectNow = 'connect_now';
	Connect = 'connect';
	DestroyNow = 'destroy_now';
	Destroy = 'destroy';
	DisconnectAllNow = 'disconnect_all_now';
	DisconnectAll = 'disconnect_all';
	CancelAllMutations = 'cancel_all_mutations';
	
	Fire = 'fire';
	FireNow = 'fire_now';
	Wait = 'wait';
	WaitNow = 'wait_now';
}

module.new = NamedSignal.new
module.from_regular_event = NamedSignal.wrap

--######################################################################################################################################################################################
--######################################################################################################################################################################################
--######################################################################################################################################################################################

return module
