<?php

declare(strict_types=1);

/** Checkout, riwayat pesanan pengguna, dan pengelolaan pesanan oleh admin. */
final class OrderController
{
    public const STATUSES = ['menunggu', 'diproses', 'dikirim', 'selesai', 'dibatalkan'];

    /** kode => [label, kelompok] */
    private const METHODS = [
        'bca' => ['Transfer BCA', 'bank'],
        'mandiri' => ['Transfer Mandiri', 'bank'],
        'bni' => ['Transfer BNI', 'bank'],
        'gopay' => ['GoPay', 'ewallet'],
        'ovo' => ['OVO', 'ewallet'],
        'dana' => ['DANA', 'ewallet'],
        'qris' => ['QRIS', 'qris'],
        'cod' => ['Bayar di tempat (COD)', 'cod'],
    ];

    private PDO $pdo;

    public function __construct()
    {
        $this->pdo = Config::database();
    }

    // ---------- pengguna ----------

    public function create(): void
    {
        $user = Guard::requireLogin();
        $b = Guard::body();

        $method = Guard::str($b['paymentMethod'] ?? null);
        if (!isset(self::METHODS[$method])) {
            fail('Pilih metode pembayaran.');
        }
        $name = Guard::str($b['shipName'] ?? null);
        $phone = Guard::str($b['shipPhone'] ?? null);
        $address = Guard::str($b['shipAddress'] ?? null);
        if (strlen($name) < 2 || strlen($name) > 100) {
            fail('Nama penerima harus 2–100 karakter.');
        }
        if (!preg_match('/^[0-9+\-\s]{8,20}$/', $phone)) {
            fail('Nomor telepon tidak valid.');
        }
        if (strlen($address) < 10 || strlen($address) > 500) {
            fail('Alamat minimal 10 karakter.');
        }

        // gabungkan produk yang sama
        $wanted = [];
        foreach (is_array($b['items'] ?? null) ? $b['items'] : [] as $it) {
            $pid = (int) ($it['productId'] ?? 0);
            $qty = (int) ($it['quantity'] ?? 0);
            if ($pid <= 0 || $qty < 1 || $qty > 99) {
                fail('Data barang tidak valid.');
            }
            $wanted[$pid] = ($wanted[$pid] ?? 0) + $qty;
        }
        if (!$wanted || count($wanted) > 50) {
            fail('Keranjang kosong atau terlalu banyak barang.');
        }
        ksort($wanted); // urutan kunci konsisten agar tidak deadlock

        $label = self::METHODS[$method][0];
        $initial = self::METHODS[$method][1] === 'cod' ? 'diproses' : 'menunggu';

        $this->pdo->beginTransaction();
        try {
            $lines = [];
            $total = 0.0;
            $original = 0.0;
            foreach ($wanted as $pid => $qty) {
                $st = $this->pdo->prepare('SELECT id, title, price, discount_percentage, stock, thumbnail FROM products WHERE id = ? FOR UPDATE');
                $st->execute([$pid]);
                $p = $st->fetch();
                if (!$p) {
                    throw new RuntimeException("Produk #$pid sudah tidak tersedia.");
                }
                if ((int) $p['stock'] < $qty) {
                    throw new RuntimeException('Stok "' . $p['title'] . '" tinggal ' . (int) $p['stock'] . '.');
                }
                $price = (float) $p['price'];
                $unit = round($price * (1 - ((float) $p['discount_percentage']) / 100), 2);
                $total += $unit * $qty;
                $original += $price * $qty;
                $lines[] = [$pid, (string) $p['title'], $p['thumbnail'], $unit, $qty];
                $this->pdo->prepare('UPDATE products SET stock = stock - ? WHERE id = ?')->execute([$qty, $pid]);
            }
            $this->pdo->prepare('INSERT INTO orders (user_id, total, original_total, payment_method, payment_label, status, ship_name, ship_phone, ship_address) VALUES (?,?,?,?,?,?,?,?,?)')
                ->execute([$user['id'], round($total, 2), round($original, 2), $method, $label, $initial, $name, $phone, $address]);
            $orderId = (int) $this->pdo->lastInsertId();
            $ins = $this->pdo->prepare('INSERT INTO order_items (order_id, product_id, title, thumbnail, price, quantity) VALUES (?,?,?,?,?,?)');
            foreach ($lines as $l) {
                $ins->execute([$orderId, $l[0], $l[1], $l[2], $l[3], $l[4]]);
            }
            $this->pdo->commit();
        } catch (RuntimeException $e) {
            $this->pdo->rollBack();
            fail($e->getMessage(), 409);
        } catch (Throwable $e) {
            $this->pdo->rollBack();
            throw $e;
        }
        respond($this->load($orderId), 201);
    }

    public function mine(): void
    {
        $user = Guard::requireLogin();
        $ids = $this->pdo->prepare('SELECT id FROM orders WHERE user_id = ? ORDER BY id DESC LIMIT 100');
        $ids->execute([$user['id']]);
        respond(['orders' => $this->loadMany($ids->fetchAll(PDO::FETCH_COLUMN))]);
    }

    public function show(int $id): void
    {
        $user = Guard::requireLogin();
        $o = $this->load($id);
        if ($o['userId'] !== (int) $user['id'] && $user['role'] !== 'admin') {
            fail('Pesanan tidak ditemukan.', 404);
        }
        respond($o);
    }

    public function cancel(int $id): void
    {
        $user = Guard::requireLogin();
        $o = $this->load($id);
        if ($o['userId'] !== (int) $user['id']) {
            fail('Pesanan tidak ditemukan.', 404);
        }
        if ($o['status'] !== 'menunggu') {
            fail('Hanya pesanan yang menunggu pembayaran yang bisa dibatalkan.', 409);
        }
        $this->changeStatus($id, 'dibatalkan');
        respond($this->load($id));
    }

    // ---------- admin ----------

    public function adminList(): void
    {
        Guard::requireAdmin();
        $ids = $this->pdo->query('SELECT id FROM orders ORDER BY id DESC LIMIT 200')->fetchAll(PDO::FETCH_COLUMN);
        respond(['orders' => $this->loadMany($ids)]);
    }

    public function adminSetStatus(int $id): void
    {
        Guard::requireAdmin();
        $status = Guard::body()['status'] ?? null;
        if (!is_string($status) || !in_array($status, self::STATUSES, true)) {
            fail('Status tidak valid.');
        }
        $o = $this->load($id);
        if ($o['status'] === 'dibatalkan') {
            fail('Pesanan yang sudah dibatalkan tidak bisa diubah lagi.', 409);
        }
        $this->changeStatus($id, $status);
        respond($this->load($id));
    }

    // ---------- internal ----------

    /** Ubah status; bila dibatalkan, stok dikembalikan (sekali saja, dalam transaksi). */
    private function changeStatus(int $id, string $status): void
    {
        $this->pdo->beginTransaction();
        try {
            $st = $this->pdo->prepare('SELECT status FROM orders WHERE id = ? FOR UPDATE');
            $st->execute([$id]);
            $cur = $st->fetchColumn();
            if ($cur === false) {
                throw new RuntimeException('Pesanan tidak ditemukan.');
            }
            if ($cur === 'dibatalkan') {
                throw new RuntimeException('Pesanan sudah dibatalkan.');
            }
            if ($status === 'dibatalkan') {
                $items = $this->pdo->prepare('SELECT product_id, quantity FROM order_items WHERE order_id = ?');
                $items->execute([$id]);
                foreach ($items->fetchAll() as $it) {
                    $this->pdo->prepare('UPDATE products SET stock = stock + ? WHERE id = ?')->execute([$it['quantity'], $it['product_id']]);
                }
            }
            $this->pdo->prepare('UPDATE orders SET status = ? WHERE id = ?')->execute([$status, $id]);
            $this->pdo->commit();
        } catch (RuntimeException $e) {
            $this->pdo->rollBack();
            fail($e->getMessage(), 409);
        } catch (Throwable $e) {
            $this->pdo->rollBack();
            throw $e;
        }
    }

    /** @return array<string,mixed> */
    private function load(int $id): array
    {
        $rows = $this->loadMany([$id]);
        return $rows[0] ?? fail('Pesanan tidak ditemukan.', 404);
    }

    /** @param array<int,mixed> $ids @return array<int,array<string,mixed>> */
    private function loadMany(array $ids): array
    {
        $ids = array_map('intval', $ids);
        if (!$ids) {
            return [];
        }
        $in = implode(',', array_fill(0, count($ids), '?'));
        $st = $this->pdo->prepare("SELECT o.*, u.name AS user_name, u.email AS user_email FROM orders o LEFT JOIN users u ON u.id = o.user_id WHERE o.id IN ($in) ORDER BY o.id DESC");
        $st->execute($ids);
        $orders = $st->fetchAll();

        $it = $this->pdo->prepare("SELECT order_id, product_id, title, thumbnail, price, quantity FROM order_items WHERE order_id IN ($in) ORDER BY id");
        $it->execute($ids);
        $byOrder = [];
        foreach ($it->fetchAll() as $row) {
            $byOrder[(int) $row['order_id']][] = [
                'productId' => (int) $row['product_id'],
                'title' => $row['title'],
                'thumbnail' => $row['thumbnail'],
                'price' => (float) $row['price'],
                'quantity' => (int) $row['quantity'],
            ];
        }

        $out = [];
        foreach ($orders as $o) {
            $oid = (int) $o['id'];
            $out[] = [
                'id' => $oid,
                'code' => 'MM-' . str_pad((string) $oid, 6, '0', STR_PAD_LEFT),
                'userId' => (int) $o['user_id'],
                'userName' => $o['user_name'],
                'userEmail' => $o['user_email'],
                'status' => $o['status'],
                'paymentMethod' => $o['payment_method'],
                'paymentLabel' => $o['payment_label'],
                'total' => (float) $o['total'],
                'originalTotal' => (float) $o['original_total'],
                'shipName' => $o['ship_name'],
                'shipPhone' => $o['ship_phone'],
                'shipAddress' => $o['ship_address'],
                'createdAt' => $o['created_at'],
                'items' => $byOrder[$oid] ?? [],
            ];
        }
        return $out;
    }
}
