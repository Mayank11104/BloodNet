<?php
require 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

// Generate unique tracking ID
function generateTrackingId() {
    return 'BN' . strtoupper(substr(md5(uniqid(mt_rand(), true)), 0, 8));
}

// Calculate priority score
function calcPriority($is_emergency, $severity) {
    $score = 0;
    if ($is_emergency) $score += 100;
    switch ($severity) {
        case 'Critical': $score += 80; break;
        case 'High':     $score += 60; break;
        case 'Medium':   $score += 40; break;
        case 'Low':      $score += 20; break;
    }
    return $score;
}

switch ($method) {

    // GET — all requests or track by tracking_id
    case 'GET':
        $tracking_id = isset($_GET['tracking_id']) ? clean($conn, $_GET['tracking_id']) : '';
        $status      = isset($_GET['status'])       ? clean($conn, $_GET['status'])      : '';
        $seeker_id   = isset($_GET['seeker_id'])    ? (int)$_GET['seeker_id']            : 0;

        // Public tracking by tracking ID
        if ($tracking_id) {
            $result = $conn->query("
                SELECT br.tracking_id, br.blood_group, br.units_needed,
                       br.hospital_name, br.is_emergency, br.incident_type,
                       br.severity, br.status, br.requested_at,
                       c.name AS city_name,
                       bb.name AS assigned_bank,
                       bb.contact AS bank_contact
                FROM blood_requests br
                JOIN cities c ON c.id = br.city_id
                LEFT JOIN blood_banks bb ON bb.id = br.assigned_bank_id
                WHERE br.tracking_id = '$tracking_id'
                LIMIT 1
            ");

            if ($result->num_rows === 0) sendError("Tracking ID not found", 404);

            $request = $result->fetch_assoc();

            // Get status history
            $req_id   = $conn->query("SELECT id FROM blood_requests WHERE tracking_id='$tracking_id'")->fetch_assoc()['id'];
            $history  = $conn->query("
                SELECT status, notes, updated_at
                FROM request_tracking
                WHERE request_id = $req_id
                ORDER BY updated_at ASC
            ");
            $timeline = [];
            while ($row = $history->fetch_assoc()) $timeline[] = $row;

            sendResponse([
                "success"  => true,
                "data"     => $request,
                "timeline" => $timeline
            ]);
            break;
        }

        // Admin — get all requests
        $where = "1=1";
        if ($status)    $where .= " AND br.status = '$status'";
        if ($seeker_id) $where .= " AND br.seeker_id = $seeker_id";

        $result = $conn->query("
            SELECT br.*, c.name AS city_name,
                   u.full_name AS seeker_name,
                   bb.name AS assigned_bank
            FROM blood_requests br
            JOIN cities c ON c.id = br.city_id
            JOIN users u ON u.id = br.seeker_id
            LEFT JOIN blood_banks bb ON bb.id = br.assigned_bank_id
            WHERE $where
            ORDER BY br.priority_score DESC, br.requested_at ASC
        ");

        $requests = [];
        while ($row = $result->fetch_assoc()) $requests[] = $row;
        sendResponse(["success" => true, "data" => $requests, "count" => count($requests)]);
        break;

    // POST — submit new blood request
    case 'POST':
        $body = getBody();

        $required = ['seeker_id','blood_group','units_needed',
                     'hospital_name','city_id','contact'];
        foreach ($required as $field) {
            if (empty($body[$field])) sendError("Field '$field' is required");
        }

        $seeker_id     = (int)$body['seeker_id'];
        $blood_group   = clean($conn, $body['blood_group']);
        $units_needed  = (int)$body['units_needed'];
        $hospital_name = clean($conn, $body['hospital_name']);
        $city_id       = (int)$body['city_id'];
        $contact       = clean($conn, $body['contact']);
        $is_emergency  = isset($body['is_emergency']) ? (int)$body['is_emergency'] : 0;
        $incident_type = isset($body['incident_type']) ? "'" . clean($conn, $body['incident_type']) . "'" : 'NULL';
        $incident_desc = isset($body['incident_desc']) ? "'" . clean($conn, $body['incident_desc']) . "'" : 'NULL';
        $severity      = isset($body['severity']) ? clean($conn, $body['severity']) : 'Medium';
        $priority      = calcPriority($is_emergency, $severity);
        $tracking_id   = generateTrackingId();

        // Auto assign nearest bank with stock
        $bank_result = $conn->query("
            SELECT bb.id, bb.city_id,
                   bs.units_available
            FROM blood_banks bb
            JOIN blood_stock bs ON bs.bank_id = bb.id
            WHERE bs.blood_group = '$blood_group'
            AND bs.units_available >= $units_needed
            ORDER BY ABS(bb.city_id - $city_id) ASC,
                     bs.units_available DESC
            LIMIT 1
        ");

        $assigned_bank_id = 'NULL';
        if ($bank_result->num_rows > 0) {
            $assigned_bank_id = $bank_result->fetch_assoc()['id'];
        }

        $conn->begin_transaction();
        try {
            $conn->query("
                INSERT INTO blood_requests
                (tracking_id, seeker_id, blood_group, units_needed,
                 hospital_name, city_id, contact, is_emergency,
                 incident_type, incident_desc, severity,
                 priority_score, assigned_bank_id)
                VALUES ('$tracking_id', $seeker_id, '$blood_group',
                        $units_needed, '$hospital_name', $city_id,
                        '$contact', $is_emergency, $incident_type,
                        $incident_desc, '$severity',
                        $priority, $assigned_bank_id)
            ");

            $request_id = $conn->insert_id;

            // Add initial tracking entry
            $conn->query("
                INSERT INTO request_tracking (request_id, status, notes)
                VALUES ($request_id, 'Pending', 'Request submitted successfully')
            ");

            // Notify matching donors if stock is low
            $stock_check = $conn->query("
                SELECT units_available FROM blood_stock
                WHERE bank_id = $assigned_bank_id
                AND blood_group = '$blood_group'
            ");

            if ($stock_check && $stock_check->num_rows > 0) {
                $units = $stock_check->fetch_assoc()['units_available'];
                if ($units <= 5) {
                    // Get donors with matching blood group
                    $donors = $conn->query("
                        SELECT u.id FROM users u
                        JOIN donor_profiles dp ON dp.user_id = u.id
                        WHERE dp.blood_group = '$blood_group'
                        AND dp.is_available = 1
                        AND u.is_active = 1
                    ");
                    while ($donor = $donors->fetch_assoc()) {
                        $d_id = $donor['id'];
                        $conn->query("
                            INSERT INTO notifications (user_id, type, subject, message)
                            VALUES ($d_id, 'in-app',
                            'Urgent Blood Needed!',
                            'There is an urgent need for $blood_group blood in your city. Please consider donating.')
                        ");
                    }
                }
            }

            $conn->commit();

            sendResponse([
                "success"     => true,
                "message"     => "Blood request submitted successfully!",
                "tracking_id" => $tracking_id,
                "priority"    => $priority,
                "assigned_bank_id" => $assigned_bank_id
            ], 201);

        } catch (Exception $e) {
            $conn->rollback();
            sendError("Request failed: " . $e->getMessage(), 500);
        }
        break;

    // PUT — update request status (admin)
    case 'PUT':
        $body = getBody();
        if (empty($body['id']) || empty($body['status'])) {
            sendError("id and status are required");
        }

        $id         = (int)$body['id'];
        $status     = clean($conn, $body['status']);
        $notes      = isset($body['notes'])      ? "'" . clean($conn, $body['notes'])      . "'" : 'NULL';
        $updated_by = isset($body['updated_by']) ? (int)$body['updated_by']                      : 'NULL';

        $conn->begin_transaction();
        try {
            $conn->query("UPDATE blood_requests SET status='$status' WHERE id=$id");

            $conn->query("
                INSERT INTO request_tracking (request_id, status, notes, updated_by)
                VALUES ($id, '$status', $notes, $updated_by)
            ");

            $conn->commit();
            sendResponse(["success" => true, "message" => "Request status updated to $status"]);

        } catch (Exception $e) {
            $conn->rollback();
            sendError("Update failed: " . $e->getMessage(), 500);
        }
        break;

    default:
        sendError("Method not allowed", 405);
}
?>