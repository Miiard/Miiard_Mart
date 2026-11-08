<?php

declare(strict_types=1);

/**
 * Worker email: ambil pesan dari antrean RabbitMQ "emails", cetak / kirim.
 * Jalankan dari terminal:  docker compose exec <service-php> php worker.php
 */
if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    exit;
}
require_once __DIR__ . '/support/AppSettings.php';
require_once __DIR__ . '/support/RabbitMq.php';

$vh = rawurlencode(AppSettings::mqVhost());
$queue = AppSettings::mqQueue();
echo "[worker] menunggu pesan di antrean \"$queue\" (Ctrl+C untuk berhenti)\n";

while (true) {
    [$status, $msgs] = RabbitMq::request('POST', "/queues/$vh/$queue/get", [
        'count' => 1, 'ackmode' => 'ack_requeue_false', 'encoding' => 'auto',
    ]);
    if ($status !== 200) {
        echo "[worker] RabbitMQ belum bisa diakses (status $status). Cek RABBITMQ_USER / RABBITMQ_PASSWORD.\n";
        sleep(5);
        continue;
    }
    if (!is_array($msgs) || !$msgs) {
        sleep(2);
        continue;
    }
    $mail = json_decode((string) ($msgs[0]['payload'] ?? ''), true);
    if (!is_array($mail) || empty($mail['to'])) {
        continue;
    }
    echo "\n========== EMAIL ==========\nKepada : {$mail['to']}\nSubjek : {$mail['subject']}\n\n{$mail['text']}\n===========================\n";
    if (AppSettings::mailEnabled()) {
        $ok = @mail($mail['to'], $mail['subject'], $mail['text'], 'From: ' . AppSettings::mailFrom());
        echo $ok ? "[worker] email dikirim lewat mail()\n" : "[worker] mail() gagal (sendmail/SMTP belum diatur)\n";
    }
}
