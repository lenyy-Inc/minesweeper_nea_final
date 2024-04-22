window.onload = function () { profile()};
var mine_number

function parse_query_string()
{

    var params = location.href.split('?')[1].split('&');
    var data = {};
    for (x in params)
    {
        data[params[x].split('=')[0]] = params[x].split('=')[1];
    }

    return data
}

function get_demos(offset)
{

	const searchrequest = new XMLHttpRequest();

	searchrequest.onload = () => 
	{

		let response = JSON.parse(searchrequest.response);
		set_demo_boxes(response)

	};
	
	searchrequest.open("GET", "../db/handler.php?request_type=get_demos&username=" + window.username + "&offset=" + offset);
	searchrequest.send();

}

function set_demo_boxes(search_results)
{

	if(search_results == undefined){return}
	for(let i = 0; i < 10; i++)
	{

		let id = i + 1
		if(i < search_results.length)
		{

			document.getElementById((id).toString()).style.display = "grid";
			document.getElementById((id).toString()).innerHTML = search_results[i][0] + " vs. " + search_results[i][1];
			document.getElementById((id).toString()).onclick= function () {watch_demo(search_results[i])}
			continue;

		}

		document.getElementById((id).toString()).style.display = "none";

	}

}

function watch_demo(search_results)
{
	const data = ["demo", search_results[2], search_results[0], search_results[1]]
	window.parent.postMessage(data)

}

function scroll_right()
{

	window.offset++
	get_demos(window.offset)

}
function scroll_left()
{

	if(window.offset > 0)
	{
		window.offset--
		get_demos(window.offset)
	}

}

function profile()
{

	document.getElementById("username").innerHTML = window.username;

    window.data = parse_query_string()
    window.username = window.data["username"]
	window.elo = window.data["elo"]
	document.getElementById("username").innerHTML = window.username;
	document.getElementById("elo").innerHTML = window.elo;
	window.offset = 0
	get_demos(window.offset)

}