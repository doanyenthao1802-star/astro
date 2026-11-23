# Astro Cinema - Hướng dẫn Cài đặt & Vận hành

Dự án rạp chiếu phim trực tuyến Astro Cinema tích hợp Supabase Database (Lưu trữ người dùng, phim, vé), Cổng thanh toán VNPay Sandbox & Trang quản trị Admin.

---

## 1. Cấu trúc dự án
- `public/`: Giao diện người dùng
  - `index.html`: Trang chủ & đặt vé Astro Cinema
  - `admin.html`: Trang quản trị Admin (Thêm/Sửa/Xóa phim, xem vé)
  - `script.js`: Xử lý giao diện, chọn ghế, tương tác
  - `supabase-client.js`: Thư viện kết nối Supabase, Auth, Profiles, Movies, Tickets
  - `style.css`: Hệ thống thiết kế Dark Cinematic
- `api/` & `lib/`:
  - `lib/vnpay.js`: Xử lý tạo URL thanh toán VNPay, xác thực chữ ký số HMAC-SHA512
  - `api/config.js`: Cung cấp cấu hình public Supabase & Admin
  - `api/orders.js` & `api/order.js`: Tra cứu thông tin vé & đơn hàng
  - `api/vnpay-return.js` & `api/vnpay-ipn.js`: Tiếp nhận kết quả thanh toán
- `supabase_schema.sql`: Script khởi tạo cơ sở dữ liệu trên Supabase
- `server.js`: Web server Node.js chạy thử nghiệm cục bộ
- `.env`: File cấu hình biến môi trường

---

## 2. Hướng dẫn thiết lập Supabase

1. Truy cập [https://supabase.com](https://supabase.com) và tạo một dự án mới (miễn phí).
2. Vào **SQL Editor** trong thanh menu bên trái của Supabase Dashboard.
3. Mở file [supabase_schema.sql](file:///c:/Users/ADMIN/astro-firebase/astro-firebase/supabase_schema.sql), sao chép toàn bộ nội dung và dán vào SQL Editor, sau đó bấm **Run**.
   - Script sẽ tạo 3 bảng chính: `profiles`, `movies`, `tickets`
   - Kích hoạt phân quyền bảo mật Row Level Security (RLS)
   - Tự động nạp sẵn 8 phim mẫu ban đầu
4. Vào **Project Settings > API** trong Supabase:
   - Sao chép **Project URL**
   - Sao chép **anon public API Key**
5. Mở file [.env](file:///c:/Users/ADMIN/astro-firebase/astro-firebase/.env) và điền:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ADMIN_PIN=astro2026
   ```
   *(Ngoài ra, bạn cũng có thể nhập trực tiếp URL và Key trong tab Cấu hình của trang Admin)*

---

## 3. Trang Quản trị Admin (`/admin.html`)

- Đường dẫn truy cập: [http://localhost:3000/admin.html](http://localhost:3000/admin.html)
- Mã PIN mặc định: `astro2026` (có thể đổi trong file `.env`)
- Tính năng:
  - **Quản lý phim (CRUD)**:
    - Xem danh sách phim, tìm kiếm theo tên, thể loại, định dạng
    - **Thêm phim mới**: Tên, thể loại, thời lượng, định dạng (2D/3D/IMAX), điểm đánh giá, độ tuổi, đạo diễn, diễn viên, tóm tắt nội dung, ảnh bìa (class preset hoặc link ảnh tùy chỉnh)
    - **Chỉnh sửa phim**: Cập nhật thông tin phim tức thì lên Supabase
    - **Xóa phim**: Xóa phim khỏi cơ sở dữ liệu
    - **Nạp lại 8 phim mẫu**: Khôi phục danh sách phim ban đầu chỉ bằng 1 cú nhấp
  - **Quản lý đơn hàng & vé**: Theo dõi toàn bộ lịch sử đặt vé từ khách hàng trong thời gian thực, xem ghế đã chọn và tổng doanh thu
  - **Cấu hình & kiểm tra Supabase**: Kiểm tra kết nối cơ sở dữ liệu trực tiếp từ giao diện

---

## 4. Tối ưu phần Thanh toán & Đặt vé

1. **Khắc phục lỗi xác thực đơn hàng**:
   - Sau khi thanh toán VNPay, hệ thống tự động nhận diện mã đơn và mã bảo mật `t`, tự động lưu vé vào bảng `tickets` trên Supabase dưới tài khoản của khách hàng và cộng điểm tích lũy.
2. **Bổ sung tùy chọn thanh toán kép**:
   - **Cổng VNPay Sandbox**: Dành cho thanh toán qua cổng VNPay với thẻ test sandbox.
   - **Thanh toán Trực tiếp / Thử nghiệm nhanh**: Xác nhận vé ngay lập tức mà không cần chuyển trang hoặc nhập thẻ sandbox, lý tưởng khi cần demo hoặc kiểm tra nhanh toàn bộ luồng lưu dữ liệu lên Supabase.
3. **Vé điện tử & In vé**:
   - Khi hoàn tất, hiển thị chi tiết mã vé, suất chiếu, ghế ngồi và có nút **"In / Tải vé điện tử"**.

---

## 5. Chạy ứng dụng

1. Mở Terminal tại thư mục `astro-firebase`
2. Chạy lệnh:
   ```bash
   node server.js
   ```
3. Mở trình duyệt:
   - Giao diện khách hàng: [http://localhost:3000](http://localhost:3000)
   - Giao diện quản trị: [http://localhost:3000/admin.html](http://localhost:3000/admin.html)
