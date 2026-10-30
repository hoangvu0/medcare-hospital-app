from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.shared import Pt
from docx.text.paragraph import Paragraph
from docx.oxml import OxmlElement


SOURCE = Path(r"C:\Users\hoangvu\Downloads\2324801030027_2324801030077_2324801030052_Nhom09_XayDungUngDungHoTroKhamBenhVaChamSocSucKhoeBangFlutter_ban_cuoi.docx")
OUTPUT = Path(r"C:\Users\hoangvu\Downloads\2324801030027_2324801030077_2324801030052_Nhom09_XayDungUngDungHoTroKhamBenhVaChamSocSucKhoeBangFlutter_ban_cuoi_huong_dan_chup_man_hinh.docx")


def insert_before(anchor, text, bold=False, size=None):
    p = OxmlElement("w:p")
    anchor._p.addprevious(p)
    paragraph = Paragraph(p, anchor._parent)
    run = paragraph.add_run(text)
    run.bold = bold
    if size:
        run.font.size = Pt(size)
    return paragraph


doc = Document(str(SOURCE))
anchor = next(p for p in doc.paragraphs if p.text.startswith("4.6. Kiểm thử và đánh giá"))

insert_before(anchor, "4.5.2. Danh sách màn hình chức năng chính cần chụp", bold=True, size=13)
insert_before(anchor, "Để chương 4 phản ánh đúng phiên bản đã chạy, nhóm nên chụp màn hình từ thiết bị thật/emulator sau khi backend đang hoạt động. Mỗi ảnh cần có tiêu đề, vai trò sử dụng và trạng thái dữ liệu; không chụp màn hình lỗi, dữ liệu trống hoặc dữ liệu mẫu không liên quan.")

screens = [
    ("Ảnh 1 – Đăng nhập", "Bệnh nhân/ bác sĩ/ admin", "Hiển thị email hoặc mã bệnh nhân, mật khẩu, nút đăng nhập, trạng thái đang xác thực và điều hướng đúng vai trò."),
    ("Ảnh 2 – Đăng ký và OTP", "Bệnh nhân", "Hiển thị họ tên, số điện thoại, email, mật khẩu, bước gửi OTP và kết quả tạo đúng hồ sơ mới."),
    ("Ảnh 3 – Trang chủ bệnh nhân", "Bệnh nhân", "Hiển thị tên bệnh nhân đúng tài khoản, ảnh nền bệnh viện, dịch vụ chính, bác sĩ, lịch gần nhất, ví viện phí và chuông thông báo."),
    ("Ảnh 4 – Tìm kiếm bác sĩ", "Bệnh nhân", "Hiển thị từ khóa tìm kiếm, bác sĩ, chuyên khoa, kinh nghiệm, phí khám, lịch trống và nút xem chi tiết/đặt lịch."),
    ("Ảnh 5 – Chi tiết bác sĩ và đặt lịch", "Bệnh nhân", "Hiển thị hồ sơ bác sĩ, khoa, phòng, ngày giờ, gói khám, phí và xác nhận slot trước khi tạo lịch."),
    ("Ảnh 6 – Thanh toán QR chờ duyệt", "Bệnh nhân", "Hiển thị đúng số tiền của gói khám, ngân hàng/tài khoản nhận, nội dung chuyển khoản, mã giao dịch và nút gửi yêu cầu xác nhận."),
    ("Ảnh 7 – Admin duyệt thanh toán", "Admin", "Hiển thị giao dịch pending, bệnh nhân, lịch hẹn, gói khám, số tiền và thao tác duyệt/từ chối. Sau duyệt phải có trạng thái success/confirmed."),
    ("Ảnh 8 – Cấp số và hàng đợi", "Bệnh nhân + bác sĩ", "Hiển thị mã lịch, phòng, số thứ tự đang gọi và số tiếp theo. Hai thiết bị phải hiển thị cùng một số."),
    ("Ảnh 9 – Bàn làm việc bác sĩ", "Bác sĩ", "Hiển thị ca khám đã xác nhận, tiếp nhận bệnh nhân, gọi số tiếp theo và thông tin gói khám."),
    ("Ảnh 10 – Sinh hiệu và khám ICD-10", "Bác sĩ", "Hiển thị huyết áp, nhịp tim, SpO2, nhiệt độ, cân nặng, triệu chứng, chẩn đoán và mã ICD-10 trước khi lưu."),
    ("Ảnh 11 – Cận lâm sàng, ảnh và đơn thuốc", "Bác sĩ", "Hiển thị chỉ định xét nghiệm/X-quang/nội soi, tải tệp hoặc ảnh, thuốc, liều, số ngày, hướng dẫn và trạng thái gửi bệnh nhân."),
    ("Ảnh 12 – Bệnh án và chuông thông báo", "Bệnh nhân", "Hiển thị bệnh án, xét nghiệm gần nhất, hình ảnh, đơn thuốc, lời dặn và thông báo mới từ bác sĩ tại biểu tượng chuông."),
    ("Ảnh 13 – Quản trị bác sĩ, slot và audit", "Admin", "Hiển thị danh sách bác sĩ, khoa, phòng, lịch làm việc, capacity, số chỗ còn lại và nhật ký thao tác."),
    ("Ảnh 14 – Gói tầm soát/tiêm chủng", "Bệnh nhân + admin", "Bệnh nhân gửi đăng ký gói; admin nhận yêu cầu, xem thông tin, cập nhật trạng thái tiếp nhận và tạo thông báo phản hồi."),
]

for title, role, detail in screens:
    p = insert_before(anchor, f"{title} — Vai trò: {role}", bold=True)
    p.paragraph_format.space_before = Pt(5)
    insert_before(anchor, f"Nội dung bắt buộc trong ảnh: {detail}")
    placeholder = insert_before(anchor, "[DÁN ẢNH CHỤP MÀN HÌNH TẠI ĐÂY]")
    placeholder.alignment = WD_ALIGN_PARAGRAPH.CENTER
    for run in placeholder.runs:
        run.italic = True
        run.font.size = Pt(10)

insert_before(anchor, "Quy tắc chụp và trình bày: dùng cùng một kích thước ảnh, che mật khẩu/OTP/thông tin nhạy cảm, ghi rõ Chrome hay Android Emulator, ghi thời điểm chụp và mô tả ngắn ngay dưới ảnh. Với các luồng đồng bộ, nên đặt ảnh bệnh nhân và bác sĩ/admin cạnh nhau để chứng minh cùng một appointment_id, payment_id hoặc queue ticket.")

doc.save(str(OUTPUT))
print(OUTPUT)
