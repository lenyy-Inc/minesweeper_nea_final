
export function search_db(ascending, username_search, elo_search, offset)
{

	const searchrequest = new XMLHttpRequest();
	var order 
	if(ascending)
	{order = "ASC";}
	else
	{order = "DESC";}

	searchrequest.onload = () => 
	{

		let response = JSON.parse(searchrequest.response);
		return response

	};
	
	searchrequest.open("GET", "./db/handler.php?request_type=search&username=" + username_search + "&elo=" + elo_search + "&order=" + order + "&offset=" + offset);
	searchrequest.send();

}
