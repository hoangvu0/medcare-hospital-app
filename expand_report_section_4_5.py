from pathlib import Path
from docx import Document
from docx.oxml.ns import qn
from docx.shared import Pt

SOURCE = Path(r"C:\Users\hoangvu\Downloads\2324801030027_2324801030077_2324801030052_Nhom09_XayDungUngDungHoTroKhamBenhVaChamSocSucKhoeBangFlutter_cap_nhat_muc_4_5_dep.docx")
OUTPUT = SOURCE.with_name(SOURCE.stem + "_chi_tiet_project" + SOURCE.suffix)

doc = Document(str(SOURCE))

def font_run(run, size=10.5, bold=None):
    run.font.name = "Arial"
    run._element.get_or_add_rPr().get_or_add_rFonts().set(qn("w:ascii"), "Arial")
    run._element.get_or_add_rPr().get_or_add_rFonts().set(qn("w:hAnsi"), "Arial")
    run._element.get_or_add_rPr().get_or_add_rFonts().set(qn("w:eastAsia"), "Arial")
    run.font.size = Pt(size)
    if bold is not None:
        run.bold = bold

def style_body(p, size=10.5, before=2, after=5):
    p.paragraph_format.space_before = Pt(before)
    p.paragraph_format.space_after = Pt(after)
    p.paragraph_format.line_spacing = 1.08
    p.paragraph_format.keep_together = True
    for r in p.runs:
        font_run(r, size)

heading = next(p for p in doc.paragraphs if p.text.strip().startswith("4.5."))
body = next(p for p in doc.paragraphs if p.text.strip().startswith("Các màn hình mở rộng"))
next_heading = next(p for p in doc.paragraphs if p.text.strip().startswith("4.6. Kiểm"))

heading.text = "4.5. Các màn hình và tiện ích mở rộng có trong project"
for r in heading.runs:
    font_run(r, 14, True)
heading.paragraph_format.space_before = Pt(10)
heading.paragraph_format.space_after = Pt(7)
heading.paragraph_format.line_spacing = 1.0
heading.paragraph_format.keep_with_next = True

body.text = (
    "Ngoài các màn hình đăng nhập, trang chủ, bác sĩ, lịch hẹn, bệnh án và quản trị đã trình bày ở các mục trước, "
    "project hiện có các màn hình mở rộng dưới đây. Tên file được ghi kèm để đối chiếu trực tiếp với mã nguồn. "
    "Mục này phân biệt rõ chức năng đã có trong app/backend với phần còn phụ thuộc dịch vụ bên ngoài."
)
style_body(body, 10.5, 0, 8)

details = [
    ("4.5.1. Tài khoản, hồ sơ và thông báo",
     "man_hinh_bo_sung.dart có đăng nhập, đăng ký, chọn Email/Gmail OTP hoặc SMS OTP, quên mật khẩu, xác thực OTP, kiểm tra lỗi API và điều hướng theo vai trò. Người bệnh có Hồ sơ cá nhân, chỉnh sửa thông tin, che số điện thoại/BHYT, Hồ sơ gia đình và màn hình Thông báo. Chuông lấy notification theo patient_id từ backend; thông báo có thể mở chi tiết và hiển thị nội dung bác sĩ gửi."),
    ("4.5.2. Tìm bác sĩ, chuyên khoa và đặt lịch",
     "danh_sach_bac_si_page.dart, chi_tiet_bac_si_page.dart và man_hinh_bo_sung.dart cho phép tìm theo tên/chuyên khoa, xem kinh nghiệm, đánh giá, phí và lịch trống, sau đó chọn ngày, slot, lý do khám và gói. dat_lich_kham_page.dart xử lý bước xác nhận. Khi backend hoạt động, lịch được tạo trên server; khi không có backend, app chỉ dùng luồng cục bộ và không đồng bộ sang thiết bị khác."),
    ("4.5.3. Lịch hẹn, đổi/hủy lịch và số thứ tự",
     "App có danh sách lịch hẹn, chi tiết lịch, trạng thái chờ thanh toán/đã xác nhận/đã hủy, đổi ngày, hủy lịch, tạo mã check-in, nhận số thứ tự, xem bệnh án của đợt khám và đánh giá bác sĩ. hang_doi_kham_page.dart hiển thị số đang gọi, số của bệnh nhân, phòng và thời gian dự kiến. Backend queue_state và SSE /queue/events giúp Chrome, Android Emulator và điện thoại cùng thấy một trạng thái khi dùng chung server."),
    ("4.5.4. Thanh toán viện phí và duyệt thủ công",
     "thanh_toan_vien_phi_page.dart và nap_vi_page.dart hiển thị chi tiết viện phí, lịch sử giao dịch, ví, số tiền và QR theo giao dịch. Khi chưa cấu hình webhook ngân hàng, giao dịch vẫn ở trạng thái chờ xác nhận; bệnh nhân gửi yêu cầu, admin vào admin_approval_page.dart để duyệt hoặc từ chối thủ công. Chỉ sau khi backend cập nhật thành công mới chuyển lịch sang bước xác nhận, cấp QR check-in hoặc số theo chính sách. QR không được xem là giao dịch ngân hàng tự động nếu chưa có webhook."),
    ("4.5.5. Bệnh án, đơn thuốc và kết quả khám",
     "ho_so_benh_an_page.dart hiển thị lịch sử khám, chẩn đoán, sinh hiệu, xét nghiệm, hình ảnh, đơn thuốc và lời dặn theo appointment. don_thuoc_dien_tu_page.dart hiển thị thuốc, liều, số ngày và hướng dẫn. theo_doi_sinh_hieu_page.dart dành cho dữ liệu huyết áp, nhịp tim, SpO2, nhiệt độ và cân nặng. Các kết quả do bác sĩ gửi qua clinical actions/medical records mới xuất hiện ở bệnh nhân; dữ liệu nháp không được coi là kết quả cuối."),
    ("4.5.6. Gói khám, tiêm chủng và bảo lãnh",
     "goi_kham_suc_khoe_page.dart trình bày các gói tầm soát và thông tin gói; tiem_chung_page.dart quản lý nội dung đăng ký tiêm; bao_lanh_vien_phi_page.dart hiển thị luồng yêu cầu bảo lãnh; the_y_te_dien_tu_page.dart hiển thị thẻ y tế điện tử. Các đăng ký được ghi nhận để admin xử lý trong phạm vi backend hiện có. Kết nối công ty bảo hiểm/BHYT thật vẫn cần API của đơn vị cung cấp."),
    ("4.5.7. AI, xét nghiệm và nội dung sức khỏe",
     "tro_ly_suc_khoe_ai_page.dart gọi route /ai/chat; backend ưu tiên Infermedica hoặc Gemini nếu có biến môi trường, nếu chưa có thì trả fallback và phải báo trạng thái chưa cấu hình. giai_thich_xet_nghiem_page.dart hỗ trợ xem/giải thích thông tin xét nghiệm trong app. tin_tuc_suc_khoe_page.dart lấy tin qua /news từ RSS/cache/fallback. Các nội dung này chỉ hỗ trợ tham khảo, không thay thế chẩn đoán của bác sĩ."),
    ("4.5.8. Nhắc thuốc, sức khỏe và tiện ích bệnh viện",
     "nhac_lich_uong_thuoc_page.dart quản lý lịch nhắc thuốc; suc_khoe_tinh_than_page.dart cung cấp màn hình hỗ trợ sức khỏe tinh thần; ban_do_benh_vien_page.dart hiển thị sơ đồ bệnh viện; sos_cap_cuu_page.dart hiển thị lối gọi hỗ trợ/cấp cứu; tien_do_kham_page.dart theo dõi tiến độ ca khám. local_notification_service.dart hỗ trợ thông báo cục bộ trên thiết bị. Gọi xe cấp cứu, bản đồ dẫn đường hoặc tổng đài thật cần cấu hình dịch vụ ngoài."),
    ("4.5.9. Workstation bác sĩ",
     "ban_lam_viec_bac_si_page.dart tổ chức ca khám theo các bước: tiếp nhận và gọi số, nhập sinh hiệu, khám/ICD-10, cận lâm sàng và hình ảnh, kê đơn, ký/gửi EMR, theo khoa, hội chẩn, đặt tái khám, ra y lệnh và gửi lời dặn. Bác sĩ có thể cập nhật file y tế theo API hiện có. Mỗi thao tác phải gắn đúng appointment; server lưu clinical_actions, medical_records, prescriptions/files và tạo notification cho bệnh nhân."),
    ("4.5.10. Portal admin",
     "admin_control_page.dart là màn hình điều hành tài khoản, lịch hẹn, bác sĩ, doanh thu/KPI, audit, hỗ trợ, điều hành và danh sách bác sĩ. admin_approval_page.dart duyệt thanh toán/bảo lãnh; quan_tri_slot_kham_page.dart quản lý phòng, slot, capacity, booked và số còn lại; chan_doan_he_thong_page.dart hỗ trợ kiểm tra trạng thái hệ thống. Admin là vai trò kiểm soát nghiệp vụ khi chưa có cổng thanh toán hoặc dịch vụ ngoài."),
    ("4.5.11. Dữ liệu và giới hạn của các tiện ích",
     "Các màn hình dùng MedicalStore/MedicalApiClient và database client để hiển thị nhanh; dữ liệu cần chia sẻ giữa bệnh nhân, bác sĩ và admin phải ghi ở SQLite server qua API. Project đã có endpoint nội bộ cho auth, bác sĩ, lịch, thanh toán, queue, bệnh án, đơn thuốc, file, notification, AI, news và admin. Chưa thể gọi là tích hợp production nếu thiếu SMTP/Twilio, webhook ngân hàng, FCM, video, PKI, HIS/LIS/PACS, bảo hiểm hoặc đơn thuốc quốc gia."),
]

# Insert in reverse so the displayed order remains the same before Chapter 4.6.
for title, text in reversed(details):
    p = next_heading.insert_paragraph_before()
    p.text = title + "\n" + text
    style_body(p, 10.2, 2, 5)
    if p.runs:
        p.runs[0].bold = True
        p.runs[0].font.size = Pt(10.5)
        font_run(p.runs[0], 10.5, True)

doc.save(str(OUTPUT))
print(OUTPUT)
