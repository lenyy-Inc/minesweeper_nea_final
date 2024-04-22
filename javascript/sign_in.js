function get_handler()
{

    const req = new XMLHttpRequest();
    req.open("GET", "./db/handler.php", true);
    req.send();


}

function set_handler(data)
{

    const req = new XMLHttpRequest();
    req.open("SET", "./db/handler.php?username=" + window.username + "&password=" + window.password);
    data = JSON.stringify(data);
    req.send(data);

}

function check_lengths()
{

    var username = document.getElementsByName("username_box")
    var password = document.getElementsByName("password_box")
    var password_confirm = document.getElementsByName("password_confirm_box")

}