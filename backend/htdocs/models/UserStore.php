<?php

declare(strict_types=1);

/** Akses tabel users, password_resets, rate_limits. Tabel products tidak disentuh. */
final class UserStore
{
    public static function pdo(): PDO
    {
        return Config::database();
    }

    /** @param array<int,mixed> $params */
    public static function q(string $sql, array $params = []): PDOStatement
    {
        $st = self::pdo()->prepare($sql);
        $st->execute($params);
        return $st;
    }

    public static function ensureSchema(): void
    {
        $pdo = self::pdo();
        $pdo->exec("CREATE TABLE IF NOT EXISTS users (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            email VARCHAR(190) NOT NULL UNIQUE,
            password_hash VARCHAR(255) NOT NULL,
            role ENUM('user','admin') NOT NULL DEFAULT 'user',
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        // foto profil (kolom ditambah bila tabel users sudah ada dari versi sebelumnya)
        if (!self::q("SHOW COLUMNS FROM users LIKE 'avatar'")->fetch()) {
            $pdo->exec('ALTER TABLE users ADD COLUMN avatar MEDIUMBLOB NULL, ADD COLUMN avatar_mime VARCHAR(30) NULL, ADD COLUMN avatar_v INT NOT NULL DEFAULT 0');
        }
        $pdo->exec("CREATE TABLE IF NOT EXISTS password_resets (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id INT UNSIGNED NOT NULL,
            code_hash VARCHAR(255) NOT NULL,
            expires_at DATETIME NOT NULL,
            attempts INT NOT NULL DEFAULT 0,
            used TINYINT(1) NOT NULL DEFAULT 0,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            KEY idx_reset_user (user_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        $pdo->exec("CREATE TABLE IF NOT EXISTS rate_limits (
            rkey VARCHAR(80) NOT NULL PRIMARY KEY,
            hits INT NOT NULL DEFAULT 0,
            reset_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

        $pdo->exec("CREATE TABLE IF NOT EXISTS orders (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id INT UNSIGNED NOT NULL,
            total DECIMAL(14,2) NOT NULL,
            original_total DECIMAL(14,2) NOT NULL,
            payment_method VARCHAR(20) NOT NULL,
            payment_label VARCHAR(60) NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT 'menunggu',
            ship_name VARCHAR(100) NOT NULL,
            ship_phone VARCHAR(30) NOT NULL,
            ship_address TEXT NOT NULL,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            KEY idx_orders_user (user_id),
            KEY idx_orders_status (status)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        $pdo->exec("CREATE TABLE IF NOT EXISTS order_items (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            order_id INT UNSIGNED NOT NULL,
            product_id INT UNSIGNED NOT NULL,
            title VARCHAR(255) NOT NULL,
            thumbnail TEXT NULL,
            price DECIMAL(12,2) NOT NULL,
            quantity INT NOT NULL,
            KEY idx_items_order (order_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

        if (!self::q("SELECT id FROM users WHERE role = 'admin' LIMIT 1")->fetch()) {
            self::q(
                "INSERT INTO users (name, email, password_hash, role) VALUES (?, ?, ?, 'admin')
                 ON DUPLICATE KEY UPDATE role = 'admin'",
                [AppSettings::adminName(), AppSettings::adminEmail(), password_hash(AppSettings::adminPassword(), PASSWORD_DEFAULT)]
            );
        }
    }

    /** @return array<string,mixed>|null */
    public static function findByEmail(string $email): ?array
    {
        return self::q('SELECT id, name, email, password_hash, role, avatar_v FROM users WHERE email = ?', [$email])->fetch() ?: null;
    }

    /** @return array<string,mixed>|null */
    public static function findById(int $id): ?array
    {
        return self::q('SELECT id, name, email, role, avatar_v FROM users WHERE id = ?', [$id])->fetch() ?: null;
    }

    /** @param array<string,mixed> $u @return array<string,mixed> */
    public static function publicUser(array $u): array
    {
        $v = (int) ($u['avatar_v'] ?? 0);
        return [
            'id' => (int) $u['id'], 'name' => $u['name'], 'email' => $u['email'], 'role' => $u['role'],
            'avatarUrl' => $v > 0 ? '/users/' . (int) $u['id'] . '/avatar?v=' . $v : null,
        ];
    }

    /** Pembatas percobaan (anti tebak-tebakan). */
    public static function throttle(string $name, string $identity, int $max, int $minutes): void
    {
        $key = substr($name . ':' . sha1(($_SERVER['REMOTE_ADDR'] ?? '?') . '|' . strtolower($identity)), 0, 80);
        $row = self::q('SELECT hits, (reset_at > NOW()) AS active FROM rate_limits WHERE rkey = ?', [$key])->fetch();
        if ($row && (int) $row['active'] === 1) {
            if ((int) $row['hits'] >= $max) {
                fail('Terlalu banyak percobaan. Coba lagi beberapa menit lagi.', 429);
            }
            self::q('UPDATE rate_limits SET hits = hits + 1 WHERE rkey = ?', [$key]);
        } else {
            self::q('REPLACE INTO rate_limits (rkey, hits, reset_at) VALUES (?, 1, DATE_ADD(NOW(), INTERVAL ? MINUTE))', [$key, $minutes]);
        }
    }
}
