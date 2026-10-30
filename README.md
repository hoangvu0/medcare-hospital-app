# MedCare

Ứng dụng Flutter dành cho người bệnh: đăng nhập, tìm bác sĩ, đặt lịch,
quản lý hồ sơ, bệnh án, đơn thuốc, xét nghiệm và thanh toán.

## Chạy dự án

```bash
flutter pub get
flutter run
flutter test
```

### Chạy app với backend thật ở máy local

Mở terminal thứ nhất:

```bash
cd server
dart pub get
dart run bin/server.dart
```

Mở terminal thứ hai. Android Emulator dùng `10.0.2.2`, còn Chrome/Edge dùng
`127.0.0.1`:

```bash
flutter run --dart-define=MEDCARE_API_BASE_URL=http://10.0.2.2:8080
```

Các cấu hình tương ứng đã có sẵn trong `.vscode/launch.json`.

Ứng dụng có kho dữ liệu tại chỗ (`MedicalStore`) để giữ trạng thái tạm thời và
cache khi mất mạng. Dữ liệu nghiệp vụ dùng cho môi trường thật phải được đồng
bộ với backend và database server.

Luồng đăng ký dùng SMS OTP thật khi backend được cấu hình với Twilio Verify:
`TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN` và `TWILIO_VERIFY_SERVICE_SID`.
Nếu chưa cấu hình backend/SMS, màn đăng ký sẽ không cho xác thực OTP; app không
tự sinh hoặc hiển thị mã OTP trên thiết bị.

Khi `MEDCARE_API_BASE_URL` được cấu hình và người dùng đăng nhập backend, bước
Xác nhận đặt lịch sẽ gọi `POST /appointments` trước khi cập nhật dữ liệu cục
bộ. Không có backend thì app không thể tạo lịch khám thật.

Thanh toán tạo yêu cầu xác minh và chỉ chuyển thành công sau callback đã xác
thực từ cổng thanh toán hoặc đối soát của bệnh viện. Không có backend/cổng
thanh toán thật thì app giữ trạng thái chờ, không tự báo thành công.

Chat AI cũng không tự sinh câu trả lời y khoa khi thiếu dịch vụ bên ngoài; cần
cấu hình Gemini hoặc tích hợp Infermedica ở backend. Các chức năng cấp cứu,
bảo lãnh và thanh toán cần kết nối lần lượt với tổng đài/dispatcher, API bảo
hiểm và cổng thanh toán thật trước khi triển khai cho người bệnh.

Tin tức được backend đồng bộ từ RSS sức khỏe và trang Tin tức & Sự kiện của
Bệnh viện Đại học Y Dược TP. Hồ Chí Minh; khi nguồn ngoài tạm thời lỗi, app
hiển thị trạng thái lỗi để người dùng biết dữ liệu chưa được cập nhật.

## Kiến trúc

- `lib/models`: model nghiệp vụ.
- `lib/state`: state dùng chung và các thao tác nghiệp vụ tạm thời.
- `lib/pages`: giao diện theo từng chức năng.
- `lib/routes`: tên route tập trung.
- `lib/config`: cấu hình runtime.

## Kết nối môi trường thật

Sao chép `.env.example` sang hệ thống CI/CD hoặc truyền cấu hình qua
`--dart-define`, ví dụ:

```bash
flutter run --dart-define=MEDCARE_API_BASE_URL=https://api.your-domain.tld \
  --dart-define=MEDCARE_PAYMENT_BANK_CODE=TCB \
  --dart-define=MEDCARE_PAYMENT_BANK_ACCOUNT=YOUR_REAL_ACCOUNT \
  --dart-define=MEDCARE_PAYMENT_BANK_NAME=YOUR_HOSPITAL_ACCOUNT_NAME
```

Trước khi phát hành cần thay `MedicalStore` bằng repository/API có xác thực,
secure storage, kiểm soát phân quyền, audit log, mã hóa dữ liệu y tế và cơ chế
thanh toán/notification do đơn vị cung cấp dịch vụ xác nhận. Không đưa khóa bí
mật hay thông tin bệnh án thật vào repository.
