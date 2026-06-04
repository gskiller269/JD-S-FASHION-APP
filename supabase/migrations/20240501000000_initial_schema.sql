-- ============================================================================
-- JD'S FASHION: COMPLETE DATABASE SETUP
-- Run this ENTIRE script in your Supabase SQL Editor (https://supabase.com/dashboard)
-- Go to: SQL Editor > New Query > Paste this > Click "Run"
-- ============================================================================


-- ============================================================================
-- STEP 0: CLEANUP EXISTING SCHEMAS (for clean reruns)
-- ============================================================================

DROP TABLE IF EXISTS public.banners CASCADE;
DROP TABLE IF EXISTS public.support_tickets CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.reviews CASCADE;
DROP TABLE IF EXISTS public.payments CASCADE;
DROP TABLE IF EXISTS public.order_items CASCADE;
DROP TABLE IF EXISTS public.orders CASCADE;
DROP TABLE IF EXISTS public.coupons CASCADE;
DROP TABLE IF EXISTS public.addresses CASCADE;
DROP TABLE IF EXISTS public.cart_items CASCADE;
DROP TABLE IF EXISTS public.wishlists CASCADE;
DROP TABLE IF EXISTS public.inventory CASCADE;
DROP TABLE IF EXISTS public.product_variants CASCADE;
DROP TABLE IF EXISTS public.product_images CASCADE;
DROP TABLE IF EXISTS public.products CASCADE;
DROP TABLE IF EXISTS public.categories CASCADE;
DROP TABLE IF EXISTS public.vendors CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS order_status CASCADE;
DROP TYPE IF EXISTS payment_status CASCADE;
DROP TYPE IF EXISTS payment_method CASCADE;
DROP TYPE IF EXISTS ticket_status CASCADE;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_confirm ON auth.users;



-- ============================================================================
-- STEP 1: CREATE ENUMS
-- ============================================================================

CREATE TYPE user_role AS ENUM ('customer', 'vendor', 'admin');
CREATE TYPE order_status AS ENUM ('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded');
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
CREATE TYPE payment_method AS ENUM ('razorpay', 'upi', 'credit_card', 'debit_card', 'cod');
CREATE TYPE ticket_status AS ENUM ('open', 'in_progress', 'resolved', 'closed');


-- ============================================================================
-- STEP 2: CREATE TABLES
-- ============================================================================

-- 1. Profiles (extends Supabase auth.users)
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    role user_role DEFAULT 'customer',
    full_name TEXT,
    avatar_url TEXT,
    phone_number TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 2. Vendors
CREATE TABLE public.vendors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    store_name TEXT NOT NULL,
    store_description TEXT,
    logo_url TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 3. Categories
CREATE TABLE public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    image_url TEXT,
    parent_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 4. Products
CREATE TABLE public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID REFERENCES public.vendors(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT NOT NULL,
    base_price DECIMAL(10, 2) NOT NULL,
    discount_price DECIMAL(10, 2),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 5. Product Images
CREATE TABLE public.product_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
    image_url TEXT NOT NULL,
    is_primary BOOLEAN DEFAULT false,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 6. Product Variants
CREATE TABLE public.product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
    color TEXT,
    size TEXT,
    sku TEXT UNIQUE,
    price_adjustment DECIMAL(10, 2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 7. Inventory
CREATE TABLE public.inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    variant_id UUID REFERENCES public.product_variants(id) ON DELETE CASCADE NOT NULL UNIQUE,
    quantity INTEGER NOT NULL DEFAULT 0,
    low_stock_threshold INTEGER DEFAULT 5,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 8. Wishlists
CREATE TABLE public.wishlists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE(user_id, product_id)
);

-- 9. Cart Items
CREATE TABLE public.cart_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    variant_id UUID REFERENCES public.product_variants(id) ON DELETE CASCADE NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE(user_id, variant_id)
);

-- 10. Addresses
CREATE TABLE public.addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    address_line_1 TEXT NOT NULL,
    address_line_2 TEXT,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    postal_code TEXT NOT NULL,
    country TEXT DEFAULT 'India',
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 11. Coupons
CREATE TABLE public.coupons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    description TEXT,
    discount_percentage DECIMAL(5, 2),
    discount_amount DECIMAL(10, 2),
    min_order_value DECIMAL(10, 2),
    max_discount DECIMAL(10, 2),
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 12. Orders
CREATE TABLE public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE RESTRICT NOT NULL,
    address_id UUID REFERENCES public.addresses(id) ON DELETE RESTRICT NOT NULL,
    coupon_id UUID REFERENCES public.coupons(id) ON DELETE SET NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    discount_amount DECIMAL(10, 2) DEFAULT 0,
    final_amount DECIMAL(10, 2) NOT NULL,
    status order_status DEFAULT 'pending',
    tracking_number TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 13. Order Items
CREATE TABLE public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
    variant_id UUID REFERENCES public.product_variants(id) ON DELETE RESTRICT NOT NULL,
    quantity INTEGER NOT NULL,
    price_at_time DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 14. Payments
CREATE TABLE public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL UNIQUE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE RESTRICT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    method payment_method NOT NULL,
    status payment_status DEFAULT 'pending',
    transaction_id TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 15. Reviews
CREATE TABLE public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5) NOT NULL,
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE(product_id, user_id)
);

-- 16. Notifications
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 17. Support Tickets
CREATE TABLE public.support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    subject TEXT NOT NULL,
    description TEXT NOT NULL,
    status ticket_status DEFAULT 'open',
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 18. Banners (for Admin Panel)
CREATE TABLE public.banners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    image_url TEXT NOT NULL,
    link_url TEXT,
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);


-- ============================================================================
-- STEP 3: DATABASE FUNCTIONS & TRIGGERS
-- ============================================================================

-- Auto-update updated_at timestamp on any row update
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply the trigger to all relevant tables
CREATE TRIGGER update_profiles_modtime BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_vendors_modtime BEFORE UPDATE ON public.vendors FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_products_modtime BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_variants_modtime BEFORE UPDATE ON public.product_variants FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_inventory_modtime BEFORE UPDATE ON public.inventory FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_cart_modtime BEFORE UPDATE ON public.cart_items FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_addresses_modtime BEFORE UPDATE ON public.addresses FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_orders_modtime BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_payments_modtime BEFORE UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_reviews_modtime BEFORE UPDATE ON public.reviews FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_tickets_modtime BEFORE UPDATE ON public.support_tickets FOR EACH ROW EXECUTE FUNCTION update_modified_column();

-- Auto-create a profile when a new user signs up via Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url, phone_number)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url',
    COALESCE(NEW.raw_user_meta_data->>'phone_number', NEW.phone)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Auto-confirm email when a new user signs up (Bypasses email verification requirement)
CREATE OR REPLACE FUNCTION public.auto_confirm_user()
RETURNS TRIGGER AS $$
BEGIN
  NEW.email_confirmed_at = COALESCE(NEW.email_confirmed_at, now());
  NEW.confirmed_at = COALESCE(NEW.confirmed_at, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created_confirm
  BEFORE INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.auto_confirm_user();



-- ============================================================================
-- STEP 4: ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on ALL tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wishlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.banners ENABLE ROW LEVEL SECURITY;

-- PROFILES
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Allow profile insert on signup" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- CATEGORIES (public read for everyone)
CREATE POLICY "Everyone can read categories" ON public.categories FOR SELECT USING (true);
CREATE POLICY "Only admins can manage categories" ON public.categories FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- PRODUCTS (public read for active products)
CREATE POLICY "Everyone can read active products" ON public.products FOR SELECT USING (is_active = true);
CREATE POLICY "Vendors can manage own products" ON public.products FOR ALL USING (
  vendor_id IN (SELECT id FROM public.vendors WHERE profile_id = auth.uid())
);
CREATE POLICY "Admins can manage all products" ON public.products FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- PRODUCT IMAGES (public read)
CREATE POLICY "Everyone can read product images" ON public.product_images FOR SELECT USING (true);

-- PRODUCT VARIANTS (public read)
CREATE POLICY "Everyone can read product variants" ON public.product_variants FOR SELECT USING (true);

-- INVENTORY (public read)
CREATE POLICY "Everyone can read inventory" ON public.inventory FOR SELECT USING (true);

-- WISHLISTS (user-specific)
CREATE POLICY "Users can view own wishlist" ON public.wishlists FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can add to own wishlist" ON public.wishlists FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can remove from own wishlist" ON public.wishlists FOR DELETE USING (auth.uid() = user_id);

-- CART ITEMS (user-specific)
CREATE POLICY "Users can view own cart" ON public.cart_items FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can add to own cart" ON public.cart_items FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own cart" ON public.cart_items FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can remove from own cart" ON public.cart_items FOR DELETE USING (auth.uid() = user_id);

-- ADDRESSES (user-specific)
CREATE POLICY "Users can view own addresses" ON public.addresses FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can add own addresses" ON public.addresses FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own addresses" ON public.addresses FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own addresses" ON public.addresses FOR DELETE USING (auth.uid() = user_id);

-- COUPONS (public read for active coupons)
CREATE POLICY "Everyone can read active coupons" ON public.coupons FOR SELECT USING (is_active = true);

-- ORDERS (user-specific)
CREATE POLICY "Users can view own orders" ON public.orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own orders" ON public.orders FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ORDER ITEMS (user can view their order's items)
CREATE POLICY "Users can view own order items" ON public.order_items FOR SELECT USING (
  order_id IN (SELECT id FROM public.orders WHERE user_id = auth.uid())
);

-- PAYMENTS (user-specific)
CREATE POLICY "Users can view own payments" ON public.payments FOR SELECT USING (auth.uid() = user_id);

-- REVIEWS (public read, user-specific write)
CREATE POLICY "Everyone can read reviews" ON public.reviews FOR SELECT USING (true);
CREATE POLICY "Users can create own reviews" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own reviews" ON public.reviews FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own reviews" ON public.reviews FOR DELETE USING (auth.uid() = user_id);

-- NOTIFICATIONS (user-specific)
CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- SUPPORT TICKETS (user-specific)
CREATE POLICY "Users can view own tickets" ON public.support_tickets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own tickets" ON public.support_tickets FOR INSERT WITH CHECK (auth.uid() = user_id);

-- BANNERS (public read)
CREATE POLICY "Everyone can read active banners" ON public.banners FOR SELECT USING (is_active = true);

-- VENDORS (public read for verified vendors)
CREATE POLICY "Everyone can read verified vendors" ON public.vendors FOR SELECT USING (is_verified = true);
CREATE POLICY "Vendors can manage own store" ON public.vendors FOR ALL USING (profile_id = auth.uid());


-- ============================================================================
-- STEP 5: STORAGE BUCKETS
-- ============================================================================

INSERT INTO storage.buckets (id, name, public) VALUES ('product-images', 'product-images', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('banners', 'banners', true) ON CONFLICT (id) DO NOTHING;

-- Storage Policies (Drop first to avoid duplication errors)
DROP POLICY IF EXISTS "Product images are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Avatars are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Banners are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;

CREATE POLICY "Product images are publicly accessible" ON storage.objects FOR SELECT USING (bucket_id = 'product-images');
CREATE POLICY "Avatars are publicly accessible" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Banners are publicly accessible" ON storage.objects FOR SELECT USING (bucket_id = 'banners');
CREATE POLICY "Users can upload their own avatar" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]
);



-- ============================================================================
-- STEP 6: SEED DATA
-- ============================================================================

-- ============================================================================
-- STEP 6: SEED DATA
-- ============================================================================

-- 1. Create a dummy Auth User (for vendors, admins, and testing)
-- This allows us to have valid profiles, vendors, reviews, etc.
-- Password is 'password123'
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
VALUES (
  'd0d4e9d0-6238-4e89-bdc9-94b2a8d3e215',
  'vendor@jdsfashion.com',
  '$2a$10$vI8YV.a2S/6e1/sW7P3S3uO5BwD.n3kGj/1FqQvD7L.g2n6C.X4eq', 
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"JD Vendor Store"}',
  now(),
  now(),
  'authenticated',
  'authenticated'
) ON CONFLICT (id) DO NOTHING;

-- 2. Create the associated profile for the Vendor/Admin user
INSERT INTO public.profiles (id, role, full_name, created_at, updated_at)
VALUES (
  'd0d4e9d0-6238-4e89-bdc9-94b2a8d3e215',
  'vendor',
  'JD Vendor Store',
  now(),
  now()
) ON CONFLICT (id) DO UPDATE SET role = 'vendor';

-- 3. Create the verified Vendor store (using valid hex UUID e0000000-0000-0000-0000-000000000001)
INSERT INTO public.vendors (id, profile_id, store_name, store_description, contact_email, is_verified)
VALUES (
  'e0000000-0000-0000-0000-000000000001',
  'd0d4e9d0-6238-4e89-bdc9-94b2a8d3e215',
  'JD Luxury Official',
  'Premium fashion, apparel and accessories directly from JD.',
  'vendor@jdsfashion.com',
  true
) ON CONFLICT (id) DO NOTHING;

-- 4. Categories (with deterministic UUIDs and premium banner images)
TRUNCATE public.categories CASCADE;
INSERT INTO public.categories (id, name, slug, description, image_url) VALUES
  ('c0000000-0000-0000-0000-000000000001', 'Shirts', 'shirts', 'Premium formal and casual shirts', 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=500&q=80'),
  ('c0000000-0000-0000-0000-000000000002', 'T-Shirts', 't-shirts', 'Comfortable and stylish t-shirts', 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=500&q=80'),
  ('c0000000-0000-0000-0000-000000000003', 'Jeans', 'jeans', 'Designer denim jeans', 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=500&q=80'),
  ('c0000000-0000-0000-0000-000000000004', 'Trousers', 'trousers', 'Formal and casual trousers', 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=500&q=80'),
  ('c0000000-0000-0000-0000-000000000005', 'Hoodies', 'hoodies', 'Warm and trendy hoodies', 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=500&q=80'),
  ('c0000000-0000-0000-0000-000000000006', 'Jackets', 'jackets', 'Premium outerwear jackets', 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=500&q=80'),
  ('c0000000-0000-0000-0000-000000000007', 'Blazers', 'blazers', 'Elegant blazers for every occasion', 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=500&q=80'),
  ('c0000000-0000-0000-0000-000000000008', 'Shoes', 'shoes', 'Luxury footwear collection', 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=500&q=80'),
  ('c0000000-0000-0000-0000-000000000009', 'Watches', 'watches', 'Premium timepieces', 'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=500&q=80'),
  ('c0000000-0000-0000-0000-000000000010', 'Wallets', 'wallets', 'Leather wallets and cardholders', 'https://images.unsplash.com/photo-1627124709702-6c8f6f0491a5?w=500&q=80'),
  ('c0000000-0000-0000-0000-000000000011', 'Sunglasses', 'sunglasses', 'Designer sunglasses', 'https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=500&q=80'),
  ('c0000000-0000-0000-0000-000000000012', 'Accessories', 'accessories', 'Belts, ties, cufflinks and more', 'https://images.unsplash.com/photo-1511556532299-8f662fc26c06?w=500&q=80');

-- 5. Products (12 luxury premium fashion products using valid hex UUIDs: a0000000-...)
INSERT INTO public.products (id, vendor_id, category_id, name, slug, description, base_price, discount_price, is_active) VALUES
  ('a0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Premium Slim Fit Shirt', 'premium-slim-fit-shirt', 'A classic premium slim fit shirt crafted from high-quality 100% cotton. Features a semi-spread collar, buttoned cuffs, and a curved hemline. Perfect for both business formal and smart-casual settings.', 2499.00, 1999.00, true),
  ('a0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000007', 'Classic Oxford Blazer', 'classic-oxford-blazer', 'Elevate your wardrobe with this classic structured blazer, tailored to perfection. Crafted from a premium wool blend, it offers comfort, durability, and a sophisticated silhouette.', 8999.00, 6999.00, true),
  ('a0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000008', 'Italian Leather Shoes', 'italian-leather-shoes', 'Handcrafted dress shoes made from genuine Italian full-grain leather. Designed with a sleek cap-toe, premium leather lining, and cushioned footbed for exceptional style and comfort.', 5999.00, 4499.00, true),
  ('a0000000-0000-0000-0000-000000000004', 'e0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000009', 'Luxury Chronograph Watch', 'luxury-chronograph-watch', 'A sophisticated timepiece featuring a precision quartz movement, stainless steel case, sapphire crystal glass, and a rich leather strap. Water-resistant up to 50 meters.', 12999.00, 9999.00, true),
  ('a0000000-0000-0000-0000-000000000005', 'e0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 'Designer Denim Jeans', 'designer-denim-jeans', 'Modern slim-tapered fit jeans crafted from premium stretch denim. Features classic 5-pocket styling and unique wash details that look great casual or dressed up.', 3499.00, 2799.00, true),
  ('a0000000-0000-0000-0000-000000000006', 'e0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000005', 'Cashmere Hoodie', 'cashmere-hoodie', 'Indulgently soft knit hoodie crafted from premium lightweight Mongolian cashmere. Relaxed fit with ribbed cuffs and hem, drawstring hood, and kangaroo pocket.', 4999.00, 3999.00, true),
  ('a0000000-0000-0000-0000-000000000007', 'e0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000006', 'Bomber Jacket', 'bomber-jacket', 'Classic military-inspired bomber jacket in a water-resistant shell. Features ribbed collar, cuffs, and hem, utility sleeve pocket, and smooth satin lining.', 3999.00, 2999.00, true),
  ('a0000000-0000-0000-0000-000000000008', 'e0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000004', 'Slim Fit Chinos', 'slim-fit-chinos', 'Versatile stretch cotton chinos with a modern tapered fit. Finished with front slash pockets and button-through back pockets. Pre-washed for extra softness.', 2299.00, 1799.00, true),
  ('a0000000-0000-0000-0000-000000000009', 'e0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'Classic Cotton T-Shirt', 'classic-cotton-t-shirt', 'Essential crewneck t-shirt made from extra-soft combed cotton. Cut for a modern fit with durable double-needle stitching. Ideal for layering.', 999.00, 799.00, true),
  ('a0000000-0000-0000-0000-000000000010', 'e0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000010', 'Bifold Leather Wallet', 'bifold-leather-wallet', 'Crafted from rich vegetable-tanned leather, this slim bifold wallet features 8 card slots, a full-length bill compartment, and secure RFID protection.', 1999.00, 1499.00, true),
  ('a0000000-0000-0000-0000-000000000011', 'e0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000011', 'Aviator Sunglasses', 'aviator-sunglasses', 'Classic aviator sunglasses with lightweight metal frames and polarized, scratch-resistant lenses offering 100% UV protection.', 2999.00, 2299.00, true),
  ('a0000000-0000-0000-0000-000000000012', 'e0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000012', 'Premium Silk Tie', 'premium-silk-tie', 'Hand-stitched tie crafted from 100% premium Italian silk. Features a classic width and elegant subtle woven texture, perfect for formal events.', 1499.00, 1199.00, true)
ON CONFLICT (id) DO NOTHING;

-- 6. Product Images (Unsplash URLs using valid hex UUIDs: b0000000-...)
INSERT INTO public.product_images (id, product_id, image_url, is_primary, display_order) VALUES
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600&q=80', true, 0),
  ('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000002', 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=600&q=80', true, 0),
  ('b0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000003', 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=600&q=80', true, 0),
  ('b0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000004', 'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=600&q=80', true, 0),
  ('b0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000005', 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=600&q=80', true, 0),
  ('b0000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000006', 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=600&q=80', true, 0),
  ('b0000000-0000-0000-0000-000000000007', 'a0000000-0000-0000-0000-000000000007', 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=600&q=80', true, 0),
  ('b0000000-0000-0000-0000-000000000008', 'a0000000-0000-0000-0000-000000000008', 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=600&q=80', true, 0),
  ('b0000000-0000-0000-0000-000000000009', 'a0000000-0000-0000-0000-000000000009', 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=600&q=80', true, 0),
  ('b0000000-0000-0000-0000-000000000010', 'a0000000-0000-0000-0000-000000000010', 'https://images.unsplash.com/photo-1627124709702-6c8f6f0491a5?w=600&q=80', true, 0),
  ('b0000000-0000-0000-0000-000000000011', 'a0000000-0000-0000-0000-000000000011', 'https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=600&q=80', true, 0),
  ('b0000000-0000-0000-0000-000000000012', 'a0000000-0000-0000-0000-000000000012', 'https://images.unsplash.com/photo-1511556532299-8f662fc26c06?w=600&q=80', true, 0)
ON CONFLICT (id) DO NOTHING;

-- 7. Product Variants (Color, size, SKU using valid hex UUIDs: f0000001-...)
INSERT INTO public.product_variants (id, product_id, color, size, sku, price_adjustment) VALUES
  -- Slim Fit Shirt Variants
  ('f0000001-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Navy Blue', 'M', 'SH-SLIM-NV-M', 0.00),
  ('f0000001-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Navy Blue', 'L', 'SH-SLIM-NV-L', 0.00),
  ('f0000001-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'White', 'M', 'SH-SLIM-WT-M', 0.00),
  ('f0000001-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', 'White', 'L', 'SH-SLIM-WT-L', 0.00),

  -- Oxford Blazer Variants
  ('f0000002-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'Charcoal Grey', 'L', 'BLZ-OX-CH-L', 0.00),
  ('f0000002-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000002', 'Charcoal Grey', 'XL', 'BLZ-OX-CH-XL', 500.00),
  ('f0000002-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000002', 'Navy Blue', 'L', 'BLZ-OX-NV-L', 0.00),

  -- Leather Shoes Variants
  ('f0000003-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'Tan Brown', '9', 'SHOE-IT-TN-9', 0.00),
  ('f0000003-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000003', 'Tan Brown', '10', 'SHOE-IT-TN-10', 0.00),
  ('f0000003-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000003', 'Classic Black', '9', 'SHOE-IT-BK-9', 0.00),

  -- Luxury Watch Variants
  ('f0000004-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000004', 'Gold/Brown', 'OS', 'WTCH-LUX-GD', 0.00),
  ('f0000004-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000004', 'Silver/Black', 'OS', 'WTCH-LUX-SL', -500.00),

  -- Jeans Variants
  ('f0000005-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000005', 'Vintage Indigo', '32', 'JN-DSG-VI-32', 0.00),
  ('f0000005-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000005', 'Vintage Indigo', '34', 'JN-DSG-VI-34', 0.00),

  -- Cashmere Hoodie Variants
  ('f0000006-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000006', 'Heather Grey', 'M', 'HD-CASH-HG-M', 0.00),
  ('f0000006-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000006', 'Heather Grey', 'L', 'HD-CASH-HG-L', 0.00),

  -- Bomber Jacket Variants
  ('f0000007-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000007', 'Olive Green', 'M', 'JKT-BOMB-OL-M', 0.00),
  ('f0000007-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000007', 'Olive Green', 'L', 'JKT-BOMB-OL-L', 0.00),

  -- Chinos Variants
  ('f0000008-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000008', 'Khaki', '32', 'CHN-SLIM-KK-32', 0.00),
  ('f0000008-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000008', 'Khaki', '34', 'CHN-SLIM-KK-34', 0.00),

  -- T-Shirt Variants
  ('f0000009-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000009', 'Jet Black', 'M', 'TSH-CL-BK-M', 0.00),
  ('f0000009-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000009', 'Jet Black', 'L', 'TSH-CL-BK-L', 0.00),

  -- Wallet Variants
  ('f0000010-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000010', 'Chocolate Brown', 'OS', 'WLT-BIF-BR', 0.00),

  -- Sunglasses Variants
  ('f0000011-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000011', 'Black/Gold', 'OS', 'SUN-AV-BKGD', 0.00),

  -- Tie Variants
  ('f0000012-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000012', 'Burgundy Red', 'OS', 'TIE-SLK-BG', 0.00)
ON CONFLICT (id) DO NOTHING;

-- 8. Inventory (Stock levels using valid hex UUIDs: e0000002-...)
INSERT INTO public.inventory (id, variant_id, quantity, low_stock_threshold) VALUES
  ('e0000002-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000001', 50, 5),
  ('e0000002-0000-0000-0000-000000000002', 'f0000001-0000-0000-0000-000000000002', 45, 5),
  ('e0000002-0000-0000-0000-000000000003', 'f0000001-0000-0000-0000-000000000003', 30, 5),
  ('e0000002-0000-0000-0000-000000000004', 'f0000001-0000-0000-0000-000000000004', 25, 5),
  ('e0000002-0000-0000-0000-000000000005', 'f0000002-0000-0000-0000-000000000001', 12, 3),
  ('e0000002-0000-0000-0000-000000000006', 'f0000002-0000-0000-0000-000000000002', 8, 3),
  ('e0000002-0000-0000-0000-000000000007', 'f0000002-0000-0000-0000-000000000003', 15, 3),
  ('e0000002-0000-0000-0000-000000000008', 'f0000003-0000-0000-0000-000000000001', 20, 4),
  ('e0000002-0000-0000-0000-000000000009', 'f0000003-0000-0000-0000-000000000002', 18, 4),
  ('e0000002-0000-0000-0000-000000000010', 'f0000003-0000-0000-0000-000000000003', 25, 4),
  ('e0000002-0000-0000-0000-000000000011', 'f0000004-0000-0000-0000-000000000001', 5, 2),
  ('e0000002-0000-0000-0000-000000000012', 'f0000004-0000-0000-0000-000000000002', 10, 2),
  ('e0000002-0000-0000-0000-000000000013', 'f0000005-0000-0000-0000-000000000001', 40, 5),
  ('e0000002-0000-0000-0000-000000000014', 'f0000005-0000-0000-0000-000000000002', 35, 5),
  ('e0000002-0000-0000-0000-000000000015', 'f0000006-0000-0000-0000-000000000001', 15, 3),
  ('e0000002-0000-0000-0000-000000000016', 'f0000006-0000-0000-0000-000000000002', 12, 3),
  ('e0000002-0000-0000-0000-000000000017', 'f0000007-0000-0000-0000-000000000001', 25, 4),
  ('e0000002-0000-0000-0000-000000000018', 'f0000007-0000-0000-0000-000000000002', 20, 4),
  ('e0000002-0000-0000-0000-000000000019', 'f0000008-0000-0000-0000-000000000001', 30, 5),
  ('e0000002-0000-0000-0000-000000000020', 'f0000008-0000-0000-0000-000000000002', 30, 5),
  ('e0000002-0000-0000-0000-000000000021', 'f0000009-0000-0000-0000-000000000001', 100, 10),
  ('e0000002-0000-0000-0000-000000000022', 'f0000009-0000-0000-0000-000000000002', 90, 10),
  ('e0000002-0000-0000-0000-000000000023', 'f0000010-0000-0000-0000-000000000001', 40, 5),
  ('e0000002-0000-0000-0000-000000000024', 'f0000011-0000-0000-0000-000000000001', 25, 3),
  ('e0000002-0000-0000-0000-000000000025', 'f0000012-0000-0000-0000-000000000001', 50, 5)
ON CONFLICT (id) DO NOTHING;

-- 9. Coupons (Promo codes using valid hex UUIDs: e0000003-...)
INSERT INTO public.coupons (id, code, description, discount_percentage, discount_amount, min_order_value, max_discount, is_active) VALUES
  ('e0000003-0000-0000-0000-000000000001', 'WELCOME10', 'Get 10% off on your first order.', 10.00, NULL, 1500.00, 1000.00, true),
  ('e0000003-0000-0000-0000-000000000002', 'JDFASHION500', 'Flat ₹500 off on orders above ₹2999.', NULL, 500.00, 2999.00, 500.00, true),
  ('e0000003-0000-0000-0000-000000000003', 'FESTIVE30', 'Super festive discount of 30% on premium styles.', 30.00, NULL, 5000.00, 3000.00, true)
ON CONFLICT (id) DO NOTHING;

-- 10. Banners (Promo carousel banners using valid hex UUIDs: e0000004-...)
INSERT INTO public.banners (id, title, image_url, link_url, is_active, display_order) VALUES
  ('e0000004-0000-0000-0000-000000000001', 'Exclusive Summer Sale: Up to 50% Off', 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1000&q=80', '/category/shirts', true, 1),
  ('e0000004-0000-0000-0000-000000000002', 'Premium Watch Collection - Shop Elegance', 'https://images.unsplash.com/photo-1522312346375-d1a52e2b99b3?w=1000&q=80', '/category/watches', true, 2),
  ('e0000004-0000-0000-0000-000000000003', 'Royal Blazers & Formalwear: Style Redefined', 'https://images.unsplash.com/photo-1593032465175-481ac7f401a0?w=1000&q=80', '/category/blazers', true, 3)
ON CONFLICT (id) DO NOTHING;

-- 11. Sample Address (using valid hex UUID: e0000005-...)
INSERT INTO public.addresses (id, user_id, title, address_line_1, address_line_2, city, state, postal_code, country, is_default) VALUES
  ('e0000005-0000-0000-0000-000000000001', 'd0d4e9d0-6238-4e89-bdc9-94b2a8d3e215', 'JD HQ Office', '101 Luxury Avenue', 'Sector 5, DLF Phase 3', 'Gurugram', 'Haryana', '122002', 'India', true)
ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- DONE! Your database is fully set up.
-- ============================================================================


-- ============================================================================
-- DONE! Your database is fully set up.
-- ============================================================================
