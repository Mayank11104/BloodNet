<?php
require 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {

    // GET — fetch donation history for a donor
    case 'GET':
        $donor_id = isset($_GET['donor_id']) ? (int)$_GET['donor_id'] : 0;
        $bank_id  = isset($_GET['bank_id'])  ? (int)$_GET['bank_id']  : 0;

        if (!$donor_id && !$bank_id) {
            sendError("donor_id or bank_id is required");
        }

        $where = "1=1";
        if ($donor_id) $where .= " AND d.donor_id = $donor_id";
        if ($bank_id)  $where .= " AND d.bank_id  = $bank_id";

        $result = $conn->query("
            SELECT d.id, d.donation_date, d.blood_group,
                   d.units_donated, d.credits_earned, d.notes,
                   u.full_name  AS donor_name,
                   bb.name      AS bank_name,
                   bb.city_id,
                   c.name       AS city_name
            FROM donations d
            JOIN users       u  ON u.id  = d.donor_id
            JOIN blood_banks bb ON bb.id = d.bank_id
            JOIN cities      c  ON c.id  = bb.city_id
            WHERE $where
            ORDER BY d.donation_date DESC
        ");

        $donations = [];
        while ($row = $result->fetch_assoc()) $donations[] = $row;

        sendResponse([
            "success" => true,
            "data"    => $donations,
            "count"   => count($donations)
        ]);
        break;

    // POST — record a new donation (called by admin when donor donates)
    case 'POST':
        $body = getBody();

        $required = ['donor_id', 'bank_id', 'blood_group', 'donation_date'];
        foreach ($required as $field) {
            if (empty($body[$field])) sendError("Field '$field' is required");
        }

        $donor_id      = (int)$body['donor_id'];
        $bank_id       = (int)$body['bank_id'];
        $blood_group   = clean($conn, $body['blood_group']);
        $donation_date = clean($conn, $body['donation_date']);
        $units_donated = isset($body['units_donated']) ? (int)$body['units_donated'] : 1;
        $credits       = 10; // flat 10 credits per donation
        $verified_by   = isset($body['verified_by']) ? (int)$body['verified_by'] : 'NULL';
        $notes         = isset($body['notes']) ? "'" . clean($conn, $body['notes']) . "'" : 'NULL';

        // Check donor exists
        $check = $conn->query("
            SELECT u.id, dp.blood_group, dp.total_credits
            FROM users u
            JOIN donor_profiles dp ON dp.user_id = u.id
            WHERE u.id = $donor_id AND u.role = 'donor'
            LIMIT 1
        ");

        if ($check->num_rows === 0) sendError("Donor not found", 404);
        $donor = $check->fetch_assoc();

        // Check 56-day gap
        $lastDonation = $conn->query("
            SELECT donation_date FROM donations
            WHERE donor_id = $donor_id
            ORDER BY donation_date DESC
            LIMIT 1
        ");

        if ($lastDonation->num_rows > 0) {
            $last = $lastDonation->fetch_assoc();
            $lastDate = new DateTime($last['donation_date']);
            $today    = new DateTime($donation_date);
            $diff     = $lastDate->diff($today)->days;

            if ($diff < 56) {
                $remaining = 56 - $diff;
                sendError("Donor must wait $remaining more day(s) before donating again (56-day rule)");
            }
        }

        $conn->begin_transaction();
        try {
            // 1. Insert donation record
            $conn->query("
                INSERT INTO donations
                (donor_id, bank_id, blood_group, units_donated, credits_earned, donation_date, verified_by, notes)
                VALUES ($donor_id, $bank_id, '$blood_group', $units_donated, $credits, '$donation_date', $verified_by, $notes)
            ");

            // 2. Update donor profile
            $new_credits    = $donor['total_credits'] + $credits;
            $unavailable_until = date('Y-m-d', strtotime($donation_date . ' +56 days'));

            $conn->query("
                UPDATE donor_profiles
                SET total_credits      = $new_credits,
                    last_donation_date = '$donation_date',
                    is_available       = 0,
                    unavailable_until  = '$unavailable_until'
                WHERE user_id = $donor_id
            ");

            // 3. Update blood stock — add units
            $conn->query("
                UPDATE blood_stock
                SET units_available = units_available + $units_donated
                WHERE bank_id = $bank_id AND blood_group = '$blood_group'
            ");

            // 4. Check if credits milestone reached (every 100)
            $prev_milestone = floor($donor['total_credits'] / 100);
            $new_milestone  = floor($new_credits / 100);

            if ($new_milestone > $prev_milestone) {
                // Award badge
                $badge_name = "BloodNet Hero Level $new_milestone";
                $conn->query("
                    INSERT INTO rewards (user_id, badge_name, credits_at)
                    VALUES ($donor_id, '$badge_name', $new_credits)
                ");

                // Notify donor
                $conn->query("
                    INSERT INTO notifications (user_id, type, subject, message)
                    VALUES ($donor_id, 'in-app',
                    '🏆 Congratulations! New Badge Earned!',
                    'You have earned the \"$badge_name\" badge! Your gift will be sent by the blood bank shortly. Thank you for saving lives!')
                ");
            } else {
                // Regular donation notification
                $conn->query("
                    INSERT INTO notifications (user_id, type, subject, message)
                    VALUES ($donor_id, 'in-app',
                    '🩸 Donation Recorded!',
                    'Thank you for donating blood on $donation_date! You earned +$credits credits. Keep saving lives!')
                ");
            }

            $conn->commit();

            sendResponse([
                "success"           => true,
                "message"           => "Donation recorded successfully!",
                "credits_earned"    => $credits,
                "total_credits"     => $new_credits,
                "unavailable_until" => $unavailable_until,
                "badge_earned"      => $new_milestone > $prev_milestone
            ], 201);

        } catch (Exception $e) {
            $conn->rollback();
            sendError("Failed to record donation: " . $e->getMessage(), 500);
        }
        break;

    default:
        sendError("Method not allowed", 405);
}
?>