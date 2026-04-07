<?php
require 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {

    // GET all cities
    case 'GET':
        $result = $conn->query("
            SELECT c.id, c.name, c.state, c.pincode,
                   bb.id AS bank_id, bb.name AS bank_name,
                   bb.address, bb.contact, bb.email
            FROM cities c
            LEFT JOIN blood_banks bb ON bb.city_id = c.id
            ORDER BY c.name ASC
        ");
        $cities = [];
        while ($row = $result->fetch_assoc()) $cities[] = $row;
        sendResponse(["success" => true, "data" => $cities]);
        break;

    default:
        sendError("Method not allowed", 405);
}
?>