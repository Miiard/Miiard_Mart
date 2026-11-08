<?php

declare(strict_types=1);

/** Pengaturan tambahan untuk login, JWT, RabbitMQ. Semua bisa diubah lewat environment docker. */
final class AppSettings
{
    private static ?string $jwtSecret = null;

    public static function env(string $key, string $default = ''): string
    {
        $value = getenv($key);
        return $value === false || $value === '' ? $default : $value;
    }

    public static function jwtSecret(): string
    {
        if (self::$jwtSecret !== null) {
            return self::$jwtSecret;
        }
        $configured = self::env('JWT_SECRET');
        if (strlen($configured) >= 16) {
            return self::$jwtSecret = $configured;
        }
        // tanpa JWT_SECRET: buat sekali lalu simpan di folder data (sama seperti secret Google2FA)
        $path = self::env('JWT_SECRET_FILE', dirname(__DIR__, 2) . '/data/.jwt_secret');
        $dir = dirname($path);
        if (is_file($path)) {
            $stored = trim((string) file_get_contents($path));
            if (strlen($stored) >= 32) {
                return self::$jwtSecret = $stored;
            }
        }
        $generated = bin2hex(random_bytes(32));
        if ((is_dir($dir) || @mkdir($dir, 0700, true)) && @file_put_contents($path, $generated . PHP_EOL, LOCK_EX) !== false) {
            @chmod($path, 0600);
            return self::$jwtSecret = $generated;
        }
        // folder tidak bisa ditulis: turunkan dari kredensial database (tetap stabil antar-request)
        return self::$jwtSecret = hash('sha256', 'miiard|' . self::env('DB_PASSWORD', 'app_secret') . '|' . self::env('DB_USERNAME', 'app'));
    }

    public static function jwtDays(): int { return max(1, (int) self::env('JWT_DAYS', '7')); }
    public static function adminName(): string { return self::env('ADMIN_NAME', 'Admin Miiard'); }
    public static function adminEmail(): string { return strtolower(self::env('ADMIN_EMAIL', 'admin@miiard.mart')); }
    public static function adminPassword(): string { return self::env('ADMIN_PASSWORD', 'Admin123!'); }
    /** true = kode reset ikut dikirim di respons API (praktis untuk demo). Set DEV_SHOW_RESET_CODE=false untuk produksi. */
    public static function devShowCode(): bool { return self::env('DEV_SHOW_RESET_CODE', 'true') === 'true'; }
    public static function resetMinutes(): int { return 15; }

    public static function mqHost(): string { return self::env('RABBITMQ_HOST', 'rabbitmq'); }
    public static function mqPort(): int { return (int) self::env('RABBITMQ_MANAGEMENT_PORT', '15672'); }
    public static function mqUser(): string { return self::env('RABBITMQ_USER', self::env('RABBITMQ_DEFAULT_USER', 'app')); }
    public static function mqPass(): string { return self::env('RABBITMQ_PASSWORD', self::env('RABBITMQ_DEFAULT_PASS', '')); }
    public static function mqVhost(): string { return self::env('RABBITMQ_VHOST', '/'); }
    public static function mqQueue(): string { return 'emails'; }
    public static function mailEnabled(): bool { return self::env('MAIL_ENABLED', 'false') === 'true'; }
    public static function mailFrom(): string { return self::env('MAIL_FROM', 'Miiard.Mart <no-reply@miiard.mart>'); }
}
