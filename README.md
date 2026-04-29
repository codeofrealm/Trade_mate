# TradeMate

A full-featured Flutter e-commerce management app with a **User side** for browsing and ordering products, and an **Admin side** for managing products, orders, customers, and analytics — all powered by **Firebase**.

---

## Features

### User Side
- **Login / Register** — Email & password authentication via Firebase Auth. Role-based routing (admin → admin dashboard, user → home).
- **Home Dashboard** — Sticky header with search bar, active product grid with category chips, stock badges, star ratings.
- **Product Details** — Product image, description, quantity selector, address status, reviews list, write a review (star rating + comment → saved to Firestore).
- **Cart** — Add/remove products, update quantity, delivery address preview, place cart order.
- **My Orders** — Order tracking with animated progress bar (Placed → Packed → Shipped → Delivered), cancel order button, notification banners for delivered/cancelled orders.
- **Analytics** — Personal spending summary (Today / This Week / This Month / All Time), order count stats, monthly bar chart, order history list.
- **Profile** — Save/edit delivery address, logout.
- **Notifications** — Bell icon on dashboard navigates to a notifications page showing only delivered and cancelled orders.

### Admin Side
- **Dashboard (Home)** — Low stock warning card (tap → dedicated low stock page with edit buttons), overview stats (total products, users, orders, revenue), revenue summary (today/weekly/monthly/yearly), 3 bar charts (7-day, 30-day, yearly).
- **Products** — Sticky header with search + mini dashboard (total, active, inactive, min/max stock), product list with edit and activate/deactivate buttons.
- **Orders (Active)** — Sticky header with mini dashboard (total, placed, processing, packed, shipped), search + filter by status, tap order → detail sheet with status update chips.
- **Customers** — Sticky header with mini dashboard (customer count, total spent), search, customer cards with order badges. Tap → customer detail page with collapsible SliverAppBar showing stats + full order history.
- **Completed Orders** — Sticky header with mini dashboard (total, delivered, cancelled, revenue), search + filter (delivered/cancelled), order list.
- **Low Stock Page** — All active products with stock ≤ 5, tap any card → product edit form.
- **Product Form** — Add/edit product with image picker (gallery), all fields with iOS-style inputs, active toggle.
- **No back arrow** on admin root pages — `automaticallyImplyLeading: false` + `PopScope` prevents accidental navigation.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart 3.x) |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| Image Storage | Base64 encoded in Firestore |
| State Management | `StreamBuilder` + `setState` |
| UI Style | iOS-style (Material 3 + custom theme) |

---

## Dependencies

```yaml
dependencies:
  firebase_core: ^4.7.0
  firebase_auth: ^6.4.0
  cloud_firestore: ^6.3.0
  image_picker: ^1.2.1
  url_launcher: ^6.3.0
  cupertino_icons: ^1.0.8
```

---

## Firestore Collections

| Collection | Description |
|---|---|
| `users` | User profiles with role (`admin` / `user`) and delivery address |
| `products` | Product catalog (name, category, price, stock, image, rating) |
| `orders` | All user orders with status, address, product info |
| `cart_items` | Per-user cart items |
| `product_reviews` | Product reviews with rating and comment |
| `wishlist` | User wishlisted products |

---

## Project Structure

```
lib/
├── app/
│   ├── ui/
│   │   └── glass.dart              # GlassContainer, GlassBackground
│   ├── app_routes.dart             # All named routes
│   ├── start_page.dart             # Auth check + role routing
│   └── trade_mate_app.dart         # MaterialApp + theme
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_service.dart   # Firebase Auth login/register/logout
│   │   │   └── auth_user_store.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── login_page.dart
│   │       │   └── register_page.dart
│   │       └── widgets/
│   │           └── auth_text_field.dart
│   │
│   ├── admin/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── admin_product.dart
│   │   │   │   ├── admin_product_review.dart
│   │   │   │   └── admin_user_order.dart
│   │   │   └── services/
│   │   │       └── admin_catalog_service.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── admin_dashboard_page.dart
│   │       │   ├── admin_product_form_page.dart
│   │       │   └── admin_low_stock_page.dart
│   │       └── widgets/dashboard/
│   │           ├── admin_overview_tab.dart
│   │           ├── admin_products_tab.dart
│   │           ├── admin_orders_tab.dart
│   │           ├── admin_completed_orders_tab.dart
│   │           └── admin_reviews_tab.dart  # Customers tab
│   │
│   └── home/
│       ├── data/
│       │   ├── models/
│       │   │   ├── home_cart_item.dart
│       │   │   ├── home_user_address.dart
│       │   │   └── home_user_order.dart
│       │   ├── home_product_service.dart
│       │   └── home_user_profile_service.dart
│       └── presentation/
│           ├── pages/
│           │   ├── home_page.dart
│           │   ├── home_profile_page.dart
│           │   ├── home_notifications_page.dart
│           │   ├── product_details_page.dart
│           │   ├── order_details_page.dart
│           │   ├── order_success_page.dart
│           │   └── track_page.dart
│           └── widgets/home/
│               ├── home_dashboard_tab.dart
│               ├── home_cart_tab.dart
│               ├── home_orders_tab.dart
│               ├── home_analytics_tab.dart
│               ├── home_profile_tab.dart
│               └── home_floating_nav_bar.dart
│
├── firebase_options.dart
└── main.dart
```

---

## Getting Started

### 1. Clone the repository
```bash
git clone <repo-url>
cd trade_mate
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Firebase Setup
- Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
- Enable **Authentication** (Email/Password)
- Enable **Cloud Firestore**
- Download `google-services.json` → place in `android/app/`
- Download `GoogleService-Info.plist` → place in `ios/Runner/`
- Update `lib/firebase_options.dart` with your config

### 4. Create Admin Account
In Firestore `users` collection, set the user document:
```json
{
  "role": "admin",
  "username": "Admin",
  "email": "your-admin@email.com"
}
```

### 5. Run the app
```bash
flutter run
```

---

## Navigation Flow

```
StartPage (auth check)
    ├── Not logged in → LoginPage
    │       ├── Login as admin → AdminDashboardPage
    │       └── Login as user  → HomePage
    │
    ├── Admin role → AdminDashboardPage
    │       ├── Tab: Dashboard (overview + charts)
    │       ├── Tab: Products  (list + add/edit)
    │       ├── Tab: Orders    (active orders)
    │       ├── Tab: Customers (customer list + detail)
    │       └── Tab: Completed (delivered + cancelled)
    │
    └── User role → HomePage
            ├── Tab: Dashboard  (product grid)
            ├── Tab: Cart       (cart items + checkout)
            ├── Tab: Orders     (order tracking + cancel)
            └── Tab: Analytics  (spending charts)
```

---

## Back Navigation Rules

| Page | Back Behaviour |
|---|---|
| LoginPage | Back = close app |
| HomePage | Back = close app |
| AdminDashboardPage | Back = close app |
| All sub-pages | Back = go to previous page |

---

## Version

`1.0.0+1`
