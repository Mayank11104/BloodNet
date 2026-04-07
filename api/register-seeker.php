<?php
require 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError("Method not allowed", 405);
}

$body = getBody();

$required = ['username', 'email', 'password', 'phone', 'full_name', 'city_id'];
foreach ($required as $field) {
    if (empty($body[$field])) sendError("Field '$field' is required");
}

$username  = clean($conn, $body['username']);
$email     = clean($conn, $body['email']);
$phone     = clean($conn, $body['phone']);
$full_name = clean($conn, $body['full_name']);
$city_id   = (int)$body['city_id'];
$password  = md5($body['password']);

// Check duplicate
$check = $conn->query("
    SELECT id FROM users
    WHERE email='$email' OR username='$username' OR phone='$phone'
    LIMIT 1
");
if ($check->num_rows > 0) {
    sendError("Email, username or phone already registered");
}

$conn->query("
    INSERT INTO users (username, email, password, phone, full_name, role, city_id)
    VALUES ('$username','$email','$password','$phone','$full_name','seeker',$city_id)
");

$user_id = $conn->insert_id;

sendResponse([
    "success" => true,
    "message" => "Seeker registered successfully!",
    "user_id" => $user_id
], 201);
?>