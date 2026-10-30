from pathlib import Path
from docx import Document
from docx.oxml.ns import qn
from docx.shared import Pt

SOURCE = Path(r"C:\Users\hoangvu\Downloads\2324801030027_2324801030077_2324801030052_Nhom09_XayDungUngDungHoTroKhamBenhVaChamSocSucKhoeBangFlutter_cap_nhat.docx")
OUTPUT = SOURCE.with_name(SOURCE.stem + "_muc_4_5_chi_tiet_dung" + SOURCE.suffix)
doc = Document(str(SOURCE))

def set_font(run, size=10.2, bold=None):
    run.font.name = "Arial"
    rpr = run._element.get_or_add_rPr()
    rfonts = rpr.get_or_add_rFonts()
    for key in ("ascii", "hAnsi", "eastAsia"):
        rfonts.set(qn("w:" + key), "Arial")
    run.font.size = Pt(size)
    if bold is not None:
        run.bold = bold

def style(p, size=10.2, before=2, after=5):
    pf = p.paragraph_format
    pf.space_before = Pt(before)
    pf.space_after = Pt(after)
    pf.line_spacing = 1.08
    pf.keep_together = True
    for r in p.runs:
        set_font(r, size)

# The document has a table of contents and the real chapter heading. Use the last one.
chapter_headings = [p for p in doc.paragraphs if p.text.strip().startswith("4.5.")]
chapter_heading = chapter_headings[-1]
chapter46 = [p for p in doc.paragraphs if p.text.strip().startswith("4.6. Kiểm")][-1]

chapter_heading.text = "4.5. Các màn hình và tiện ích mở rộng có trong project"
style(chapter_heading, 14, 10, 7)
for r in chapter_heading.runs:
    set_font(r, 14, True)
chapter_heading.paragraph_format.keep_with_next = True

# The first paragraph after the real heading is the existing 4.5 introduction.
pos = next(i for i, p in enumerate(doc.paragraphs) if p._p is chapter_heading._p)
intro = doc.paragraphs[pos + 1]
intro.text = (
    "Project hiện có các màn hình mở rộng dưới đây. Nội dung được đối chiếu với thư mục lib/pages, "
    "app routes và API backend; phần nào cần dịch vụ bên ngoài được ghi rõ để tránh nhầm là chức năng đã tích hợp production."
)
style(intro, 10.5, 0, 8)

details = [
    ("4.5.1. Tài khoản, hồ sơ và thông báo", "man_hinh_bo_sung.dart có đăng nhập, đăng ký, Email/Gmail OTP hoặc SMS OTP, quên mật khẩu, xác thực OTP, kiểm tra lỗi API và điều hướng theo vai trò. Người bệnh có Hồ sơ cá nhân, chỉnh sửa thông tin, che số điện thoại/BHYT, Hồ sơ gia đình và màn hình Thông báo. Chuông đọc notification theo patient_id; thông báo có thể mở chi tiết nội dung bác sĩ gửi."),
    ("4.5.2. Tìm bác sĩ, chuyên khoa và đặt lịch", "danh_sach_bac_si_page.dart, chi_tiet_bac_si_page.dart và man_hinh_bo_sung.dart cho phép tìm theo tên/chuyên khoa, xem kinh nghiệm, đánh giá, phí và lịch trống. Người bệnh chọn ngày, slot, lý do và gói; dat_lich_kham_page.dart xử lý xác nhận. Có backend thì lịch được ghi trên server; không có backend thì chỉ là luồng cục bộ trên thiết bị."),
    ("4.5.3. Lịch hẹn, đổi/hủy lịch và số thứ tự", "App có danh sách/chi tiết lịch, trạng thái chờ thanh toán – đã xác nhận – đã hủy, đổi ngày, hủy lịch, tạo mã check-in, nhận số, xem bệnh án của đợt khám và đánh giá bác sĩ. hang_doi_kham_page.dart hiển thị số đang gọi, số bệnh nhân, phòng và thời gian dự kiến. queue_state và SSE /queue/events giúp các thiết bị cùng thấy một trạng thái khi dùng chung server."),
    ("4.5.4. Thanh toán viện phí và duyệt thủ công", "thanh_toan_vien_phi_page.dart và nap_vi_page.dart hiển thị chi tiết viện phí, lịch sử giao dịch, ví, số tiền và QR. Khi chưa có webhook ngân hàng, bệnh nhân gửi yêu cầu xác nhận; admin dùng admin_approval_page.dart để duyệt hoặc từ chối thủ công. Chỉ giao dịch được backend xác nhận mới mở bước tiếp theo, tạo QR check-in hoặc cấp số; QR không tự chứng minh tiền đã vào ngân hàng."),
    ("4.5.5. Bệnh án, đơn thuốc và kết quả khám", "ho_so_benh_an_page.dart hiển thị lịch sử khám, chẩn đoán, sinh hiệu, xét nghiệm, hình ảnh, đơn thuốc và lời dặn theo appointment. don_thuoc_dien_tu_page.dart hiển thị thuốc, liều, số ngày và hướng dẫn. theo_doi_sinh_hieu_page.dart theo dõi huyết áp, nhịp tim, SpO2, nhiệt độ và cân nặng. Chỉ dữ liệu bác sĩ đã gửi qua clinical actions/medical records mới hiển thị là kết quả chính thức."),
    ("4.5.6. Gói khám, tiêm chủng và bảo lãnh", "goi_kham_suc_khoe_page.dart trình bày gói tầm soát; tiem_chung_page.dart xử lý nội dung đăng ký tiêm; bao_lanh_vien_phi_page.dart hiển thị yêu cầu bảo lãnh; the_y_te_dien_tu_page.dart hiển thị thẻ y tế điện tử. Các yêu cầu được ghi nhận để admin xử lý trong backend hiện có. Kết nối công ty bảo hiểm/BHYT thật vẫn cần API đơn vị cung cấp."),
    ("4.5.7. AI, xét nghiệm và tin tức sức khỏe", "tro_ly_suc_khoe_ai_page.dart gọi /ai/chat, ưu tiên Infermedica hoặc Gemini nếu có khóa; nếu chưa có thì backend trả fallback và phải thể hiện trạng thái chưa cấu hình. giai_thich_xet_nghiem_page.dart hỗ trợ xem/giải thích thông tin xét nghiệm. tin_tuc_suc_khoe_page.dart lấy tin qua /news từ RSS, cache hoặc fallback. Đây là nội dung tham khảo, không thay chẩn đoán bác sĩ."),
    ("4.5.8. Nhắc thuốc, sức khỏe và tiện ích bệnh viện", "nhac_lich_uong_thuoc_page.dart quản lý lịch nhắc thuốc; suc_khoe_tinh_than_page.dart hỗ trợ sức khỏe tinh thần; ban_do_benh_vien_page.dart hiển thị sơ đồ; sos_cap_cuu_page.dart hiển thị gọi hỗ trợ/cấp cứu; tien_do_kham_page.dart theo dõi tiến độ. local_notification_service.dart hỗ trợ thông báo cục bộ. Gọi xe, chỉ đường và tổng đài thật cần dịch vụ ngoài."),
    ("4.5.9. Workstation bác sĩ", "ban_lam_viec_bac_si_page.dart tổ chức tiếp nhận/gọi số, sinh hiệu, khám và ICD-10, cận lâm sàng/hình ảnh, kê đơn, ký/gửi EMR, theo khoa, hội chẩn, tái khám, ra y lệnh và gửi lời dặn. Bác sĩ có thể cập nhật file y tế theo API. Mỗi thao tác gắn đúng appointment; server lưu clinical_actions, medical_records, prescriptions/files và tạo notification cho bệnh nhân."),
    ("4.5.10. Portal admin", "admin_control_page.dart điều hành tài khoản, lịch hẹn, bác sĩ, doanh thu/KPI, audit, hỗ trợ và danh sách bác sĩ. admin_approval_page.dart duyệt thanh toán/bảo lãnh; quan_tri_slot_kham_page.dart quản lý phòng, slot, capacity, booked và số còn lại; chan_doan_he_thong_page.dart kiểm tra trạng thái hệ thống. Admin là nơi xử lý thủ công khi chưa có cổng thanh toán hoặc dịch vụ ngoài."),
    ("4.5.11. Dữ liệu và giới hạn", "Các màn hình dùng MedicalStore/MedicalApiClient và database client; dữ liệu cần chia sẻ giữa bệnh nhân, bác sĩ và admin phải ghi ở SQLite server qua API. Project đã có endpoint nội bộ cho auth, bác sĩ, lịch, thanh toán, queue, bệnh án, đơn thuốc, file, notification, AI, news và admin. SMTP/Twilio, webhook ngân hàng, FCM, video, PKI, HIS/LIS/PACS, bảo hiểm và đơn thuốc quốc gia vẫn cần cấu hình/tích hợp riêng."),
]

for title, text in details:
    p = chapter46.insert_paragraph_before()
    p.text = title + "\n" + text
    style(p)
    if p.runs:
        set_font(p.runs[0], 10.5, True)

doc.save(str(OUTPUT))
print(OUTPUT)
