<?php
require 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {

    // GET — fetch notifications for a user
    case 'GET':
        $user_id  = isset($_GET['user_id'])  ? (int)$_GET['user_id']  : 0;
        $unread   = isset($_GET['unread'])   ? (int)$_GET['unread']   : 0;

        if (!$user_id) sendError("user_id is required");

        $where = "user_id = $user_id";
        if ($unread) $where .= " AND is_read = 0";

        $result = $conn->query("
            SELECT id, type, subject, message, is_read, sent_at
            FROM notifications
            WHERE $where
            ORDER BY sent_at DESC
            LIMIT 50
        ");

        $notifications = [];
        while ($row = $result->fetch_assoc()) $notifications[] = $row;

        // Unread count
        $unreadResult = $conn->query("
            SELECT COUNT(*) AS count
            FROM notifications
            WHERE user_id = $user_id AND is_read = 0
        ");
        $unreadCount = $unreadResult->fetch_assoc()['count'];

        sendResponse([
            "success"      => true,
            "data"         => $notifications,
            "count"        => count($notifications),
            "unread_count" => (int)$unreadCount
        ]);
        break;

    // PUT — mark notification(s) as read
    case 'PUT':
        $body    = getBody();
        $user_id = isset($body['user_id']) ? (int)$body['user_id'] : 0;
        $notif_id = isset($body['id'])     ? (int)$body['id']      : 0;

        if (!$user_id) sendError("user_id is required");

        if ($notif_id) {
            // Mark single notification as read
            $conn->query("
                UPDATE notifications
                SET is_read = 1
                WHERE id = $notif_id AND user_id = $user_id
            ");
        } else {
            // Mark ALL as read
            $conn->query("
                UPDATE notifications
                SET is_read = 1
                WHERE user_id = $user_id
            ");
        }

        sendResponse(["success" => true, "message" => "Marked as read"]);
        break;

    default:
        sendError("Method not allowed", 405);
}
?>