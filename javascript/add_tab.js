//let screen_height = window.screen.availHeight;
//let screen_width = window.screen.availWidth;

import { resize_tabs } from "./resizing.js";

//this just adds the necessary parts needed for all tabs

function add_tab(tab_name)
{

    if (window.tab_container.length > 49)
    {

        return

    }

    let new_tab_index = window.tab_container.length 

    let new_tab = document.createElement("div");
    new_tab.setAttribute("class","tab");
    new_tab.style.height = window.tab_height + "px";
    new_tab.style.width = window.tab_width + "px";

    let open_page_button = document.createElement("div");
    open_page_button.onclick = function () { open_tab(new_tab)};
    open_page_button.setAttribute("class", "open_page_button");
    open_page_button.innerHTML = tab_name;
    open_page_button.style.height = window.tab_height + "px";
    open_page_button.style.width = window.tab_width + "px";

    let close_button = document.createElement("span");
    close_button.onclick = function () { close_tab(new_tab_index); };
    close_button.setAttribute("class", "close_button");
    close_button.innerHTML= "&times";
    close_button.style.height = window.close_height + "px";
    close_button.style.width = window.close_width + "px";

    window.tab_container.push(new_tab);
    window.tab_holder.appendChild(new_tab);
    new_tab.appendChild(open_page_button);
    open_page_button.appendChild(close_button);

    reorganise_tabs()

}



function add_tab_iframe_holder(tab_name)
{

    add_tab(tab_name)

    let latest_added_tab = window.tab_container[window.tab_container.length - 1];

    let iframe_holder = document.createElement("div");
    iframe_holder.setAttribute("class", "iframe_holder");
    iframe_holder.style.height = window.game_height + "px";
    iframe_holder.style.width = window.game_space_width + "px";

    latest_added_tab.appendChild(iframe_holder);

}

export function add_tab_search_result_iframe()
{

    add_tab_iframe_holder("search results:")

    let latest_added_tab = window.tab_container[window.tab_container.length - 1];
    let iframe_holder = latest_added_tab.getElementsByClassName("iframe_holder")[0]

    let search_result_iframe = document.createElement("iframe")
    search_result_iframe.setAttribute("class","game_iframe");

    var username_search = document.getElementById("username_search").textContent;
	var elo_search = document.getElementById("elo_search").textContent;

    search_result_iframe.src = "./search_results_page/results.html?username=" + username_search + "&elo=" + elo_search;

    iframe_holder.appendChild(search_result_iframe);

    open_tab(latest_added_tab)

}

export function add_tab_message(e)
{

    switch(e.data[0])
    {
        case "profile":
            add_tab_profile_iframe(e)
            break;

        case "demo":
             add_tab_demo_iframe(e)
            break;

        default:
            break;

    }

}

export function add_tab_profile_iframe(e)
{

    let username = e.data[1];
    let elo = e.data[2];

    add_tab_iframe_holder(username + "'s profile:")

    let latest_added_tab = window.tab_container[window.tab_container.length - 1];
    let iframe_holder = latest_added_tab.getElementsByClassName("iframe_holder")[0]

    let profile_iframe = document.createElement("iframe")
    profile_iframe.setAttribute("class","game_iframe");
    profile_iframe.setAttribute("scrolling","no");

    profile_iframe.src = "./profile_page/profile.html?username=" + username + "&elo=" + elo;

    iframe_holder.appendChild(profile_iframe);

    open_tab(latest_added_tab)

}

export function add_tab_demo_iframe(e)
{
    let demoID = e.data[1]

    add_tab_iframe_holder(e.data[2] + " vs. " + e.data[3])

    let latest_added_tab = window.tab_container[window.tab_container.length - 1];
    let iframe_holder = latest_added_tab.getElementsByClassName("iframe_holder")[0]

    let game_iframe = document.createElement("iframe")
    game_iframe.setAttribute("class","game_iframe");

    game_iframe.src = "./demo/minesweeper.html?demoID=" + demoID;

    iframe_holder.appendChild(game_iframe);

    open_tab(latest_added_tab)

}

export function add_tab_game_iframe(mode)
{

    add_tab_iframe_holder("game:")

    let latest_added_tab = window.tab_container[window.tab_container.length - 1];
    let iframe_holder = latest_added_tab.getElementsByClassName("iframe_holder")[0]

    let game_iframe = document.createElement("iframe")
    game_iframe.setAttribute("class","game_iframe");

    game_iframe.src = "./game_client/minesweeper.html?username=" + window.username + "&game_mode=" + mode

    iframe_holder.appendChild(game_iframe);

    open_tab(latest_added_tab)

}

function redeclare_ids()
{

    for (let i in window.tab_container)
    {

        window.tab_container[i].setAttribute("id", "tab_" + i);  

    };

}

function redeclare_indexes()
{

    for (let i in window.tab_container)
    {

        let close_button = window.tab_container[i].getElementsByClassName("close_button")[0];
        close_button.onclick = function () { close_tab(i); };


    };

}

/*
function resize_tabs()
{

    if (tab_container.length > 7)
    {

        let new_tab_width = tab_holder.getBoundingClientRect().width / tab_container.length;

        for (let i in tab_container) 
        {
            let close_button = tab_container[i].getElementsByClassName("close_button")[0]
            let open_page_button = tab_container[i].getElementsByClassName("open_page_button")[0]
    
            tab_container[i].style.width = new_tab_width + "px";
            open_page_button.style.width = new_tab_width + "px";

            if (close_button.style.width > new_tab_width)
            {

                close_button.style.width = new_tab_width + "px";

            }
            else
            {

                close_button.style.width = 0.3 * tab_height;

            }
    
        };

    }

}
*/
function reorganise_tabs()
{

    redeclare_ids()

    redeclare_indexes()

    resize_tabs()

}

function open_tab(parent)
{
    var child_iframe_holder = parent.getElementsByClassName("iframe_holder")[0];
    var already_visible = child_iframe_holder.style.display == "block";


    for (let i in window.tab_container)
    {

        let iframe_holder = tab_container[i].getElementsByClassName("iframe_holder")[0] 
        iframe_holder.style.display = "none";
        tab_container[i].getElementsByClassName("open_page_button")[0].style.borderStyle = "outset";

    }
    if(!already_visible)
    {
        child_iframe_holder.style.display = "block";
        parent.getElementsByClassName("open_page_button")[0].style.borderStyle = "inset";
    }

}

function close_tab(i)
{

    window.tab_container[i].remove();
    window.tab_container.splice(i, 1);

    reorganise_tabs()
    
}