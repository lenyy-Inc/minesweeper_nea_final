//constants to be shared between javascript files
//var is used for global variables shared between script files, so it is used even for constants, though this isn't ideal

window.screen_height = window.screen.availHeight;
window.screen_width = window.screen.availWidth;

window.game_space_width_height_ratio = 0.61;
window.tab_holder_height_ratio = 1/8;

window.initial_game_space_width = screen_width * 0.7;
window.initial_game_space_height = initial_game_space_width * game_space_width_height_ratio;

window.initial_sidebar_width = screen_width * 0.2;

window.game_space = document.getElementById("game_space");

window.tab_holder = document.getElementById("tab_holder");

window.game = document.getElementById("game");

window.sidebar = document.getElementById("sidebar");

//globals

//window.username = "test";

window.game_space_height;
window.game_space_width;

window.game_height;

window.tab_holder_height;

window.sidebar_width;

window.game_height;

//tab_stuff

window.tab_container = [];

window.tab_height;
window.tab_width;

window.close_height;
window.close_width;

//the page always needs all of these, so they cant be unloaded