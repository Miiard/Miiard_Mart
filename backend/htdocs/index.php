<?php

declare(strict_types=1);

require_once __DIR__ . '/Rest.php';
require_once __DIR__ . '/Config.php';
require_once __DIR__ . '/vendor/autoload.php';
require_once __DIR__ . '/support/AppSettings.php';
require_once __DIR__ . '/support/Jwt.php';
require_once __DIR__ . '/support/RabbitMq.php';
require_once __DIR__ . '/support/Guard.php';
require_once __DIR__ . '/models/UserStore.php';
require_once __DIR__ . '/controller/AuthController.php';
require_once __DIR__ . '/controller/UserAuthController.php';
require_once __DIR__ . '/controller/AdminController.php';
require_once __DIR__ . '/controller/OrderController.php';
require_once __DIR__ . '/controller/UploadController.php';
require_once __DIR__ . '/controller/ProductController.php';
require_once __DIR__ . '/routes/api.php';

try {
    $authController = new AuthController();
    $controller = new ProductController(Config::database());
    $controller->initialiseDatabase();
    UserStore::ensureSchema();
    registerApiRoutes($controller, $authController, new UserAuthController(), new AdminController(), new OrderController());
} catch (Throwable $exception) {
    error_log($exception->getMessage());
    $status = $exception->getCode() === 503 ? 503 : 500;
    fail($status === 503 ? 'Database connection failed.' : 'Internal server error.', $status);
}
