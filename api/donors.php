<?php
require 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {

    // GET donors — search by blood_group, city_id
    case 'GET':
        $blood_group = isset($_GET['blood_group']) ? clean($conn, $_GET['blood_group']) : '';
        $city_id     = isset($_GET['city_id'])     ? (int)$_GET['city_id']             : 0;
        $donor_id    = isset($_GET['id'])           ? (int)$_GET['id']                  : 0;

        // Single donor profile
        if ($donor_id) {
            $result = $conn->query("
                SELECT u.id, u.full_name, u.email, u.phone, u.city_id,
                       c.name AS city_name,
                       dp.blood_group, dp.gender, dp.weight_kg,
                       dp.total_credits, dp.is_available,
                       dp.unavailable_until, dp.last_donation_date,
                       hc.has_diabetes, hc.has_hiv_hepatitis,
                       hc.on_medication, hc.recent_surgery, hc.is_eligible
                FROM users u
                JOIN donor_profiles dp ON dp.user_id = u.id
                LEFT JOIN health_checks hc ON hc.user_id = u.id
                LEFT JOIN cities c ON c.id = u.city_id
                WHERE u.id = $donor_id AND u.role = 'donor'
                LIMIT 1
            ");
            if ($result->num_rows === 0) sendError("Donor not found", 404);
            sendResponse(["success" => true, "data" => $result->fetch_assoc()]);
        }

        // Search donors
        $where = "u.role = 'donor' AND dp.is_available = 1 AND u.is_active = 1";
        if ($blood_group) $where .= " AND dp.blood_group = '$blood_group'";
        if ($city_id)     $where .= " AND u.city_id = $city_id";

        $result = $conn->query("
            SELECT u.id, u.full_name, u.phone, u.city_id,
                   c.name AS city_name,
                   dp.blood_group, dp.gender,
                   dp.total_credits, dp.is_available,
                   dp.last_donation_date
            FROM users u
            JOIN donor_profiles dp ON dp.user_id = u.id
            LEFT JOIN cities c ON c.id = u.city_id
            WHERE $where
            ORDER BY dp.total_credits DESC
        ");

        $donors = [];
        while ($row = $result->fetch_assoc()) $donors[] = $row;
        sendResponse(["success" => true, "data" => $donors, "count" => count($donors)]);
        break;

    // POST — Register new donor
    case 'POST':
        $body = getBody();

        // Validate required fields
        $required = ['username','email','password','phone','full_name',
                     'city_id','blood_group','date_of_birth','gender',
                     'weight_kg','has_diabetes','has_hiv_hepatitis',
                     'on_medication','recent_surgery'];

        foreach ($required as $field) {
            if (!isset($body[$field]) || $body[$field] === '') {
                sendError("Field '$field' is required");
            }
        }

        // Age check (must be 18-65)
        $dob = new DateTime($body['date_of_birth']);
        $age = $dob->diff(new DateTime())->y;
        if ($age < 18 || $age > 65) {
            sendError("Donor must be between 18 and 65 years old");
        }

        // Weight check
        if ($body['weight_kg'] < 50) {
            sendError("Donor must weigh at least 50kg");
        }

        // Health eligibility check
        $is_eligible = (!$body['has_diabetes'] &&
                        !$body['has_hiv_hepatitis'] &&
                        !$body['on_medication'] &&
                        !$body['recent_surgery']) ? 1 : 0;

        // Check duplicate
        $email    = clean($conn, $body['email']);
        $username = clean($conn, $body['username']);
        $phone    = clean($conn, $body['phone']);

        $check = $conn->query("
            SELECT id FROM users
            WHERE email='$email' OR username='$username' OR phone='$phone'
            LIMIT 1
        ");
        if ($check->num_rows > 0) {
            sendError("Email, username or phone already registered");
        }

        $conn->begin_transaction();
        try {
            // Insert user
            $password  = md5($body['password']);
            $full_name = clean($conn, $body['full_name']);
            $city_id   = (int)$body['city_id'];

            $conn->query("
                INSERT INTO users (username, email, password, phone, full_name, role, city_id)
                VALUES ('$username','$email','$password','$phone','$full_name','donor',$city_id)
            ");
            $user_id = $conn->insert_id;

            // Insert donor profile
            $blood_group = clean($conn, $body['blood_group']);
            $dob_str     = clean($conn, $body['date_of_birth']);
            $gender      = clean($conn, $body['gender']);
            $weight      = (float)$body['weight_kg'];
            $hemo        = isset($body['hemoglobin_level']) ? (float)$body['hemoglobin_level'] : 'NULL';
            $bp          = isset($body['blood_pressure'])   ? "'" . clean($conn, $body['blood_pressure']) . "'" : 'NULL';

            $conn->query("
                INSERT INTO donor_profiles
                (user_id, blood_group, date_of_birth, gender, weight_kg, hemoglobin_level, blood_pressure)
                VALUES ($user_id,'$blood_group','$dob_str','$gender',$weight,$hemo,$bp)
            ");

            // Insert health check
            $has_diabetes     = (int)$body['has_diabetes'];
            $has_hiv          = (int)$body['has_hiv_hepatitis'];
            $on_meds          = (int)$body['on_medication'];
            $recent_surgery   = (int)$body['recent_surgery'];
            $surgery_details  = isset($body['surgery_details'])    ? "'" . clean($conn, $body['surgery_details'])    . "'" : 'NULL';
            $med_details      = isset($body['medication_details']) ? "'" . clean($conn, $body['medication_details']) . "'" : 'NULL';

            $conn->query("
                INSERT INTO health_checks
                (user_id, has_diabetes, has_hiv_hepatitis, on_medication,
                 recent_surgery, surgery_details, medication_details, is_eligible)
                VALUES ($user_id,$has_diabetes,$has_hiv,$on_meds,
                        $recent_surgery,$surgery_details,$med_details,$is_eligible)
            ");

            $conn->commit();

            sendResponse([
                "success" => true,
                "message" => "Donor registered successfully!",
                "user_id" => $user_id,
                "eligible"=> (bool)$is_eligible
            ], 201);

        } catch (Exception $e) {
            $conn->rollback();
            sendError("Registration failed: " . $e->getMessage(), 500);
        }
        break;

    // PUT — Update donor availability
    case 'PUT':
        $body = getBody();
        if (empty($body['user_id'])) sendError("user_id is required");

        $user_id      = (int)$body['user_id'];
        $is_available = (int)$body['is_available'];

        $conn->query("
            UPDATE donor_profiles
            SET is_available = $is_available
            WHERE user_id = $user_id
        ");

        sendResponse(["success" => true, "message" => "Availability updated"]);
        break;

    default:
        sendError("Method not allowed", 405);
}
?>