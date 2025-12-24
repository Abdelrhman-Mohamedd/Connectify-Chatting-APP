-- Create profiles table
create table public.profiles (
  id uuid references auth.users not null primary key,
  updated_at timestamp with time zone,
  username text unique,
  name text,
  avatar_url text,
  email text,
  
  constraint username_length check (char_length(username) >= 3)
);

-- Enable RLS
alter table public.profiles enable row level security;

create policy "Public profiles are viewable by everyone."
  on profiles for select
  using ( true );

create policy "Users can insert their own profile."
  on profiles for insert
  with check ( auth.uid() = id );

create policy "Users can update own profile."
  on profiles for update
  using ( auth.uid() = id );

-- Create conversations table
create table public.conversations (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  last_message text,
  last_message_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.conversations enable row level security;

create policy "Authenticated users can view conversations"
  on conversations for select
  using ( auth.role() = 'authenticated' );

create policy "Authenticated users can insert conversations"
  on conversations for insert
  with check ( auth.role() = 'authenticated' );

-- Create conversation_participants table
create table public.conversation_participants (
  conversation_id uuid references public.conversations not null,
  user_id uuid references auth.users not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  primary key (conversation_id, user_id)
);

alter table public.conversation_participants enable row level security;

create policy "Participants can view their conversations"
  on conversation_participants for select
  using ( auth.uid() = user_id );

create policy "Participants can insert"
  on conversation_participants for insert
  with check ( auth.role() = 'authenticated' );

-- Create messages table
create table public.messages (
  id uuid default uuid_generate_v4() primary key,
  conversation_id uuid references public.conversations not null,
  sender_id uuid references auth.users not null,
  content text not null,
  is_read boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.messages enable row level security;

create policy "Participants can view messages"
  on messages for select
  using (
    exists (
      select 1 from conversation_participants
      where conversation_id = messages.conversation_id
      and user_id = auth.uid()
    )
  );

create policy "Participants can insert messages"
  on messages for insert
  with check (
    auth.uid() = sender_id
  );

-- Function to handle new user sign up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, name, avatar_url)
  values (new.id, new.email, new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'avatar_url');
  return new;
end;
$$ language plpgsql security definer;

-- Trigger for new user
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- [FIX 1] Helper to bypass recursion in Conversation RLS
CREATE OR REPLACE FUNCTION get_my_conversation_ids()
RETURNS TABLE (conversation_id uuid) 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY SELECT cp.conversation_id FROM conversation_participants cp WHERE cp.user_id = auth.uid();
END;
$$ LANGUAGE plpgsql;

-- [FIX 2] Update Conversation View Policy
DROP POLICY IF EXISTS "Authenticated users can view conversations" ON conversations;
CREATE POLICY "Authenticated users can view conversations"
ON conversations FOR SELECT
USING (
  id IN ( SELECT get_my_conversation_ids() )
);

-- [FIX 3] Update Messages View Policy
DROP POLICY IF EXISTS "Participants can view messages" ON messages;
CREATE POLICY "Participants can view messages"
ON messages FOR SELECT
USING (
   conversation_id IN ( SELECT get_my_conversation_ids() )
);

-- [FIX 4] Allow Updating Last Message
CREATE POLICY "Participants can update their conversations"
ON public.conversations
FOR UPDATE
USING (
  id IN ( SELECT get_my_conversation_ids() )
)
WITH CHECK (
  id IN ( SELECT get_my_conversation_ids() )
);

-- [FIX 5] Allow Marking Messages as Read
CREATE POLICY "Participants can update messages"
ON public.messages
FOR UPDATE
USING (
  exists (
    select 1 from public.conversation_participants
    where conversation_id = messages.conversation_id
    and user_id = auth.uid()
  )
)
WITH CHECK (
  exists (
    select 1 from public.conversation_participants
    where conversation_id = messages.conversation_id
    and user_id = auth.uid()
  )
);

-- [FIX 6] Automatic Conversation Update Trigger
CREATE OR REPLACE FUNCTION public.update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.conversations
  SET 
    last_message = NEW.content,
    last_message_at = NEW.created_at
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


CREATE TRIGGER on_message_created
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE PROCEDURE public.update_conversation_last_message();

-- [FIX 7] Enable Realtime for Tables
-- This is REQUIRED for the Flutter app to listen to changes
alter publication supabase_realtime add table public.conversations;
alter publication supabase_realtime add table public.messages;

-- [FIX 8] Handle Message Deletion (Update Conversation Last Message)
CREATE OR REPLACE FUNCTION public.handle_message_delete()
RETURNS TRIGGER AS $$
DECLARE
  latest_content text;
  latest_time timestamptz;
BEGIN
  -- Find the newest message that still exists
  SELECT content, created_at 
  INTO latest_content, latest_time
  FROM public.messages
  WHERE conversation_id = OLD.conversation_id
  ORDER BY created_at DESC
  LIMIT 1;

  -- Update the conversation table
  UPDATE public.conversations
  SET 
    last_message = latest_content,
    last_message_at = COALESCE(latest_time, created_at)
  WHERE id = OLD.conversation_id;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_message_deleted
  AFTER DELETE ON public.messages
  FOR EACH ROW EXECUTE PROCEDURE public.handle_message_delete();

