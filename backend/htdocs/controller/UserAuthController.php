<?php

declare(strict_types=1);

/** Register, login (email + password), profil, lupa & reset password. Terpisah dari AuthController (Google 2FA). */
final class UserAuthController
{
    private static function passwordProblem(mixed $pw): ?string
    {
        if (!is_string($pw) || strlen($pw) < 6) {
            return 'Password minimal 6 karakter.';
        }
        if (strlen($pw) > 72) {
            return 'Password maksimal 72 karakter.';
        }
        if (!preg_match('/[A-Za-z]/', $pw) || !preg_match('/\d/', $pw)) {
            return 'Password harus mengandung huruf dan angka.';
        }
        return null;
    }

    private static function validEmail(string $e): bool
    {
        return strlen($e) <= 190 && preg_match('/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/', $e) === 1;
    }

    public function register(): void
    {
        UserStore::throttle('register', '', 20, 15);
        $b = Guard::body();
        $name = Guard::str($b['name'] ?? null);
        $email = strtolower(Guard::str($b['email'] ?? null));
        if (strlen($name) < 2 || strlen($name) > 100) {
            fail('Nama harus 2–100 karakter.');
        }
        if (!self::validEmail($email)) {
            fail('Format email tidak valid.');
        }
        if ($p = self::passwordProblem($b['password'] ?? null)) {
            fail($p);
        }
        if (UserStore::findByEmail($email)) {
            fail('Email sudah terdaftar.', 409);
        }
        try {
            UserStore::q("INSERT INTO users (name, email, password_hash, role) VALUES (?, ?, ?, 'user')",
                [$name, $email, password_hash((string) $b['password'], PASSWORD_DEFAULT)]);
        } catch (PDOException $e) {
            if ($e->getCode() === '23000') {
                fail('Email sudah terdaftar.', 409);
            }
            throw $e;
        }
        $user = ['id' => (int) UserStore::pdo()->lastInsertId(), 'name' => $name, 'email' => $email, 'role' => 'user'];
        respond(['token' => Jwt::sign($user['id']), 'user' => UserStore::publicUser($user)], 201);
    }

    public function login(): void
    {
        $b = Guard::body();
        $email = strtolower(Guard::str($b['email'] ?? null));
        $pw = is_string($b['password'] ?? null) ? $b['password'] : '';
        if ($email === '' || $pw === '') {
            fail('Isi email dan password.');
        }
        UserStore::throttle('login', $email, 8, 15);
        $u = UserStore::findByEmail($email);
        // hash palsu: waktu respons sama baik email ada maupun tidak
        $ok = password_verify($pw, $u ? (string) $u['password_hash'] : '$2y$10$VS3pTwffixxKmkZMBOmE0u/XVbiJH/SH2QJxd2tgyNeDluSh5avN.');
        if (!$u || !$ok) {
            fail('Email atau password salah.', 401);
        }
        respond(['token' => Jwt::sign((int) $u['id']), 'user' => UserStore::publicUser($u)]);
    }

    public function me(): void
    {
        respond(['user' => UserStore::publicUser(Guard::requireLogin())]);
    }

    public function updateMe(): void
    {
        $u = Guard::requireLogin();
        $name = Guard::str(Guard::body()['name'] ?? null);
        if (strlen($name) < 2 || strlen($name) > 100) {
            fail('Nama harus 2–100 karakter.');
        }
        UserStore::q('UPDATE users SET name = ? WHERE id = ?', [$name, $u['id']]);
        $u['name'] = $name;
        respond(['user' => UserStore::publicUser($u)]);
    }

    /** PUT /auth/avatar  {"image": "<base64 JPEG/PNG/WEBP>"} */
    public function setAvatar(): void
    {
        $u = Guard::requireLogin();
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
        if (strlen($bytes) > 2 * 1024 * 1024) {
            fail('Ukuran foto maksimal 2 MB.', 413);
        }
        $info = @getimagesizefromstring($bytes);
        $mimes = ['image/jpeg', 'image/png', 'image/webp'];
        if (!$info || !in_array($info['mime'], $mimes, true)) {
            fail('Format foto harus JPG, PNG, atau WEBP.');
        }
        UserStore::q('UPDATE users SET avatar = ?, avatar_mime = ?, avatar_v = avatar_v + 1 WHERE id = ?', [$bytes, $info['mime'], $u['id']]);
        respond(['user' => UserStore::publicUser(UserStore::findById((int) $u['id']) ?? $u)]);
    }

    public function removeAvatar(): void
    {
        $u = Guard::requireLogin();
        UserStore::q('UPDATE users SET avatar = NULL, avatar_mime = NULL, avatar_v = 0 WHERE id = ?', [$u['id']]);
        respond(['user' => UserStore::publicUser(UserStore::findById((int) $u['id']) ?? $u)]);
    }

    /** GET /users/{id}/avatar - mengirim gambar langsung. */
    public function avatar(int $id): void
    {
        $row = UserStore::q('SELECT avatar, avatar_mime FROM users WHERE id = ?', [$id])->fetch();
        if (!$row || $row['avatar'] === null) {
            http_response_code(404);
            exit;
        }
        header('Content-Type: ' . $row['avatar_mime']);
        header('Cache-Control: public, max-age=86400');
        header('X-Content-Type-Options: nosniff');
        echo $row['avatar'];
        exit;
    }

    public function forgot(): void
    {
        $email = strtolower(Guard::str(Guard::body()['email'] ?? null));
        if (!self::validEmail($email)) {
            fail('Format email tidak valid.');
        }
        UserStore::throttle('forgot', $email, 5, 15);
        $generic = ['message' => 'Jika email terdaftar, kode reset sudah dikirim.'];
        $u = UserStore::findByEmail($email);
        if (!$u) {
            respond($generic);
        }
        $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        UserStore::q('UPDATE password_resets SET used = 1 WHERE user_id = ? AND used = 0', [$u['id']]);
        UserStore::q('INSERT INTO password_resets (user_id, code_hash, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? MINUTE))',
            [$u['id'], password_hash($code, PASSWORD_DEFAULT), AppSettings::resetMinutes()]);

        $queued = RabbitMq::publish(AppSettings::mqQueue(), [
            'to' => $u['email'],
            'subject' => 'Kode reset password Miiard.Mart',
            'text' => "Halo {$u['name']},\n\nKode reset password kamu: $code\n"
                . 'Berlaku ' . AppSettings::resetMinutes() . " menit. Jangan bagikan kode ini ke siapa pun.\n\n"
                . "Kalau kamu tidak meminta reset, abaikan pesan ini.\n\n— Miiard.Mart",
        ]);
        if (!$queued) {
            error_log('[miiard] gagal mengirim ke RabbitMQ; cek RABBITMQ_USER / RABBITMQ_PASSWORD.');
        }
        respond(AppSettings::devShowCode() ? $generic + ['devCode' => $code] : $generic);
    }

    public function reset(): void
    {
        $b = Guard::body();
        $email = strtolower(Guard::str($b['email'] ?? null));
        $code = Guard::str($b['code'] ?? null);
        if (!self::validEmail($email) || !preg_match('/^\d{6}$/', $code)) {
            fail('Email atau kode tidak valid.');
        }
        if ($p = self::passwordProblem($b['newPassword'] ?? null)) {
            fail($p);
        }
        UserStore::throttle('reset', $email, 10, 15);

        $bad = 'Kode salah atau sudah kedaluwarsa.';
        $u = UserStore::findByEmail($email);
        if (!$u) {
            fail($bad);
        }
        $r = UserStore::q('SELECT * FROM password_resets WHERE user_id = ? AND used = 0 AND expires_at > NOW() ORDER BY id DESC LIMIT 1',
            [$u['id']])->fetch();
        if (!$r || (int) $r['attempts'] >= 5) {
            fail($bad);
        }
        if (!password_verify($code, (string) $r['code_hash'])) {
            UserStore::q('UPDATE password_resets SET attempts = attempts + 1 WHERE id = ?', [$r['id']]);
            fail($bad);
        }
        UserStore::q('UPDATE users SET password_hash = ? WHERE id = ?', [password_hash((string) $b['newPassword'], PASSWORD_DEFAULT), $u['id']]);
        UserStore::q('UPDATE password_resets SET used = 1 WHERE user_id = ?', [$u['id']]);
        respond(['message' => 'Password berhasil diubah. Silakan login.']);
    }
}
