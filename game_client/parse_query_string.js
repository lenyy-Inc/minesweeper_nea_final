window.onload = add_username_and_mode_from_query_string;

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

function add_username_and_mode_from_query_string()
{

    window.data = parse_query_string()

    window.mode = window.data["game_mode"]
    window.username = window.data["username"]

}