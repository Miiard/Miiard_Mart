<?php

declare(strict_types=1);

/**
 * RabbitMQ lewat HTTP Management API (port 15672), jadi tidak perlu library AMQP di vendor.
 */
final class RabbitMq
{
    /** @return array{0:int,1:mixed} */
    public static function request(string $method, string $path, mixed $json = null): array
    {
        $url = 'http://' . AppSettings::mqHost() . ':' . AppSettings::mqPort() . '/api' . $path;
        $headers = 'Authorization: Basic ' . base64_encode(AppSettings::mqUser() . ':' . AppSettings::mqPass()) . "\r\n"
            . "Content-Type: application/json\r\n";
        $ctx = stream_context_create(['http' => [
            'method' => $method,
            'header' => $headers,
            'content' => $json === null ? '' : json_encode($json),
            'timeout' => 4,
            'ignore_errors' => true,
        ]]);
        $res = @file_get_contents($url, false, $ctx);
        $status = 0;
        if (isset($http_response_header[0]) && preg_match('#\s(\d{3})\s#', $http_response_header[0], $m)) {
            $status = (int) $m[1];
        }
        return [$status, $res === false ? null : json_decode($res, true)];
    }

    /** @param array<string,mixed> $message */
    public static function publish(string $queue, array $message): bool
    {
        $vh = rawurlencode(AppSettings::mqVhost());
        [$s] = self::request('PUT', "/queues/$vh/$queue", ['durable' => true, 'auto_delete' => false]);
        if ($s < 200 || $s >= 300) {
            return false;
        }
        [$s, $r] = self::request('POST', "/exchanges/$vh/amq.default/publish", [
            'properties' => ['delivery_mode' => 2],
            'routing_key' => $queue,
            'payload' => json_encode($message, JSON_UNESCAPED_UNICODE),
            'payload_encoding' => 'string',
        ]);
        return $s === 200 && is_array($r) && !empty($r['routed']);
    }
}
