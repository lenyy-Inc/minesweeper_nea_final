<?php
class userDB extends SQLite3
{

    private static ?userDB $userDB = NULL;

    private function __construct()
    {

        $this->open("./user_data.db");

    }

    public static function get_userDB(): userDB
    {
 
        if (self::$userDB == NULL)
        {

            self::$userDB = new userDB();

        }

        return self::$userDB;

    }

}

$DB_instance = userDB::get_userDB();

if ($_SERVER["REQUEST_METHOD"] == "GET");
{

	if ($_GET["request_type"] == "signin")
	{

		$username = $_GET["username"];
		$password = $_GET["password"];
		$password_confirm = $_GET["password_confirm"];

		if(($username == null) || ($password == null) || ($password_confirm == null))
		{

			header("Location: ../index.html?error_message=not_all_fields_filled");
			exit;

		}

		if(!($password_confirm == $password))
		{

			header("Location: ../index.html?error_message=password_and_password_confirm_do_not_match");
			exit;

		}
	
		$select = $DB_instance->prepare("SELECT password FROM users WHERE username = :username LIMIT 1");
		$select->bindvalue(":username", $username);
	
		$dbpassword = $select->execute()->fetchArray(SQLITE3_ASSOC);

		if (!$dbpassword)
		{

			$insert = $DB_instance->prepare("INSERT INTO users (username, password, elo) VALUES (:username, :password, '1000')");
			$insert->bindvalue(":username", $username);
			$insert->bindvalue(":password", $password);
			$insert->execute();
			header("Location: ../index.html?error_message=added_new_user_please_sign_in");
			exit;


		}
		
		if($dbpassword["password"] == $password)
		{

			session_start();
			$_SESSION["username"] = $username;
			header("Location: ../game_page.php");
			exit;

		}

		header("Location: ../index.html?error_message=incorrect_password");
		exit;
	
	}
	if ($_GET["request_type"] == "search")
	{

		$username = $_GET["username"]; 
		$elo =  $_GET["elo"]; 
		$offset = ($_GET["offset"] * 10);

		if($elo == "")
		{
			if($username == "")
			{

				$select = $DB_instance->prepare(
					"SELECT username, elo 
					FROM users 
					ORDER BY 
					elo DESC 
					LIMIT 10 
					OFFSET :offset"
					);

			}
			else
			{

				$select = $DB_instance->prepare(
					"SELECT username, elo 
					FROM users 
					WHERE username LIKE :username 
					ORDER BY 
						CASE 
							WHEN username LIKE :1username THEN 0
							WHEN username LIKE :2username THEN 1
							WHEN username LIKE :3username THEN 2
							WHEN username LIKE :username THEN 3
							ELSE 4 
							END,
					elo DESC 
					LIMIT 10 
					OFFSET :offset"
					);

					$select->bindvalue(":username", "%" . $username . "%");
					$select->bindvalue(":1username", $username);
					$select->bindvalue(":2username", $username. "%");
					$select->bindvalue(":3username", "%" . $username);
					
			}

		}
		else
		{
			
			if($username == "")
			{

				$select = $DB_instance->prepare(
					"SELECT username, elo 
					FROM users 
					WHERE elo > :min_elo
					AND elo < :max_elo
					ORDER BY 
					elo DESC 
					LIMIT 10 
					OFFSET :offset"
					);
	
					$select->bindvalue(":min_elo", $elo - 50);
					$select->bindvalue(":max_elo", $elo + 50);

			}
			else
			{

				$select = $DB_instance->prepare(
					"SELECT username, elo 
					FROM users 
					WHERE username LIKE :username 
					AND elo > :min_elo
					AND elo < :max_elo
					ORDER BY 
						CASE 
							WHEN username LIKE :1username THEN 0
							WHEN username LIKE :2username THEN 1
							WHEN username LIKE :3username THEN 2
							WHEN username LIKE :username THEN 3
							ELSE 4 
							END,
					elo DESC 
					LIMIT 10 
					OFFSET :offset"
					);
	
					$select->bindvalue(":min_elo", $elo - 50);
					$select->bindvalue(":max_elo", $elo + 50);
	
					$select->bindvalue(":username", "%" . $username . "%");
					$select->bindvalue(":1username", $username);
					$select->bindvalue(":2username", $username. "%");
					$select->bindvalue(":3username", "%" . $username);

			}
		
		}

		$select->bindvalue(":offset", $offset);

		$fetchedArray = array();

		$selection = $select->execute();

		while($selected = $selection->fetchArray(SQLITE3_NUM))
		{

			array_push($fetchedArray, $selected);

		}

		echo json_encode($fetchedArray);
		exit;
	}
	if ($_GET["request_type"] == "get_demos")
	{

		$username = $_GET["username"]; 
		$offset = ($_GET["offset"] * 10);

		$select = $DB_instance->prepare(
			"SELECT player1, player2, demoID
			FROM demos
			WHERE player1 = :username
			OR player2 = :username
			ORDER BY rowid DESC
			LIMIT 10
			OFFSET :offset"
			);

		$select->bindValue(":username", $username);
		$select->bindValue(":offset", $offset);

		$fetchedArray = array();

		$selection = $select->execute();
	
		while($selected = $selection->fetchArray(SQLITE3_NUM))
		{
	
			array_push($fetchedArray, $selected);
	
		}

		echo json_encode($fetchedArray);
		exit;

	}
	if($_GET["request_type"] == "replay")
	{

		$demoID = $_GET["demoID"];

		$select = $DB_instance->prepare(
			"SELECT demo 
			FROM demos
			WHERE demoID = :demoID"
		);

		$select->bindValue(":demoID", $demoID);

		$fetchedArray = array();

		$selection = $select->execute();

		while($selected = $selection->fetchArray(SQLITE3_NUM))
		{
	
			array_push($fetchedArray, $selected);
	
		}

		echo json_encode($fetchedArray);
		exit;

	}

}

header("Location: ../index.html?error_message=report_the_fact_you_saw_this_and_what_you_did");