<?php

declare(strict_types=1);

/** JWT HS256 sederhana (tanpa library tambahan). */
final class Jwt
{
    private static function enc(string $s): string
    {
        return rtrim(strtr(base64_encode($s), '+/', '-_'), '=');
    }

    private static function dec(string $s): string
    {
        return (string) base64_decode(strtr($s, '-_', '+/'));
    }

    public static function sign(int $userId): string
    {
        $head = self::enc(json_encode(['alg' => 'HS256', 'typ' => 'JWT'], JSON_THROW_ON_ERROR));
        $pay = self::enc(json_encode(['sub' => $userId, 'exp' => time() + 86400 * AppSettings::jwtDays()], JSON_THROW_ON_ERROR));
        $sig = self::enc(hash_hmac('sha256', "$head.$pay", AppSettings::jwtSecret(), true));
        return "$head.$pay.$sig";
    }

    /** @return array<string,mixed>|null */
    public static function verify(string $token): ?array
    {
        $p = explode('.', $token);
        if (count($p) !== 3) {
            return null;
        }
        $calc = self::enc(hash_hmac('sha256', "$p[0].$p[1]", AppSettings::jwtSecret(), true));
        if (!hash_equals($calc, $p[2])) {
            return null;
        }
        $data = json_decode(self::dec($p[1]), true);
        if (!is_array($data) || (int) ($data['exp'] ?? 0) < time()) {
            return null;
        }
        return $data;
    }
}
