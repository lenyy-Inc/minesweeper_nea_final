window.onload = function () { results()};
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
	
	searchrequest.open("GET", "../db/handler.php?request_type=search&username=" + window.username + "&elo=" + window.elo  + "&offset=" + offset);
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
			document.getElementById((id).toString()).innerHTML = search_results[i][0] + ": " + search_results[i][1];
			document.getElementById((id).toString()).onclick=function () {open_profile(search_results[i])}
			continue;

		}

		document.getElementById((id).toString()).style.display = "none";

	}

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

function results()
{

    window.data = parse_query_string()

    window.elo = window.data["elo"]
    window.username = window.data["username"]
	window.offset = 0
	get_demos(window.offset)

}

function open_profile(results)
{

	const data = ["profile"].concat(results)
	window.parent.postMessage(data)

}