extends Node

var game_manager: Node;

var server : UDPServer = UDPServer.new();

var broadcasters: Array[PacketPeerUDP];
var timers: Array[Timer];

var conn_array: Array[PacketPeerUDP];

var rand: RandomNumberGenerator = RandomNumberGenerator.new();

var accepting_client: bool = false;

var room_name: String;

func broadcast_lobby() -> void:
	for b in broadcasters:
		b.put_packet(room_name.to_utf8_buffer());

func stop_broadcast() -> void:
	for i in timers:
		i.one_shot = true;
		
	accepting_client = false;
		
func broadcast_message(msg: String) -> void:
		
	for conn in conn_array:
		conn.put_packet(msg.to_utf8_buffer());
		
func start_broadcast() -> void:
	accepting_client = true;
	for i in timers:
		i.one_shot = false;
		i.start();

func reset_broadcast() -> void:
	room_name = "";
	accepting_client = false;

func _ready() -> void:
	var regex = RegEx.new();
	regex.compile("^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])(\\.(?!$)|$)){4}$");
	
	var interfaces: Array = IP.get_local_interfaces();
	
	for i in interfaces:
		for ip in i.addresses:
			var result = regex.search(ip)
			
			if result:
				var str_arr : PackedStringArray = ip.split(".");
				var ip_b : String = "%s.%s.%s.255" % [str_arr[0], str_arr[1], str_arr[2]];
				
				
				var peer: PacketPeerUDP = PacketPeerUDP.new();
				peer.set_broadcast_enabled(true);
				peer.set_dest_address(ip_b, 9955);
				broadcasters.append(peer);
				
	var timer: Timer = Timer.new();
	timer.name = "Broadcast_timer";
	timer.timeout.connect(broadcast_lobby);
	timer.wait_time = 1.5;
	timer.autostart = true;
	timers.append(timer);
	
	self.call_deferred("add_child", timer);
	
	server.listen(9977);
	
func _process(_delta):
	server.poll();
	
	if server.is_connection_available():
		var peer: PacketPeerUDP = server.take_connection();
		var msg: String = peer.get_packet().get_string_from_utf8();
		var json: Dictionary = JSON.parse_string(msg);
		
		if !accepting_client:
			peer.put_packet("room_closed".to_utf8_buffer());
			return;
		
		if json.action == "char_create":
			var name: String = json.char.name;
			
			game_manager.add_player(peer, str(rand.randi_range(0, 9999999)), name);
		
			conn_array.append(peer);
			
		elif json.action == "connection_check":
			var reply: Dictionary = {
				action = "reply_connection"
			};
			
			var reply_json : String = JSON.stringify(reply);
			
			peer.put_packet(reply_json.to_utf8_buffer());
	
	for peer in conn_array:
		if peer.get_available_packet_count() > 0:
			var json : Dictionary = JSON.parse_string(peer.get_packet().get_string_from_utf8());
			print("Received " + str(json));
			game_manager.process_client_data(json);
