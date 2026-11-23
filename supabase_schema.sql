-- ==============================================================
-- ASTRO CINEMA - SUPABASE DATABASE SCHEMA
-- Chạy script này trong Supabase Dashboard > SQL Editor > New query > Run
-- ==============================================================

-- 1. Kích hoạt extension cần thiết
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. BẢNG PROFILES (Thông tin người dùng mở rộng)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL DEFAULT '',
  phone TEXT DEFAULT '',
  bio TEXT DEFAULT '',
  level TEXT DEFAULT 'SILVER',
  points INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 3. BẢNG MOVIES (Quản lý phim đang chiếu / sắp chiếu cho Admin)
CREATE TABLE IF NOT EXISTS public.movies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT UNIQUE NOT NULL,
  genre TEXT NOT NULL DEFAULT 'Hành động',
  duration INTEGER NOT NULL DEFAULT 120,
  rating TEXT NOT NULL DEFAULT '4.8',
  format TEXT NOT NULL DEFAULT '2D',
  poster TEXT NOT NULL DEFAULT 'g1',
  poster_url TEXT DEFAULT '',
  director TEXT DEFAULT '',
  cast_members TEXT DEFAULT '',
  age_rating TEXT DEFAULT 'T13',
  plot TEXT DEFAULT '',
  trailer TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 4. BẢNG TICKETS (Lịch sử đặt vé & thanh toán)
CREATE TABLE IF NOT EXISTS public.tickets (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  user_email TEXT NOT NULL,
  movie_title TEXT NOT NULL,
  poster TEXT DEFAULT 'g1',
  show_date TEXT NOT NULL,
  show_time TEXT NOT NULL,
  format TEXT NOT NULL DEFAULT '2D',
  seats JSONB NOT NULL DEFAULT '[]'::jsonb,
  total_price INTEGER NOT NULL DEFAULT 0,
  coupon TEXT DEFAULT '',
  payment_method TEXT NOT NULL DEFAULT 'vnpay',
  status TEXT NOT NULL DEFAULT 'paid',
  vnp_txn TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- ==============================================================
-- BẢO MẬT ROW LEVEL SECURITY (RLS)
-- ==============================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.movies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;

-- Policy cho Profiles:
CREATE POLICY "Public profiles are viewable by everyone" 
  ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile" 
  ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id OR auth.role() = 'anon');

CREATE POLICY "Users can update their own profile" 
  ON public.profiles FOR UPDATE USING (auth.uid() = id OR auth.role() = 'anon');

CREATE POLICY "Users can delete their own profile" 
  ON public.profiles FOR DELETE USING (auth.uid() = id OR auth.role() = 'anon');

-- Policy cho Movies:
CREATE POLICY "Movies are viewable by everyone" 
  ON public.movies FOR SELECT USING (true);

CREATE POLICY "Allow movie management" 
  ON public.movies FOR ALL USING (true) WITH CHECK (true);

-- Policy cho Tickets:
CREATE POLICY "Tickets viewable by owner or anon" 
  ON public.tickets FOR SELECT USING (true);

CREATE POLICY "Allow ticket booking" 
  ON public.tickets FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow ticket update" 
  ON public.tickets FOR UPDATE USING (true);

-- ==============================================================
-- TRIGGER TỰ ĐỘNG TẠO PROFILE KHI USER ĐĂNG KÝ AUTH
-- ==============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name, level, points)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    'SILVER',
    0
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = COALESCE(EXCLUDED.name, public.profiles.name);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================
-- DỮ LIỆU PHIM MẪU BAN ĐẦU (SEED DATA)
-- ==============================================================
INSERT INTO public.movies (title, genre, duration, rating, format, poster, director, cast_members, age_rating, plot)
VALUES
('Đêm Cuối Cùng', 'Hành động, Kịch tính', 128, '4.8', 'IMAX', 'g1', 'Minh Khôi', 'Lan Phương, Quốc Anh, Thu Hà', 'T13', 'Thành phố chìm trong bóng tối sau một trận mất điện kéo dài. Một nhóm người xa lạ buộc phải cùng nhau băng qua những con phố đổ nát để tới điểm sơ tán cuối cùng trước khi trời sáng. Chỉ có một lối ra và rất ít thời gian.'),
('Parasite', 'Chính kịch, Giật gân', 132, '4.9', '2D', 'g2', 'Bong Joon-ho', 'Song Kang-ho, Choi Woo-shik, Park So-dam', 'T16', 'Cả một gia đình nghèo khó lần lượt tìm cách len vào làm việc trong nhà của một gia đình giàu có. Mọi thứ suôn sẻ cho tới khi một bí mật bị giấu kín lộ ra và cuộc chơi đổi chiều.'),
('It: Chapter Two', 'Kinh dị, Siêu nhiên', 169, '4.6', 'IMAX', 'g3', 'Andy Muschietti', 'Jessica Chastain, James McAvoy, Bill Hader', 'T18', 'Hai mươi bảy năm sau, nhóm bạn thuở nhỏ trở lại thị trấn Derry để đối mặt với thứ đã ám ảnh họ. Muốn kết thúc nó, họ phải nhớ lại điều mà chính mình đã cố quên.'),
('Interstellar', 'Sci-Fi, Khám phá', 169, '5.0', 'IMAX', 'g4', 'Christopher Nolan', 'Matthew McConaughey, Anne Hathaway, Jessica Chastain', 'T13', 'Trái Đất dần không còn sống được. Một nhóm phi hành gia bay qua hố giun để tìm ngôi nhà mới cho loài người, đánh đổi nhiều năm xa gia đình để cứu tất cả.'),
('Thành Phố Neon', 'Cyberpunk, Hành động', 115, '4.5', '3D', 'g5', 'Hải Đăng', 'Khánh Vy, Đức Minh, Bảo Ngọc', 'T16', 'Trong một thành phố sáng rực đèn neon, một nữ thám tử mạng lần theo tin tặc đứng sau hàng loạt vụ xóa ký ức. Càng đi sâu, cô càng nghi ngờ chính ký ức của mình.'),
('Ghost In The Shell', 'Hành động, Viễn tưởng', 106, '4.4', '3D', 'g6', 'Rupert Sanders', 'Scarlett Johansson, Pilou Asbæk, Takeshi Kitano', 'T13', 'Thiếu tá Mira Killian là người đầu tiên được ghép não người vào cơ thể máy, và cô dẫn đầu đội chống tội phạm mạng. Khi truy đuổi một hacker nguy hiểm, cô phát hiện sự thật về quá khứ của mình.'),
('Máu Lạnh', 'Tội phạm, Hồi hộp', 121, '4.3', '2D', 'g7', 'Thanh Sơn', 'Hoàng Nam, Mai Anh, Tuấn Kiệt', 'T18', 'Một vụ án mạng xảy ra trong đêm mưa ở thị trấn nhỏ. Người điều tra dần nhận ra mọi nhân chứng đều có lý do để nói dối.'),
('Sa Mạc Đỏ', 'Phiêu lưu, Chính kịch', 140, '4.7', 'IMAX', 'g8', 'Quang Vinh', 'Minh Thư, Gia Bảo, Đức Hiếu', 'T13', 'Hai người xa lạ cùng băng qua sa mạc đỏ để tìm một ốc đảo chỉ tồn tại trong truyền thuyết. Cạn nước, lạc đường, họ buộc phải học cách tin nhau.')
ON CONFLICT (title) DO NOTHING;
