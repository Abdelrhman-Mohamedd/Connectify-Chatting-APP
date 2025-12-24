# Connectify - Modern Flutter Messaging App

A real-time messaging application redesigned with a modern, "Google Stitch" inspired aesthetic, built with **Flutter** and **Supabase**.

## ✨ Features

### 🎨 Modern UI/UX
-   **Google Stitch Design:** Clean, minimalist interface with vibrant colors and rounded elements.
-   **Theme Persistence:** **Dark Mode** and **Light Mode** support (persisted via `shared_preferences`).
-   **Bottom Navigation:** Easy access to Chats, Calls, People, and Settings.
-   **Typography:** Modern look using `Google Fonts` (Outfit).

### 💬 Messaging
-   **Real-time Chat:** Instant messaging powered by Supabase Realtime.
-   **Read Receipts:**
    -   Single Gray Check: Sent
    -   Double Blue Check: Read
-   **Unread Counts:** Real-time indicators for unread messages.
-   **Smart Time Formatting:** "Just now", "5m ago" using `timeago`.
-   **Dynamic Chat Header:** Displays the other user's real-time name and avatar.
-   **Online Presence:** Real-time "Online" status indicator for active users.

### 👤 Profile & Settings
-   **User Authentication:** Secure Email/Password Signup & Login with Supabase Auth.
-   **Profile Management:**
    -   Edit Name and Avatar.
    -   **Image Upload:** users can upload profile pictures to Supabase Storage.
    -   **Real-time Sync:** Profile updates instantly reflect across the app for all users.
    -   **Auto-Bucket Creation:** App attempts to create storage buckets automatically.
-   **Settings Page:** dedicated screen for app preferences, theme switching, and logout.

---

## 🚀 Prerequisites

1.  **Flutter SDK** (Version 3.10.x or higher).
2.  **Supabase Account:** You need a project URL and Anon Key.
3.  **Git** installed.

---

## 🛠️ Installation & Setup

1.  **Clone the Repository:**
    ```bash
    git clone <your-repo-url>
    cd flutter_messaging_app
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Environment Variables:**
    Create a `.env` file in the root directory:
    ```env
    SUPABASE_URL=your_supabase_project_url
    SUPABASE_ANON_KEY=your_supabase_anon_key
    ```

4.  **Database Setup (Supabase):**
    *   **SQL Schema:** Run the `supabase_schema.sql` script in your Supabase SQL Editor to sets up tables (`profiles`, `conversations`, `messages`), RLS policies, and triggers.
    *   **Storage Setup (Critical):**
        For profile photos to work, you **must** create a public storage bucket named `avatars` and set up policies. Run this SQL:
        ```sql
        -- Create bucket
        insert into storage.buckets (id, name, public) 
        values ('avatars', 'avatars', true) on conflict do nothing;

        -- Allow uploads
        create policy "Authenticated users can upload avatars"
        on storage.objects for insert with check (
          bucket_id = 'avatars' AND auth.role() = 'authenticated'
        );
        
        -- Allow viewing
        create policy "Public access to avatars"
        on storage.objects for select using ( bucket_id = 'avatars' );
        ```

---

## 📦 Tech Stack

-   **Frontend:** Flutter
-   **Backend:** Supabase (PostgreSQL, Auth, Storage, Realtime)
-   **State Management:** `flutter_bloc`
-   **Navigation:** `go_router`
-   **Dependency Injection:** `get_it`
-   **Local Storage:** `shared_preferences` (for Theme)
-   **Media:** `image_picker`

---

## 🏃‍♂️ How to Run

```bash
# Windows
flutter run -d windows

# Android
flutter run -d android
```

---

## 🔧 Troubleshooting

*   **"Bucket not found" error:** Ensure you created the `avatars` bucket in Supabase Storage or ran the SQL script above.
*   **"403 Unauthorized" on upload:** Check your Storage RLS policies. The app requires authenticated users to have INSERT permissions.
