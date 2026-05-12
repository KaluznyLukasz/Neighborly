# Neighborly — Technical Requirements Document

## 1. Core Feature Roadmap

### MVP
| Feature | Description |
|---|---|
| Authentication | Email/password + Sign in with Apple via FirebaseAuth |
| Map Feed | Full-screen map centered on user location, showing nearby offers as pins |
| Create Offer | Form to post a tool/help offer with category, title, description, optional photo |
| Offer Detail | View offer info, owner profile snippet, request button |
| Request Flow | Requester sends request → owner accepts/rejects → status tracked |
| Basic Profile | Avatar, display name, bio, rating display |

### Future Scale
| Feature | Description |
|---|---|
| In-app Messaging | Chat thread per transaction |
| Push Notifications | New requests, accepted/rejected, messages |
| Trust Score | Derived from review history, response rate, completion rate |
| Offer Search / Filter | Category filter, radius slider, text search |
| Payments | Optional Stripe integration for paid services |
| Community Boards | Neighborhood-scoped announcement feed |

### Primary User Journey (MVP)
```
Launch
  └─ Not authenticated → AuthView (Sign Up / Sign In)
  └─ Authenticated
       └─ NEIMapView — map loads, user location found, nearby offers rendered as pins
            ├─ Tap pin → NEIOfferDetailView
            │    └─ "Request" button → NEIRequestView → Transaction created (pending)
            └─ FAB "+" → NEICreateOfferView → Offer saved to Firestore → pin appears on map
```

---

## 2. Data Architecture

### Entities & Fields

**User**
| Field | Type | Notes |
|---|---|---|
| id | String | FirebaseAuth UID |
| displayName | String | |
| email | String | |
| avatarURL | String? | Firebase Storage URL |
| bio | String? | |
| latitude | Double? | Last known location |
| longitude | Double? | Last known location |
| rating | Double | Avg of all reviews received (0–5) |
| reviewCount | Int | Denormalized count |
| createdAt | Date | |

**Offer**
| Field | Type | Notes |
|---|---|---|
| id | String | Firestore document ID |
| title | String | |
| description | String | |
| category | OfferCategory | Enum: tools, help, food, services, items |
| ownerId | String | User.id ref |
| latitude | Double | |
| longitude | Double | |
| imageURLs | [String] | Firebase Storage URLs |
| isActive | Bool | Soft delete / pause |
| createdAt | Date | |

**Transaction**
| Field | Type | Notes |
|---|---|---|
| id | String | |
| offerId | String | Offer.id ref |
| requesterId | String | User.id ref |
| ownerId | String | User.id ref (denormalized for queries) |
| status | TransactionStatus | pending → accepted/rejected → completed/cancelled |
| message | String? | Initial message from requester |
| createdAt | Date | |
| updatedAt | Date | |

**Review**
| Field | Type | Notes |
|---|---|---|
| id | String | |
| transactionId | String | Transaction.id ref |
| reviewerId | String | User.id ref |
| revieweeId | String | User.id ref |
| rating | Int | 1–5 |
| comment | String? | |
| createdAt | Date | |

### Relationships
- User 1 → N Offers (ownerId)
- Offer 1 → N Transactions
- Transaction 1 → 0..2 Reviews (owner reviews requester, requester reviews owner)
- User 1 → N Reviews received (revieweeId)

---

## 3. Technical Stack & File Structure

### Frameworks
- **SwiftUI** — UI layer
- **MapKit** — Map rendering, annotations
- **CoreLocation** — Device location
- **FirebaseAuth** — Authentication
- **FirebaseFirestore** — Primary database
- **FirebaseStorage** — Image uploads
- **Combine / async-await** — Async data flow

### MVVM Folder Hierarchy
```
Neighborly/
├── App/
│   ├── NeighborlyApp.swift
│   └── ContentView.swift
├── Models/
│   ├── NEIOffer.swift
│   ├── NEIUser.swift
│   ├── NEITransaction.swift
│   └── NEIReview.swift
├── Views/
│   ├── Auth/
│   │   ├── NEIAuthView.swift
│   │   ├── NEISignInView.swift
│   │   └── NEISignUpView.swift
│   ├── Map/
│   │   ├── NEIMapView.swift
│   │   └── NEIOfferAnnotationView.swift
│   ├── Offers/
│   │   ├── NEICreateOfferView.swift
│   │   └── NEIOfferDetailView.swift
│   ├── Transactions/
│   │   ├── NEIRequestView.swift
│   │   └── NEITransactionListView.swift
│   ├── Profile/
│   │   └── NEIProfileView.swift
│   └── Components/
│       ├── NEIPrimaryButton.swift
│       ├── NEIInputField.swift
│       ├── NEIAvatarView.swift
│       ├── NEIRatingView.swift
│       └── NEICategoryBadge.swift
├── ViewModels/
│   ├── NEIAuthViewModel.swift
│   ├── NEIMapViewModel.swift
│   ├── NEIOfferViewModel.swift
│   ├── NEITransactionViewModel.swift
│   └── NEIProfileViewModel.swift
├── Services/
│   ├── NEIAuthService.swift
│   ├── NEIOfferService.swift
│   ├── NEITransactionService.swift
│   └── NEIStorageService.swift
├── Utils/
│   └── NEILocationManager.swift
└── Resources/
    ├── Assets.xcassets
    └── GoogleService-Info.plist
```

---

## 4. API & Database Schema (Firestore)

### Collection Structure
```
/users/{userId}
  → fields: displayName, email, avatarURL, bio, latitude, longitude,
            rating, reviewCount, createdAt

/offers/{offerId}
  → fields: title, description, category, ownerId, latitude, longitude,
            imageURLs[], isActive, createdAt

/transactions/{transactionId}
  → fields: offerId, requesterId, ownerId, status, message, createdAt, updatedAt

/reviews/{reviewId}
  → fields: transactionId, reviewerId, revieweeId, rating, comment, createdAt
```

### Security Rules Logic
```
users:
  read:  authenticated (any user can read profiles)
  write: owner only (userId == request.auth.uid)

offers:
  read:  authenticated
  create: authenticated (ownerId must equal request.auth.uid)
  update: owner only
  delete: owner only

transactions:
  read:  requesterId == auth.uid || ownerId == auth.uid
  create: authenticated (requesterId must equal auth.uid, cannot be own offer)
  update: ownerId can change status; requesterId can cancel

reviews:
  read:  authenticated
  create: authenticated, transactionId must reference completed transaction
          involving auth.uid, no duplicate review per transaction per author
  update: none
```

---

## 5. UI/UX Design System

### Color Palette
| Token | Hex | Usage |
|---|---|---|
| `neiGreen` | `#3CB371` | Primary actions, FAB, active states |
| `neiGreenLight` | `#E8F5E9` | Backgrounds, tags |
| `neiOnyx` | `#1C1C1E` | Primary text |
| `neiGray` | `#8E8E93` | Secondary text, placeholders |
| `neiSurface` | `#F2F2F7` | Screen backgrounds |
| `neiWhite` | `#FFFFFF` | Cards, inputs |
| `neiRed` | `#FF3B30` | Errors, destructive |
| `neiAmber` | `#FF9500` | Warnings, pending status |

### Typography
| Style | Font | Size | Weight |
|---|---|---|---|
| Title | SF Pro Rounded | 28 | Bold |
| Headline | SF Pro | 17 | Semibold |
| Body | SF Pro | 15 | Regular |
| Caption | SF Pro | 12 | Regular |
| Badge | SF Pro | 11 | Medium |

### Reusable Components
| Component | Purpose |
|---|---|
| `NEIPrimaryButton` | Full-width green CTA button |
| `NEISecondaryButton` | Bordered outline variant |
| `NEIInputField` | Styled TextField with label + validation state |
| `NEIAvatarView` | Circular async image with fallback initials |
| `NEIRatingView` | Star row with numeric label |
| `NEICategoryBadge` | Pill tag per OfferCategory |
| `NEIOfferAnnotationView` | Map pin with category icon |
| `NEIOfferCard` | List/sheet card for offer preview |
| `NEIStatusBadge` | Transaction status pill (pending/accepted/etc.) |

---

## 6. Implementation Phases

### Phase 1 — Foundation & Auth
- Firebase project setup (Auth, Firestore, Storage rules)
- `NEIAuthService` with email/password + Sign in with Apple
- `NEIAuthViewModel` + `NEIAuthView` (sign in / sign up flows)
- Root navigation: unauthenticated → AuthView, authenticated → MapView
- `NEIUser` model + write user doc on registration
- Design tokens (colors, fonts) in Assets.xcassets

### Phase 2 — Map & Offers
- Migrate `LocationManager` → `NEIUtils/NEILocationManager.swift`
- `NEIMapViewModel` — fetches offers from Firestore within bounding box
- `NEIMapView` — modern `Map` API with `Annotation` for each offer
- `NEIOfferAnnotationView` — category-colored pin
- `NEICreateOfferView` + `NEIOfferViewModel` (create, image upload via `NEIStorageService`)
- `NEIOfferDetailView` — offer info + owner avatar + rating

### Phase 3 — Transactions & Reviews
- `NEITransactionService` + `NEITransactionViewModel`
- `NEIRequestView` — send request with optional message
- `NEITransactionListView` — owner's inbox (pending requests)
- Accept / reject / complete actions with Firestore status updates
- `NEIReview` model + post-completion review prompt
- Denormalized rating update on User doc via Cloud Function or client-side transaction

### Phase 4 — Profile & Polish
- `NEIProfileView` — avatar upload, bio edit, reviews list
- `NEIProfileViewModel` — load user doc + their offers + received reviews
- Push notifications (FCM) for transaction status changes
- Offer category filter sheet on map
- Skeleton loading states, empty states, error handling
- App Store assets, privacy manifest, final HIG audit
