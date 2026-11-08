<?php

declare(strict_types=1);

/** Pembaca token Bearer + pengecekan login / admin. Role selalu dibaca ulang dari database. */
final class Guard
{
    private static ?array $user = null;
    private static bool $loaded = false;

    public static function bearer(): ?string
    {
        $h = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
        if ($h === '' && function_exists('getallheaders')) {
            foreach (getallheaders() as $k => $v) {
                if (strtolower((string) $k) === 'authorization') {
                    $h = (string) $v;
                }
            }
        }
        return stripos($h, 'Bearer ') === 0 ? substr($h, 7) : null;
    }

    /** @return array<string,mixed>|null */
    public static function user(): ?array
    {
        if (!self::$loaded) {
            self::$loaded = true;
            $t = self::bearer();
            $data = $t ? Jwt::verify($t) : null;
            self::$user = $data ? UserStore::findById((int) $data['sub']) : null;
        }
        return self::$user;
    }

    /** @return array<string,mixed> */
    public static function requireLogin(): array
    {
        return self::user() ?? fail('Silakan login terlebih dahulu.', 401);
    }

    /** @return array<string,mixed> */
    public static function requireAdmin(): array
    {
        $u = self::requireLogin();
        if ($u['role'] !== 'admin') {
            fail('Hanya admin yang boleh melakukan ini.', 403);
        }
        return $u;
    }

    /** @return array<string,mixed> */
    public static function body(): array
    {
        $d = json_decode((string) file_get_contents('php://input'), true);
        return is_array($d) ? $d : [];
    }

    public static function str(mixed $v): string
    {
        return is_string($v) ? trim($v) : '';
    }
}
