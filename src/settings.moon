local gametype
if os.getenv "SERVER"
	gametype = 'server'
elseif os.getenv "CLIENT"
	gametype = 'client'
else
	gametype = 'single_player'

player_name = (os.getenv "player") or "DUMMY"

{
headless: false
window_size: {800, 600}
server_ip: '192.168.12.102'
server_port: 6112
frames_per_second: 100

:gametype
:player_name

--Online settings
username: 'User'
lobby_server_url: 'http://putterson.homedns.org:8080'

--Window settings
fullscreen: false
view_width: 1200
view_height: 900 

--Font settings
font: 'src/modules/core/resources/fonts/Gudea-Regular.ttf'
menu_font: 'src/modules/core/resources/fonts/alagard_by_pix3m-d6awiwp.ttf'

--Debug settings
network_debug_mode: false
draw_diagnostics: false
verbose_output: false
keep_event_log: false

}
