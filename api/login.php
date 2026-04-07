<?php
require 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {

    case 'POST':
        $body = getBody();

        if (empty($body['username']) || empty($body['password'])) {
            sendError("Username and password are required");
        }

        $username = clean($conn, $body['username']);
        $password = md5($body['password']);

        $sql    = "SELECT id, username, email, full_name, role, city_id, is_active
                   FROM users
                   WHERE (username = '$username' OR email = '$username')
                   AND password = '$password'
                   LIMIT 1";
        $result = $conn->query($sql);

        if ($result->num_rows === 0) {
            sendError("Invalid username or password", 401);
        }

        $user = $result->fetch_assoc();

        if (!$user['is_active']) {
            sendError("Your account is deactivated. Contact BloodNet support.", 403);
        }

        // If donor, fetch donor profile too
        $profile = null;
        if ($user['role'] === 'donor') {
            $uid     = $user['id'];
            $pResult = $conn->query("SELECT * FROM donor_profiles WHERE user_id = $uid LIMIT 1");
            if ($pResult->num_rows > 0) $profile = $pResult->fetch_assoc();
        }

        sendResponse([
            "success" => true,
            "message" => "Login successful",
            "user"    => $user,
            "profile" => $profile
        ]);
        break;

    default:
        sendError("Method not allowed", 405);
}
?>