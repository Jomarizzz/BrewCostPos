<?php
/**
 * Brew Haven POS API v3 — XAMPP (Apache + MySQL + PHP)
 *
 * Setup: copy folder → C:\xampp\htdocs\pos\  ·  import database.sql  ·  open /pos/
 *
 * Actions:
 *   health | session | login | logout
 *   load | order_create | order_status
 *   menu_save | menu_delete | ingredient_save | ingredient_delete
 *   stock_restock | recipe_save
 *
 * Security:
 *   - PHP sessions; passwords stored with password_hash() (bcrypt)
 *   - Admin actions require a logged-in admin session
 *   - Login code + password verified with password_verify(); 0.4s delay on failure
 */

/* never let warnings/notices corrupt the JSON response */
ini_set('display_errors', '0');
error_reporting(E_ALL);

session_start([
    'cookie_httponly' => true,
    'cookie_samesite' => 'Lax',
    'use_strict_mode' => true,
]);

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('Access-Control-Allow-Origin: ' . (isset($_SERVER['HTTP_ORIGIN']) ? $_SERVER['HTTP_ORIGIN'] : '*'));
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

const DB_HOST = '127.0.0.1';
const DB_NAME = 'pos_db';
const DB_USER = 'root';
const DB_PASS = '';
const SERVICE_RATE = 0.05;

/* fallback credentials — used when staff table has no hashes yet or is missing */
const FALLBACK_ADMIN_USER = 'admin';
const FALLBACK_ADMIN_PASS = 'admin123';
const FALLBACK_CASHIER_CODE = '1234';

function db(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $dsn = 'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4';
        $pdo = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]);
    }
    return $pdo;
}

function out($data, int $code = 200): void {
    http_response_code($code);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}
function fail(string $msg, int $code = 400): void { out(['error' => $msg], $code); }

/* any uncaught exception → JSON, never an HTML error page */
set_exception_handler(function ($e) {
    http_response_code(500);
    echo json_encode(['error' => 'Server error: ' . $e->getMessage()],
        JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
});

function body(): array {
    $raw = file_get_contents('php://input');
    if ($raw === '' || $raw === false) return [];
    $d = json_decode($raw, true);
    return is_array($d) ? $d : [];
}

/* ================= auth helpers ================= */

/** First run: fill in bcrypt hashes for seeded staff rows. */
function ensureStaff(): void {
    try {
        $pdo = db();
        $admin = $pdo->query("SELECT id FROM staff WHERE role='admin' AND (password_hash IS NULL OR password_hash='') LIMIT 1")->fetch();
        if ($admin) {
            $pdo->prepare('UPDATE staff SET password_hash=? WHERE id=?')
                ->execute([password_hash(FALLBACK_ADMIN_PASS, PASSWORD_DEFAULT), $admin['id']]);
        }
        $cashier = $pdo->query("SELECT id FROM staff WHERE role='cashier' AND (access_code_hash IS NULL OR access_code_hash='') LIMIT 1")->fetch();
        if ($cashier) {
            $pdo->prepare('UPDATE staff SET access_code_hash=? WHERE id=?')
                ->execute([password_hash(FALLBACK_CASHIER_CODE, PASSWORD_DEFAULT), $cashier['id']]);
        }
    } catch (PDOException $e) {
        // staff table missing (old import) → fallback constants still work
    }
}

function requireSession(): array {
    if (empty($_SESSION['role'])) fail('Not signed in.', 401);
    return $_SESSION;
}

function requireAdmin(): array {
    $s = requireSession();
    if (($s['role'] ?? '') !== 'admin') fail('Admin access required.', 403);
    return $s;
}

function actionSession(): void {
    if (empty($_SESSION['role'])) out(['ok' => false]);
    out([
        'ok' => true,
        'role' => $_SESSION['role'],
        'name' => $_SESSION['name'] ?? '',
    ]);
}

function actionLogin(): void {
    ensureStaff();
    $b = body();
    $mode = $b['mode'] ?? '';

    if ($mode === 'admin') {
        $username = trim((string)($b['username'] ?? ''));
        $password = (string)($b['password'] ?? '');
        if ($username === '' || $password === '') fail('Enter username and password.');

        $hash = null;
        try {
            $stmt = db()->prepare("SELECT id, name, password_hash FROM staff WHERE role='admin' AND username=? LIMIT 1");
            $stmt->execute([$username]);
            $row = $stmt->fetch();
            if ($row) $hash = $row['password_hash'];
        } catch (PDOException $e) { /* fallback below */ }

        if ($hash) {
            $ok = password_verify($password, $hash);
        } else {
            /* no DB row yet → built-in defaults (first run) */
            $ok = hash_equals(FALLBACK_ADMIN_USER, $username) && hash_equals(FALLBACK_ADMIN_PASS, $password);
        }
        if (!$ok) {
            usleep(400000); // slow brute force slightly
            fail('Invalid username or password.', 401);
        }
        session_regenerate_id(true);
        $_SESSION['role'] = 'admin';
        $_SESSION['name'] = $row['name'] ?? 'Admin';
        out(['ok' => true, 'role' => 'admin', 'name' => $_SESSION['name']]);
    }

    if ($mode === 'cashier') {
        $name = trim((string)($b['name'] ?? ''));
        $code = (string)($b['code'] ?? '');
        if ($name === '' || $code === '') fail('Enter your name and access code.');

        $hash = null;
        try {
            $stmt = db()->query("SELECT access_code_hash FROM staff WHERE role='cashier' LIMIT 1");
            $row = $stmt->fetch();
            if ($row) $hash = $row['access_code_hash'];
        } catch (PDOException $e) { /* fallback below */ }

        $ok = $hash ? password_verify($code, $hash) : hash_equals(FALLBACK_CASHIER_CODE, $code);
        if (!$ok) {
            usleep(400000);
            fail('Invalid access code.', 401);
        }
        session_regenerate_id(true);
        $_SESSION['role'] = 'cashier';
        $_SESSION['name'] = $name;
        out(['ok' => true, 'role' => 'cashier', 'name' => $name]);
    }

    fail('Unknown login mode.');
}

function actionLogout(): void {
    $_SESSION = [];
    if (ini_get('session.use_cookies')) {
        $p = session_get_cookie_params();
        setcookie(session_name(), '', time() - 42000, $p['path'], $p['domain'], $p['secure'], $p['httponly']);
    }
    session_destroy();
    out(['ok' => true]);
}

/* ================= load: everything the app needs ================= */
function actionLoad(): void {
    requireSession();
    $pdo = db();

    $menu = $pdo->query(
        'SELECT id, name, category, price, description, icon, available FROM menu_items
         ORDER BY FIELD(category,"Coffee","Non-coffee","Pastries","Meals"), name'
    )->fetchAll();
    foreach ($menu as &$m) { $m['price'] = (float)$m['price']; $m['available'] = (bool)$m['available']; }
    unset($m);

    // payment_ref is optional: older databases may not have the column yet
    $hasRef = (bool)$pdo->query("SHOW COLUMNS FROM orders LIKE 'payment_ref'")->fetch();
    $refCol = $hasRef ? 'o.payment_ref' : 'NULL AS payment_ref';

    $orders = $pdo->query(
        "SELECT o.id, o.number, o.type, o.status, o.payment, $refCol, o.received, o.subtotal, o.total,
                o.order_date AS date,
                DATE_FORMAT(o.created_at, '%H:%i') AS time,
                DATE(o.created_at) AS day
         FROM orders o ORDER BY o.id DESC LIMIT 200"
    )->fetchAll();
    if ($orders) {
        $ids = array_column($orders, 'id');
        $ph  = implode(',', array_fill(0, count($ids), '?'));
        $stmt = $pdo->prepare("SELECT order_id, menu_item_id, name, price, qty FROM order_items WHERE order_id IN ($ph) ORDER BY id");
        $stmt->execute($ids);
        $by = [];
        foreach ($stmt->fetchAll() as $r) {
            $by[$r['order_id']][] = [
                'id' => (int)$r['menu_item_id'], 'name' => $r['name'],
                'price' => (float)$r['price'], 'qty' => (int)$r['qty'],
            ];
        }
        foreach ($orders as &$o) {
            $o['items'] = $by[$o['id']] ?? [];
            $o['total'] = (float)$o['total'];
            $o['subtotal'] = (float)$o['subtotal'];
            $o['received'] = $o['received'] !== null ? (float)$o['received'] : null;
        }
        unset($o);
    }

    $ingredients = $pdo->query(
        'SELECT id, name, unit, purchase_qty, purchase_price, stock, reorder_level, updated_at
         FROM ingredients ORDER BY name'
    )->fetchAll();
    foreach ($ingredients as &$g) {
        $g['purchase_qty']   = (float)$g['purchase_qty'];
        $g['purchase_price'] = (float)$g['purchase_price'];
        $g['stock']          = (float)$g['stock'];
        $g['reorder_level']  = (float)$g['reorder_level'];
        $g['unit_cost'] = $g['purchase_qty'] > 0 ? $g['purchase_price'] / $g['purchase_qty'] : 0;
        $g['low'] = $g['stock'] <= $g['reorder_level'];
    }
    unset($g);

    $recipes = [];
    foreach ($pdo->query('SELECT menu_item_id, ingredient_id, quantity FROM recipes')->fetchAll() as $r) {
        $recipes[(int)$r['menu_item_id']][] = [
            'ingredientId' => (int)$r['ingredient_id'],
            'quantity'     => (float)$r['quantity'],
        ];
    }

    $movements = $pdo->query(
        'SELECT m.id, m.ingredient_id, i.name AS ingredient, m.`change`, m.reason, m.order_id,
                DATE_FORMAT(m.created_at, "%d %b %H:%i") AS at
         FROM stock_movements m JOIN ingredients i ON i.id = m.ingredient_id
         ORDER BY m.id DESC LIMIT 50'
    )->fetchAll();
    foreach ($movements as &$mv) { $mv['change'] = (float)$mv['change']; }
    unset($mv);

    out([
        'ok' => true,
        'menu' => $menu,
        'orders' => $orders,
        'ingredients' => $ingredients,
        'recipes' => $recipes,
        'movements' => $movements,
    ]);
}

/* ================= order_create (+ realtime stock deduction) ================= */
function actionOrderCreate(): void {
    requireSession();
    $b = body();
    $items = $b['items'] ?? null;
    if (!is_array($items) || !$items) fail('Order has no items.');

    $pdo = db();
    $pdo->beginTransaction();
    try {
        $ids = array_values(array_unique(array_filter(array_map(fn($i) => (int)($i['id'] ?? 0), $items))));
        if (!$ids) fail('Invalid items.');

        $ph = implode(',', array_fill(0, count($ids), '?'));
        $stmt = $pdo->prepare("SELECT id, name, price, available FROM menu_items WHERE id IN ($ph)");
        $stmt->execute($ids);
        $catalog = [];
        foreach ($stmt->fetchAll() as $r) {
            $r['price'] = (float)$r['price'];
            $r['available'] = (bool)$r['available'];
            $catalog[(int)$r['id']] = $r;
        }

        $subtotal = 0.0;
        $lines = [];
        foreach ($items as $line) {
            $id  = (int)($line['id'] ?? 0);
            $qty = max(1, (int)($line['qty'] ?? 1));
            if (!isset($catalog[$id]) || !$catalog[$id]['available']) throw new Exception('Item unavailable: #' . $id);
            $p = $catalog[$id];
            $subtotal += $p['price'] * $qty;
            $lines[] = ['id' => $id, 'name' => $p['name'], 'price' => $p['price'], 'qty' => $qty];
        }

        // Aggregate the whole order first, then lock ingredients in a consistent
        // order. This prevents concurrent checkouts from overselling stock.
        $recCheck = $pdo->prepare('SELECT ingredient_id, quantity FROM recipes WHERE menu_item_id = ?');
        $needed = [];
        foreach ($lines as $line) {
            $recCheck->execute([$line['id']]);
            $recipe = $recCheck->fetchAll();
            if (!$recipe) throw new DomainException($line['name'] . ' has no recipe. Ask admin to set it up.');
            foreach ($recipe as $r) {
                $ingredientId = (int)$r['ingredient_id'];
                $quantity = (float)$r['quantity'];
                if ($ingredientId <= 0 || $quantity <= 0) throw new DomainException($line['name'] . ' has an invalid recipe.');
                $needed[$ingredientId] = ($needed[$ingredientId] ?? 0) + $quantity * $line['qty'];
            }
        }
        ksort($needed, SORT_NUMERIC);
        $lock = $pdo->prepare('SELECT id, name, stock, reorder_level FROM ingredients WHERE id = ? FOR UPDATE');
        foreach ($needed as $ingredientId => $amount) {
            $lock->execute([$ingredientId]);
            $g = $lock->fetch();
            if (!$g) throw new DomainException('Recipe ingredient not found. Ask admin to check it.');
            if ((float)$g['stock'] <= (float)$g['reorder_level'])
                throw new DomainException('Product unavailable: restock ' . $g['name'] . '.');
            if ($amount > (float)$g['stock'] + 0.000001)
                throw new DomainException('Not enough ' . $g['name'] . ' for this order. Restock or reduce quantity.');
        }

        $service = round($subtotal * SERVICE_RATE, 2);
        $total   = round($subtotal + $service, 2);

        $max = (int)$pdo->query('SELECT COALESCE(MAX(id),0) FROM orders')->fetchColumn();
        $number = str_pad((string)($max + 1), 2, '0', STR_PAD_LEFT);

        $typeRaw = $b['type'] ?? '';
        // accept the current wording and the earlier one, so old/new index.html both work
        $type    = in_array($typeRaw, ['Dine in', 'Takeout', 'Take out'], true)
                   ? ($typeRaw === 'Take out' ? 'Takeout' : $typeRaw)
                   : 'Dine in';
        $payment = in_array($b['payment'] ?? '', ['Cash', 'GCash', 'Card'], true) ? $b['payment'] : null;
        $received = (isset($b['received']) && $b['received'] !== null && $b['received'] !== '' && is_numeric($b['received']))
            ? (float)$b['received'] : null;
        if ($payment === null) {
            $pdo->rollBack();
            fail('Select a valid payment method.', 400);
        }
        if ($payment === 'Cash' && ($received === null || !is_finite($received) || $received < $total)) {
            $pdo->rollBack();
            fail('Cash received must be at least the order total.', 400);
        }
        if ($payment !== 'Cash') $received = null;

        // payment reference (optional): GCash ref no. or card/QR approval code
        $ref = isset($b['ref']) && is_string($b['ref']) ? trim(substr($b['ref'], 0, 40)) : '';
        if ($ref === '' || !in_array($payment, ['GCash', 'Card'], true)) { $ref = null; }

        $hasRefCol = (bool)$pdo->query("SHOW COLUMNS FROM orders LIKE 'payment_ref'")->fetch();
        if ($hasRefCol) {
            $ins = $pdo->prepare(
                'INSERT INTO orders (number, type, status, payment, payment_ref, received, subtotal, total, order_date)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
            );
            $ins->execute([$number, $type, 'pending', $payment, $ref, $received, $subtotal, $total, date('Y-m-d')]);
        } else {
            $ins = $pdo->prepare(
                'INSERT INTO orders (number, type, status, payment, received, subtotal, total, order_date)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
            );
            $ins->execute([$number, $type, 'pending', $payment, $received, $subtotal, $total, date('Y-m-d')]);
        }
        $orderId = (int)$pdo->lastInsertId();

        $itemStmt = $pdo->prepare(
            'INSERT INTO order_items (order_id, menu_item_id, name, price, qty) VALUES (?, ?, ?, ?, ?)'
        );
        $recStmt  = $pdo->prepare('SELECT ingredient_id, quantity FROM recipes WHERE menu_item_id = ?');
        $useStmt  = $pdo->prepare('UPDATE ingredients SET stock = stock - ? WHERE id = ?');
        $movStmt  = $pdo->prepare(
            'INSERT INTO stock_movements (ingredient_id, `change`, reason, order_id) VALUES (?, ?, "order", ?)'
        );

        foreach ($lines as $l) {
            $itemStmt->execute([$orderId, $l['id'], $l['name'], $l['price'], $l['qty']]);

            // realtime ingredient deduction
            $recStmt->execute([$l['id']]);
            foreach ($recStmt->fetchAll() as $rec) {
                $used = round((float)$rec['quantity'] * $l['qty'], 3);
                if ($used <= 0) continue;
                $useStmt->execute([$used, (int)$rec['ingredient_id']]);
                $movStmt->execute([(int)$rec['ingredient_id'], -$used, $orderId]);
            }
        }

        $pdo->commit();
        out([
            'ok' => true, 'id' => $orderId, 'number' => $number, 'status' => 'pending',
            'subtotal' => $subtotal, 'service' => $service, 'total' => $total, 'ref' => $ref, 'items' => $lines,
        ]);
    } catch (Throwable $e) {
        $pdo->rollBack();
        fail($e->getMessage(), $e instanceof DomainException ? 409 : 500);
    }
}

/* ================= order_status ================= */
function actionOrderStatus(): void {
    requireSession();
    $b = body();
    $id = (int)($b['id'] ?? 0);
    $status = $b['status'] ?? '';
    if ($id <= 0) fail('Missing order id.');
    if (!in_array($status, ['pending', 'ready', 'paid', 'cancelled'], true)) fail('Invalid status.');
    $stmt = db()->prepare('UPDATE orders SET status = ? WHERE id = ?');
    $stmt->execute([$status, $id]);
    out(['ok' => true]);
}

/* ================= menu_save / menu_delete ================= */
function actionMenuSave(): void {
    requireAdmin();
    $b = body();
    $name  = trim((string)($b['name'] ?? ''));
    $price = (float)($b['price'] ?? 0);
    $cat   = trim((string)($b['category'] ?? 'Coffee'));
    $desc  = trim((string)($b['description'] ?? ''));
    $icon  = trim((string)($b['icon'] ?? '☕'));
    $avail = !empty($b['available']) ? 1 : 0;
    $id    = (int)($b['id'] ?? 0);
    if ($name === '') fail('Name is required.');
    if ($price <= 0) fail('Price must be greater than 0.');

    $pdo = db();
    if ($id > 0) {
        $pdo->prepare('UPDATE menu_items SET name=?, category=?, price=?, description=?, icon=?, available=? WHERE id=?')
            ->execute([$name, $cat, $price, $desc, $icon, $avail, $id]);
    } else {
        $pdo->prepare('INSERT INTO menu_items (name, category, price, description, icon, available) VALUES (?,?,?,?,?,?)')
            ->execute([$name, $cat, $price, $desc, $icon, $avail]);
    }
    out(['ok' => true]);
}

function actionMenuDelete(): void {
    requireAdmin();
    $id = (int)(body()['id'] ?? 0);
    if ($id <= 0) fail('Missing id.');
    try {
        $stmt = db()->prepare('DELETE FROM menu_items WHERE id = ?');
        $stmt->execute([$id]);
        if ($stmt->rowCount() === 0) fail('Item not found.', 404);
    } catch (PDOException $e) {
        db()->prepare('UPDATE menu_items SET available = 0 WHERE id = ?')->execute([$id]);
        out(['ok' => true, 'disabled' => true, 'note' => 'Used in past orders — marked unavailable.']);
    }
    out(['ok' => true]);
}

/* ================= ingredients ================= */
function actionIngredientSave(): void {
    requireAdmin();
    $b = body();
    $name   = trim((string)($b['name'] ?? ''));
    $unit   = trim((string)($b['unit'] ?? 'g'));
    $pq     = (float)($b['purchase_qty'] ?? 0);
    $pp     = (float)($b['purchase_price'] ?? 0);
    $stock  = (float)($b['stock'] ?? 0);
    $reorder= (float)($b['reorder_level'] ?? 0);
    $id     = (int)($b['id'] ?? 0);
    if ($name === '' || $pq <= 0 || $pp < 0) fail('Enter a name, purchased quantity and purchase price.');

    $pdo = db();
    if ($id > 0) {
        $pdo->prepare('UPDATE ingredients SET name=?, unit=?, purchase_qty=?, purchase_price=?, stock=?, reorder_level=? WHERE id=?')
            ->execute([$name, $unit, $pq, $pp, $stock, $reorder, $id]);
    } else {
        $pdo->prepare('INSERT INTO ingredients (name, unit, purchase_qty, purchase_price, stock, reorder_level) VALUES (?,?,?,?,?,?)')
            ->execute([$name, $unit, $pq, $pp, $stock, $reorder]);
        $id = (int)$pdo->lastInsertId();
        if ($stock > 0) {
            $pdo->prepare('INSERT INTO stock_movements (ingredient_id, `change`, reason) VALUES (?, ?, "restock")')
                ->execute([$id, $stock]);
        }
    }
    out(['ok' => true, 'id' => $id]);
}

function actionIngredientDelete(): void {
    requireAdmin();
    $id = (int)(body()['id'] ?? 0);
    if ($id <= 0) fail('Missing id.');
    db()->prepare('DELETE FROM ingredients WHERE id = ?')->execute([$id]);
    out(['ok' => true]);
}

/* ================= stock_restock (positive adjustment) ================= */
function actionStockRestock(): void {
    requireAdmin();
    $b = body();
    $id  = (int)($b['id'] ?? 0);
    $qty = (float)($b['qty'] ?? 0);
    if ($id <= 0 || $qty <= 0) fail('Enter a restock quantity.');
    $pdo = db();
    $pdo->beginTransaction();
    try {
        $pdo->prepare('UPDATE ingredients SET stock = stock + ? WHERE id = ?')->execute([$qty, $id]);
        $pdo->prepare('INSERT INTO stock_movements (ingredient_id, `change`, reason) VALUES (?, ?, "restock")')
            ->execute([$id, $qty]);
        $pdo->commit();
        out(['ok' => true]);
    } catch (Throwable $e) {
        $pdo->rollBack();
        fail($e->getMessage(), 500);
    }
}

/* ================= recipe_save ================= */
function actionRecipeSave(): void {
    requireAdmin();
    $b = body();
    $menuId = (int)($b['menuItemId'] ?? 0);
    $lines  = $b['lines'] ?? [];
    if ($menuId <= 0) fail('Missing product.');
    if (!is_array($lines) || !$lines) fail('Add at least one ingredient to the recipe.');

    $pdo = db();
    $pdo->beginTransaction();
    try {
        $pdo->prepare('DELETE FROM recipes WHERE menu_item_id = ?')->execute([$menuId]);
        $ins = $pdo->prepare('INSERT INTO recipes (menu_item_id, ingredient_id, quantity) VALUES (?, ?, ?)');
        foreach ($lines as $l) {
            $ing = (int)($l['ingredientId'] ?? 0);
            $qty = (float)($l['quantity'] ?? 0);
            if ($ing > 0 && $qty > 0) $ins->execute([$menuId, $ing, $qty]);
        }
        $pdo->commit();
        out(['ok' => true]);
    } catch (Throwable $e) {
        $pdo->rollBack();
        fail($e->getMessage(), 500);
    }
}

/* ================= health ================= */
function actionHealth(): void {
    try {
        $m = (int)db()->query('SELECT COUNT(*) FROM menu_items')->fetchColumn();
        $i = (int)db()->query('SELECT COUNT(*) FROM ingredients')->fetchColumn();
        out(['ok' => true, 'menu_count' => $m, 'ingredient_count' => $i, 'php' => PHP_VERSION]);
    } catch (Throwable $e) {
        fail('Database unavailable: ' . $e->getMessage(), 503);
    }
}

/* ================= router ================= */
$action = $_GET['action'] ?? '';
try {
    switch ($action) {
        case 'health':           actionHealth();          break;
        case 'session':          actionSession();         break;
        case 'login':            actionLogin();           break;
        case 'logout':           actionLogout();          break;
        case 'load':             actionLoad();            break;
        case 'order_create':     actionOrderCreate();     break;
        case 'order_status':     actionOrderStatus();     break;
        case 'menu_save':        actionMenuSave();        break;
        case 'menu_delete':      actionMenuDelete();      break;
        case 'ingredient_save':  actionIngredientSave();  break;
        case 'ingredient_delete':actionIngredientDelete();break;
        case 'stock_restock':    actionStockRestock();    break;
        case 'recipe_save':      actionRecipeSave();      break;
        default: fail('Unknown action: ' . $action, 404);
    }
} catch (PDOException $e) {
    fail('MySQL error: ' . $e->getMessage(), 503);
} catch (Throwable $e) {
    fail($e->getMessage(), 500);
}
