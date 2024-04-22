<!DOCTYPE html>
<?php session_start(); ?>
<html lang="en">
<head>


    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Mineswipper</title>

    <script type="module" src="./javascript/constants.js"></script>
    <script type="module" src="./javascript/add_tab.js"></script>
    <script type="module" src="./javascript/resizing.js"></script>
    <script type="module" src="./javascript/httprequests.js"></script>
    <script type="module" >import {add_tab_game_iframe, add_tab_search_result_iframe, add_tab_message} from "./javascript/add_tab.js";

        document.getElementById("queue_fast").onclick=function () { add_tab_game_iframe(0)};
        document.getElementById("queue_medium").onclick=function () { add_tab_game_iframe(1)};
        document.getElementById("queue_long").onclick=function () { add_tab_game_iframe(2)};
        document.getElementById("search").onclick=function () {add_tab_search_result_iframe()};
        window.onmessage=function(e) {add_tab_message(e)};

    </script>
    <script type= "text/javascript">

        window.username = "<?php echo $_SESSION['username']; ?>";

    </script>

    <style>

        .tab
         {

            position: relative;
            width: 10%;
            height: 10%;
            float: left;

        }

        .open_page_button
        {

            border-width: 0.5vmin;
            box-sizing: border-box;
            border-style: outset;
            display: flex;
            align-items: center;
            overflow-wrap: break-word;
            font-size: large;
            background-color: rgb(192, 192, 192);
            width: calc(10%);
            height: calc(10%);
            text-overflow: ellipsis;
            overflow: hidden;
            white-space: nowrap;
            align-items: center;
            text-align: center;
            border-width: 0.5vmin;

        }

        .close_button
        {

            top: 0;
            right: 0;
            position: absolute;
            display: grid;
            align-items: center;
            text-align: center;
            font-size: 2vh;
            margin-bottom: 85%;
            float: right;
            width: 2%;
            height: 2%;

        }

        .queue_button
        {

            display: grid;
            box-sizing: border-box;
            border-style: outset;
            float: left;
            border-width: 0.5vmin;
            text-overflow: ellipsis;
            overflow: hidden;
            white-space: nowrap;
            align-items: center;
            text-align: center;
            font-size: larger;

        }

    </style>
    <style>

        .profile
        {

            box-sizing: border-box;
            border-style: outset;
            background-color: rgb(192, 192, 192);

        }

        #search
        {

            display: grid;
            align-items: center;
            text-align: center;
            box-sizing: border-box;
            font-size:xx-large;
            width: 50%;
            border-style: outset;
            background-color: rgb(192, 192, 192);

        }

        .marginless
        {

            margin-top: -0.01vh;
            padding: none;
            font-size: small;
            margin: none;
            width: fit-content;
            height: fit-content;

            
        }

        .search_bar
        {

            

            float: bottom;
            padding: none;
            margin: none;
            background-color: rgb(255, 255, 255);
            font-size: 3.5vh;
            display: block;
            overflow: hidden;
            white-space: nowrap;
            width: calc(70%);
            height: calc(70%);
            overscroll-behavior: contain;

        }

        #search_section
        {

            display: grid;
            width: 100px;
            height: 100px;
            box-sizing: border-box;
            border-style: outset;
            border-width: 0.5vmin;
            float: left;

        }

        #sidebar
        {

            border-width: 1vmin;
            box-sizing: border-box;
            border-style: outset;
            position:fixed;
            padding:0;
            margin:0;
            float: left;
            height: 100%;
            top: 0;
            left: 0;
            background-color: rgb(192, 192, 192);
            background-size: 100% 100%;

        }
        
        #game_space
        {

            position:fixed;
            padding:0;
            margin:0;
            float: right;
            bottom: 0;
            right: 0;
            background-color: rgba(255, 0, 255, 0);

        }

        .empty_space
        {

            padding: 0;
            margin: 0;
            min-width: 0;
            min-height:0;
            background-color: rgb(0, 255, 255);

        }

        .iframe_holder
        {

            border-width: 0.5vmin;
            display: flex;
            box-sizing: border-box;
            position:fixed;
            padding:0;
            margin:0;
            background-color: rgb(0,0,0);
            bottom: 0;
            right: 0;

        }

        .game_iframe
        {

            border-width: 1vmin;
            box-sizing: border-box;
            display: block;
            position:absolute;
            border-radius: 0px;
            border-style: outset;
            background-color: rgb(192,192,192);
            height: 100%;
            width: 100%;
            padding:0;
            margin:0;
            bottom: 0;
            right: 0;

        }

        #tab_holder
        {

            background-color: rgba(0, 0, 255, 0);

        }
        
        #game
        {

            border-style: inset;
            border-width: 1vmin;
            box-sizing: border-box;
            background-color: rgb(192,192, 192);

        }

        .signed_in_name
        {

            position:absolute;
            top:0;
            right:0;
            font-size: larger;
            color: purple;

        }


    </style>

    <style>

        body 
        {

            background-color: rgb(192, 192, 192);

            font-family: 'Courier New', monospace;
        
        }   
          
    </style>

    <style>

        

    </style>
</head>
<body>
    <div id="whole_page">
        
        <div class = "signed_in_name" id="username"></div>

        <div id="sidebar">

            <div>

                <div class="queue_button" id="queue_fast">Queue for easy board</div>

                <div class="queue_button" id="queue_medium">Queue for medium board</div>

                <div class="queue_button" id="queue_long">Queue for expert board</div>

                <div class="search" id="search_section">
                    

                    <p class="marginless">Username</p><div contenteditable="true" class="search_bar" id="username_search"></div>

                    <p class="marginless">Elo</p><div contenteditable="true" class="search_bar" id="elo_search"></div>

                    <div id="search">Search</div>           
                
                <div>

            </div>

        </div>


        <div id="game_space"> 

            <div id="tab_holder"></div>
            <div id="game">



            </div>

        </div>

    </div>
</body>
<script>

document.getElementById("username").innerHTML = window.username;

</script>
</html>