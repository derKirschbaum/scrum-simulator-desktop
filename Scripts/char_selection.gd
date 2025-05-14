extends Control


@export var next_btn: Button;
@export var next_msg: RichTextLabel;

@export var desc: RichTextLabel;
@export var ip_list: RichTextLabel;

func _process(_delta):
	if len($"/root/NetworkManager".conn_array) >= 1 :
		next_btn.show();
		next_msg.hide();
	else:
		next_msg.show();
		next_msg.text = "[right]You need at least 2 players to proceed.\n[font_size=30](%d/2)[/font_size][/right]" % len($"/root/NetworkManager".conn_array);	
	
func _ready():
	desc.text = "[center][font_size='30']On your phone, look for [b]%s[/b] in the lobby list.[/font_size][/center]" % $"/root/NetworkManager".room_name;
	
	var regex = RegEx.new();
	regex.compile("^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])(\\.(?!$)|$)){4}$");
	
	var interfaces: Array = IP.get_local_interfaces();
	
	for i in interfaces:
		for ip in i.addresses:
			var result = regex.search(ip)
			
			if result:
				ip_list.text += "IP: " + ip + "\n";
				
func mouse_enter_sfx() -> void:
	$"/root/SoundControl".play_sfx("menu_hover");
	
func mouse_click_sfx() -> void:
	$"/root/SoundControl".play_sfx("menu_click");
