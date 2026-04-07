<?php
require 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {

    // GET stock — all cities or specific city
    case 'GET':
        $city_id     = isset($_GET['city_id'])     ? (int)$_GET['city_id']             : 0;
        $blood_group = isset($_GET['blood_group']) ? clean($conn, $_GET['blood_group']) : '';

        $where = "1=1";
        if ($city_id)     $where .= " AND c.id = $city_id";
        if ($blood_group) $where .= " AND bs.blood_group = '$blood_group'";

        $result = $conn->query("
            SELECT bs.id, bs.blood_group, bs.units_available, bs.updated_at,
                   bb.name AS bank_name, bb.contact AS bank_contact,
                   c.id AS city_id, c.name AS city_name, c.state
            FROM blood_stock bs
            JOIN blood_banks bb ON bb.id = bs.bank_id
            JOIN cities c ON c.id = bb.city_id
            WHERE $where
            ORDER BY c.name ASC, bs.blood_group ASC
        ");

        $stock = [];
        while ($row = $result->fetch_assoc()) $stock[] = $row;
        sendResponse(["success" => true, "data" => $stock, "count" => count($stock)]);
        break;

    // PUT — update stock units (admin only)
    case 'PUT':
        $body = getBody();
        if (empty($body['bank_id']) || empty($body['blood_group'])) {
            sendError("bank_id and blood_group are required");
        }

        $bank_id     = (int)$body['bank_id'];
        $blood_group = clean($conn, $body['blood_group']);
        $units       = (int)$body['units_available'];

        $conn->query("
            UPDATE blood_stock
            SET units_available = $units
            WHERE bank_id = $bank_id AND blood_group = '$blood_group'
        ");

        sendResponse(["success" => true, "message" => "Stock updated successfully"]);
        break;

    default:
        sendError("Method not allowed", 405);
}
?>