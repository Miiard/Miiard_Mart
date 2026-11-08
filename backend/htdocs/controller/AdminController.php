<?php

declare(strict_types=1);

/** Statistik dan pengelolaan pengguna (khusus admin). CRUD produk tetap di ProductController. */
final class AdminController
{
    public function stats(): void
    {
        Guard::requireAdmin();
        $u = UserStore::q("SELECT COUNT(*) AS users, COALESCE(SUM(role = 'admin'), 0) AS admins FROM users")->fetch();
        $p = UserStore::q('SELECT COUNT(*) AS products, COALESCE(SUM(stock = 0), 0) AS outOfStock, COALESCE(SUM(stock BETWEEN 1 AND 5), 0) AS lowStock FROM products')->fetch();
        respond([
            'users' => (int) $u['users'], 'admins' => (int) $u['admins'],
            'products' => (int) $p['products'], 'outOfStock' => (int) $p['outOfStock'], 'lowStock' => (int) $p['lowStock'],
        ]);
    }

    public function users(): void
    {
        Guard::requireAdmin();
        $rows = UserStore::q('SELECT id, name, email, role, created_at AS createdAt FROM users ORDER BY id')->fetchAll();
        foreach ($rows as &$r) {
            $r['id'] = (int) $r['id'];
        }
        respond(['users' => $rows]);
    }

    public function setRole(int $id): void
    {
        $me = Guard::requireAdmin();
        $role = Guard::body()['role'] ?? null;
        if (!in_array($role, ['user', 'admin'], true)) {
            fail('Role harus user atau admin.');
        }
        if ($id === (int) $me['id']) {
            fail('Kamu tidak bisa mengubah role akunmu sendiri.');
        }
        if (!UserStore::findById($id)) {
            fail('Pengguna tidak ditemukan.', 404);
        }
        UserStore::q('UPDATE users SET role = ? WHERE id = ?', [$role, $id]);
        respond(['id' => $id, 'role' => $role]);
    }

    public function deleteUser(int $id): void
    {
        $me = Guard::requireAdmin();
        if ($id === (int) $me['id']) {
            fail('Kamu tidak bisa menghapus akunmu sendiri.');
        }
        if (!UserStore::q('DELETE FROM users WHERE id = ?', [$id])->rowCount()) {
            fail('Pengguna tidak ditemukan.', 404);
        }
        UserStore::q('DELETE FROM password_resets WHERE user_id = ?', [$id]);
        respond(['id' => $id, 'isDeleted' => true]);
    }
}
