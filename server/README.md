# MedCare Backend

Backend API rieng cho app benh vien MedCare: SQLite server-side, JWT access token, refresh token, RBAC, audit log va realtime queue bang Server-Sent Events.

## Chay local

```powershell
cd server
dart pub get
$env:MEDCARE_JWT_SECRET="change-this-long-random-secret"
$env:MEDCARE_DB_PATH="medcare_server.sqlite"
$env:GEMINI_API_KEY="YOUR_GOOGLE_AI_STUDIO_KEY"
$env:MEDCARE_GEMINI_MODEL="gemini-3.8-flash"
$env:INFERMEDICA_APP_ID="YOUR_INFERMEDICA_APP_ID"
$env:INFERMEDICA_APP_KEY="YOUR_INFERMEDICA_APP_KEY"
$env:MEDCARE_PAYMENT_WEBHOOK_SECRET="YOUR_LONG_RANDOM_WEBHOOK_SECRET"
$env:MEDCARE_NEWS_FEEDS="https://vnexpress.net/rss/suc-khoe.rss,https://suckhoedoisong.vn/y-te.rss"
dart run bin/server.dart
```

Mac/Linux:

```bash
cd server
dart pub get
MEDCARE_JWT_SECRET=change-this-long-random-secret MEDCARE_DB_PATH=medcare_server.sqlite GEMINI_API_KEY=YOUR_GOOGLE_AI_STUDIO_KEY MEDCARE_GEMINI_MODEL=gemini-3.8-flash INFERMEDICA_APP_ID=YOUR_INFERMEDICA_APP_ID INFERMEDICA_APP_KEY=YOUR_INFERMEDICA_APP_KEY MEDCARE_PAYMENT_WEBHOOK_SECRET=YOUR_LONG_RANDOM_WEBHOOK_SECRET dart run bin/server.dart
```

Mac dinh server lang nghe `http://127.0.0.1:8080`.

## Tai khoan seed

| Vai tro | Dang nhap | Mat khau |
| --- | --- | --- |
| Patient | `vu@example.com` | `123456` |
| Doctor | `doctor@medcare.vn` | `123456` |
| Doctor | `bacsi@medcare.vn` | `123456` |
| Admin | `admin@medcare.vn` | `admin123` |

## Noi app Flutter voi backend

Dang nhap lay `accessToken`, sau do chay app voi:

```powershell
flutter run --dart-define=MEDCARE_API_BASE_URL=http://127.0.0.1:8080 --dart-define=MEDCARE_API_BEARER_TOKEN=<accessToken>
```

`/sync` se bi tu choi neu khong co Bearer token hop le.

## Google AI Studio / Gemini

Endpoint chat AI cua app la `POST /ai/chat`. Backend se doc key tu `GEMINI_API_KEY` hoac `GOOGLE_API_KEY`, goi Gemini `generateContent`, roi tra ve text cho app. Khong dua key vao Flutter client de tranh lo key.

Neu chua cau hinh key, `/ai/chat` tra ve HTTP 503 va app hien thi trang thai chua ket noi AI; app khong tu sinh cau tra loi y khoa.

## Thanh toan that va nap vi

`POST /payments/confirm` chi tao yeu cau doi xac minh va luon co the chay khi chua cau hinh cong thanh toan. Khi chua co webhook, giao dich giu o `pending` de admin vao `Duyet nghiep vu` duyet thu cong. Khong tu dong ghi nhan thanh cong. Khi da ket noi cong thanh toan, cong thanh toan hoac dich vu doi soat cua benh vien goi:

```text
POST /payments/webhook
x-medcare-webhook-secret: MEDCARE_PAYMENT_WEBHOOK_SECRET
Content-Type: application/json
```

Body toi thieu: `{"clientTransactionId":"...","status":"success","receiptCode":"..."}`. App chi cap nhat giao dich/so du sau khi webhook hop le hoac khi truy van lai `GET /payments/<clientTransactionId>`.

Can cau hinh thu cong tai nha cung cap thanh toan: merchant account, chu ky/webhook signature va URL cong khai cua server. Khong dung tai khoan ngan hang mau trong moi truong production.

Admin co the doi soat thu cong qua giao dien `Duyệt nghiệp vụ` (day la luong bat buoc cho moi giao dich `pending` khi chua cau hinh webhook):

- `GET /payments` va `PATCH /payments/<clientTransactionId>`: xem, duyet (`success`) hoac tu choi (`failed`) giao dich; co the ghi ma bien lai.
- `GET /cashless-claims` va `PATCH /cashless-claims/<id>`: xem va duyet (`approved`) hoac tu choi (`rejected`) yeu cau bao lanh. Chi tai khoan `admin`/`doctor` duoc cap quyen cap nhat.

Admin co the van hanh app qua giao dien `Điều hành`:

- `GET /admin/users`: xem danh sach benh nhan, bac si va admin.
- `PATCH /admin/users/<id>`: khoa/mo khoa tai khoan hoac cap nhat ten hien thi; admin khong the tu khoa chinh minh.
- `GET /appointments`: admin xem toan bo lich hen cua he thong.
- `PATCH /appointments/<id>`: admin cap nhat trang thai lich hen, vi du huy lich khi can.
- Cac thao tac dieu hanh duoc ghi vao audit log de truy vet.

Luồng bác sĩ - bệnh nhân:

- `GET /appointments`: bác sĩ chỉ nhận các lịch hẹn thuộc chính mình; bệnh nhân chỉ nhận lịch của mình; admin nhận toàn bộ.
- `POST /consultations/complete`: bác sĩ gửi `appointmentId`, chẩn đoán, bệnh án và danh sách thuốc. Backend kiểm tra bác sĩ có đúng lịch hẹn không, ghi EMR + đơn thuốc, chuyển lịch sang `completed` trong một luồng và audit thao tác.
- `GET /records` và `GET /prescriptions`: bệnh nhân đọc lại dữ liệu đã được bác sĩ ký gửi từ SQLite backend.

Tai khoan benh nhan duoc tao tu dong sau khi xac minh OTP thanh cong. Co the chon SMS OTP (Twilio) hoac Email/Gmail OTP (SMTP Gmail); admin khong phe duyet thu cong buoc dang ky.

## Dich vu ben ngoai can cau hinh thu cong

- SMS OTP: `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_VERIFY_SERVICE_SID`.
- Email/Gmail OTP: `MEDCARE_EMAIL_USERNAME` và `MEDCARE_EMAIL_APP_PASSWORD`. Với Gmail phải bật xác thực 2 bước và tạo App Password; không dùng mật khẩu Gmail chính. Có thể đặt tên người gửi bằng `MEDCARE_EMAIL_FROM_NAME`.
- AI: `INFERMEDICA_APP_ID` + `INFERMEDICA_APP_KEY` (duoc uu tien cho chat sang loc) hoac `GEMINI_API_KEY`/`GOOGLE_API_KEY` de tra loi tu nhien. Infermedica yeu cau App ID/App Key va luu credential o backend, khong dat trong Flutter client. NLP `/parse` cua Infermedica hien ho tro tot nhat tieng Anh; voi chat tieng Viet can cap them lop chuyen ngu/nguon AI phu hop.
- Thanh toan: tai khoan VietQR/Napas/VNPay/ZaloPay that va webhook doi soat.
- Kham tu xa: nha cung cap video/signaling va chinh sach luu tru ban ghi.
- Bao lanh vien phi: API/credential cua cong ty bao hiem; hien app gui yeu cau pending, khong tu phe duyet.
- Cap cuu: tong dai/dispatcher/HIS cua benh vien; SOS hien lay GPS that va mo cuoc goi that, chua the tu dieu xe neu chua co API dispatcher.


## Tin tuc benh vien tu dong

Endpoint `GET /news` lay tin moi tu RSS/API benh vien va tra ve danh sach `articles` cho app. Mac dinh backend dung cac RSS suc khoe/y te cong khai. Co the doi sang RSS benh vien rieng hoac them nhieu nguon bang bien moi truong `MEDCARE_NEWS_FEEDS`, ngan cach boi dau phay.

Vi du:

```powershell
$env:MEDCARE_NEWS_FEEDS="https://vnexpress.net/rss/suc-khoe.rss,https://suckhoedoisong.vn/y-te.rss"
```

Neu nguon RSS bi loi hoac mat mang, backend tra ve tin du phong de man hinh Tin tuc van chay duoc.

## Hop dong API

Xem chi tiet o `openapi.yaml`.
