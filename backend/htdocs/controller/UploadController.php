<?php

declare(strict_types=1);

/** Foto produk dari galeri: disimpan di database (MySQL), disajikan lewat GET /uploads/product/{id}. */
final class UploadController
{
    private const MAX_BYTES = 5 * 1024 * 1024; // 5 MB

    private function ensureTable(): void
    {
        UserStore::pdo()->exec("CREATE TABLE IF NOT EXISTS product_images (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            data MEDIUMBLOB NOT NULL,
            mime VARCHAR(30) NOT NULL,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
    }

    /** POST /uploads/product  {"image": "<base64 JPEG/PNG/WEBP>"}  (ADMIN) -> {"url": "...", "path": "..."} */
    public function storeProduct(): void
    {
        $raw = Guard::body()['image'] ?? null;
        if (!is_string($raw) || $raw === '') {
            fail('Foto tidak ditemukan.');
        }
        if (str_contains($raw, ',')) {
            $raw = substr($raw, strpos($raw, ',') + 1); // buang awalan data:image/...;base64,
        }
        $bytes = base64_decode($raw, true);
        if ($bytes === false || $bytes === '') {
            fail('Foto tidak valid.');
        }
        if (strlen($bytes) > self::MAX_BYTES) {
            fail('Ukuran foto maksimal 5 MB.', 413);
        }
        $info = @getimagesizefromstring($bytes);
        $mimes = ['image/jpeg', 'image/png', 'image/webp'];
        if (!$info || !in_array($info['mime'], $mimes, true)) {
            fail('Format foto harus JPG, PNG, atau WEBP.');
        }

        $this->ensureTable();
        UserStore::q('INSERT INTO product_images (data, mime) VALUES (?, ?)', [$bytes, $info['mime']]);
        $id = (int) UserStore::pdo()->lastInsertId();

        $path = '/uploads/product/' . $id;
        $https = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off')
            || strtolower((string) ($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '')) === 'https';
        $host = (string) ($_SERVER['HTTP_HOST'] ?? 'localhost');
        respond(['id' => $id, 'path' => $path, 'url' => ($https ? 'https' : 'http') . '://' . $host . $path], 201);
    }

    /** GET /uploads/product/{id} - mengirim gambar langsung. */
    public function showProduct(int $id): void
    {
        $this->ensureTable();
        $row = UserStore::q('SELECT data, mime FROM product_images WHERE id = ?', [$id])->fetch();
        if (!$row) {
            http_response_code(404);
            exit;
        }
        header('Content-Type: ' . $row['mime']);
        header('Cache-Control: public, max-age=31536000, immutable');
        header('X-Content-Type-Options: nosniff');
        echo $row['data'];
        exit;
    }
}
