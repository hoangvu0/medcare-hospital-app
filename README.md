# MedCare

Ứng dụng Flutter mẫu dành cho người bệnh: đăng nhập, tìm bác sĩ, đặt lịch,
quản lý hồ sơ, bệnh án, đơn thuốc, xét nghiệm và thanh toán.

## Chạy dự án

```bash
flutter pub get
flutter run
flutter test
```

Ứng dụng hiện có một kho dữ liệu tại chỗ (`MedicalStore`) để demo luồng đầy
đủ từ đăng nhập đến xác nhận/hủy lịch. Dữ liệu này chỉ tồn tại trong bộ nhớ và
sẽ mất khi khởi động lại app.

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
flutter run --dart-define=MEDCARE_API_BASE_URL=https://api.your-domain.tld
```

Trước khi phát hành cần thay `MedicalStore` bằng repository/API có xác thực,
secure storage, kiểm soát phân quyền, audit log, mã hóa dữ liệu y tế và cơ chế
thanh toán/notification do đơn vị cung cấp dịch vụ xác nhận. Không đưa khóa bí
mật hay thông tin bệnh án thật vào repository.
