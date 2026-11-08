<?php

declare(strict_types=1);

function registerApiRoutes(
    ProductController $controller,
    AuthController $authController,
    UserAuthController $userAuth,
    AdminController $admin,
    OrderController $orders
): void {
    $method = $_SERVER['REQUEST_METHOD'];
    $path = trim(parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/', '/');
    $segments = $path === '' ? [] : explode('/', $path);

    // GET /login - detail konfigurasi TOTP dan QR code untuk Google Authenticator.
    if ($segments === ['login'] && $method === 'GET') {
        $authController->setup();
    }
    // POST /login - verifikasi kode 6 digit Google Authenticator.
    if ($segments === ['login'] && $method === 'POST') {
        $authController->login();
    }
    if ($segments === ['login']) {
        fail('Method not allowed.', 405);
    }

    // GET / - halaman login.
    if ($segments === [] && $method === 'GET') {
        header('Content-Type: text/html; charset=utf-8');
        require __DIR__ . '/../views/LoginView.php';
        return;
    }
    // GET /health - health check service.
    if ($segments === ['health']) {
        respond(['status' => 'ok', 'service' => 'products-api']);
    }

    // ---------- akun pengguna (aplikasi Flutter) ----------
    if (($segments[0] ?? '') === 'auth' && count($segments) === 2) {
        $action = $segments[1];
        if ($action === 'register' && $method === 'POST') { $userAuth->register(); }
        if ($action === 'login' && $method === 'POST') { $userAuth->login(); }
        if ($action === 'me' && $method === 'GET') { $userAuth->me(); }
        if ($action === 'me' && $method === 'PUT') { $userAuth->updateMe(); }
        if ($action === 'avatar' && in_array($method, ['PUT', 'POST'], true)) { $userAuth->setAvatar(); }
        if ($action === 'avatar' && $method === 'DELETE') { $userAuth->removeAvatar(); }
        if ($action === 'forgot' && $method === 'POST') { $userAuth->forgot(); }
        if ($action === 'reset' && $method === 'POST') { $userAuth->reset(); }
        fail('Route not found.', 404);
    }

    // GET /users/{id}/avatar - foto profil.
    if (count($segments) === 3 && $segments[0] === 'users' && ctype_digit($segments[1]) && $segments[2] === 'avatar' && $method === 'GET') {
        $userAuth->avatar((int) $segments[1]);
    }

    // ---------- foto produk dari galeri ----------
    if (($segments[0] ?? '') === 'uploads') {
        $uploads = new UploadController();
        if ($segments === ['uploads', 'product'] && $method === 'POST') {
            Guard::requireAdmin();
            $uploads->storeProduct();
        }
        if (count($segments) === 3 && $segments[1] === 'product' && ctype_digit($segments[2]) && $method === 'GET') {
            $uploads->showProduct((int) $segments[2]);
        }
        fail('Route not found.', 404);
    }

    // ---------- admin: statistik & pengguna ----------
    if (($segments[0] ?? '') === 'admin') {
        if ($segments === ['admin', 'stats'] && $method === 'GET') { $admin->stats(); }
        if ($segments === ['admin', 'users'] && $method === 'GET') { $admin->users(); }
        if ($segments === ['admin', 'orders'] && $method === 'GET') { $orders->adminList(); }
        if (count($segments) === 3 && $segments[1] === 'orders' && ctype_digit($segments[2])
            && in_array($method, ['PATCH', 'PUT'], true)) { $orders->adminSetStatus((int) $segments[2]); }
        if (count($segments) === 3 && $segments[1] === 'users' && ctype_digit($segments[2])) {
            if (in_array($method, ['PATCH', 'PUT'], true)) { $admin->setRole((int) $segments[2]); }
            if ($method === 'DELETE') { $admin->deleteUser((int) $segments[2]); }
        }
        fail('Route not found.', 404);
    }

    // ---------- pesanan (checkout) ----------
    if (($segments[0] ?? '') === 'orders') {
        if ($segments === ['orders'] && $method === 'POST') { $orders->create(); }
        if ($segments === ['orders'] && $method === 'GET') { $orders->mine(); }
        if (count($segments) === 2 && ctype_digit($segments[1]) && $method === 'GET') { $orders->show((int) $segments[1]); }
        if (count($segments) === 3 && ctype_digit($segments[1]) && $segments[2] === 'cancel' && $method === 'POST') {
            $orders->cancel((int) $segments[1]);
        }
        fail('Route not found.', 404);
    }

    if (($segments[0] ?? '') !== 'products') {
        fail('Route not found.', 404);
    }

    // GET /products/search?q= - pencarian (dipakai aplikasi).
    if ($method === 'GET' && $segments === ['products', 'search']) {
        $controller->index();
    }
    // GET /products/categories - daftar kategori dengan slug dan URL.
    if ($method === 'GET' && ($segments[1] ?? '') === 'categories') {
        $controller->categories();
    }
    // GET /products/category-list - daftar nilai kategori.
    if ($method === 'GET' && ($segments[1] ?? '') === 'category-list') {
        $controller->categoryList();
    }
    // GET /products/category/{category} - produk berdasarkan kategori.
    if ($method === 'GET' && ($segments[1] ?? '') === 'category' && isset($segments[2])) {
        $_GET['category'] = $segments[2];
        $controller->index();
    }
    // GET /products/{id} - detail satu produk.
    if ($method === 'GET' && isset($segments[1]) && ctype_digit($segments[1])) {
        $controller->show((int) $segments[1]);
    }
    // GET /products - daftar produk dengan filter, sorting, dan pagination.
    if ($method === 'GET' && count($segments) === 1) {
        $controller->index();
    }
    // POST /products atau POST /products/add - tambah produk (ADMIN).
    if ($method === 'POST' && (($segments[1] ?? '') === 'add' || !isset($segments[1]))) {
        Guard::requireAdmin();
        $controller->store();
    }
    // PUT/PATCH /products/{id} - ubah produk (ADMIN).
    if (in_array($method, ['PUT', 'PATCH'], true) && isset($segments[1]) && ctype_digit($segments[1])) {
        Guard::requireAdmin();
        $controller->update((int) $segments[1]);
    }
    // DELETE /products/{id} - hapus produk (ADMIN).
    if ($method === 'DELETE' && isset($segments[1]) && ctype_digit($segments[1])) {
        Guard::requireAdmin();
        $controller->destroy((int) $segments[1]);
    }

    fail('Route not found.', 404);
}
