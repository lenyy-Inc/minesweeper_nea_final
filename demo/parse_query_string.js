window.onload = load_demo;

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

function get_demo()
{

	const searchrequest = new XMLHttpRequest();

	searchrequest.onload = () => 
	{

        let response = JSON.parse(searchrequest.response);
   
        window.demo = response[0][0]

	};
	
	searchrequest.open("GET", "../db/handler.php?request_type=replay&demoID=" + window.demoID);
	searchrequest.send();

}

function load_demo()
{

    window.data = parse_query_string()

    window.demoID = window.data["demoID"]

    get_demo()

}