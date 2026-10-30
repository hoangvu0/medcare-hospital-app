from pathlib import Path
from docx import Document
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor

SOURCE = Path(r"C:\Users\hoangvu\Downloads\2324801030027_2324801030077_2324801030052_Nhom09_XayDungUngDungHoTroKhamBenhVaChamSocSucKhoeBangFlutter (1).docx")
OUTPUT = SOURCE.with_name("2324801030027_2324801030077_2324801030052_Nhom09_XayDungUngDungHoTroKhamBenhVaChamSocSucKhoeBangFlutter_bang_benh_nhan_chuan.docx")
doc = Document(str(SOURCE))

def set_font(run, size=8.7, bold=False, color=None):
    run.font.name = "Arial"
    rpr = run._element.get_or_add_rPr()
    rfonts = rpr.get_or_add_rFonts()
    for key in ("ascii", "hAnsi", "eastAsia"):
        rfonts.set(qn("w:" + key), "Arial")
    run.font.size = Pt(size)
    run.bold = bold
    if color:
        run.font.color.rgb = color

def shade(cell, fill):
    tcpr = cell._tc.get_or_add_tcPr()
    shd = tcpr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tcpr.append(shd)
    shd.set(qn("w:fill"), fill)

def cell_text(cell, text, size=8.7, bold=False, align=None):
    cell.text = ""
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(1)
    p.paragraph_format.line_spacing = 1.0
    if align is not None:
        p.alignment = align
    r = p.add_run(text)
    set_font(r, size, bold)
    cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.TOP

# Remove any previous generated patient-function table; all original report tables remain intact.
for old_table in list(doc.tables):
    if old_table.rows:
        header = " | ".join(c.text.strip() for c in old_table.rows[0].cells)
        generated_header = (
            old_table.cell(0, 0).text.strip() == "STT"
            or "Nhóm màn hình" in header
            or "Mức độ triển khai" in header
        )
        if generated_header:
            old_table._element.getparent().remove(old_table._element)

real_45 = [p for p in doc.paragraphs if p.text.strip().startswith("4.5.") and not p.style.name.lower().startswith("toc")][-1]
real_46 = [p for p in doc.paragraphs if p.text.strip().startswith("4.6. Kiểm") and not p.style.name.lower().startswith("toc")][-1]
real_45.text = "4.5. Các chức năng dành cho bệnh nhân"
for r in real_45.runs:
    set_font(r, 14, True)
real_45.paragraph_format.space_before = Pt(10)
real_45.paragraph_format.space_after = Pt(7)
real_45.paragraph_format.line_spacing = 1.0
real_45.paragraph_format.keep_with_next = True

pos = next(i for i, p in enumerate(doc.paragraphs) if p._p is real_45._p)
intro = doc.paragraphs[pos + 1]
intro.text = "Bảng tổng hợp toàn bộ các chức năng/màn hình người bệnh đang có trong mã nguồn project và luồng xử lý tương ứng."
for r in intro.runs:
    set_font(r, 10, False)
intro.paragraph_format.space_after = Pt(7)
intro.paragraph_format.line_spacing = 1.05

rows = [
    ("01", "Đăng nhập", "man_hinh_bo_sung.dart", "Nhập email/số điện thoại và mật khẩu; gọi /auth/login, nhận JWT/refresh token và vào giao diện bệnh nhân."),
    ("02", "Đăng ký tài khoản", "man_hinh_bo_sung.dart", "Nhập họ tên, điện thoại, email, mật khẩu; chọn kênh OTP và gửi request đăng ký."),
    ("03", "Xác thực Email/Gmail OTP", "man_hinh_bo_sung.dart; server/bin/server.dart", "Nhập OTP để verify-otp và tạo tài khoản. Gửi email cần cấu hình SMTP Gmail ở backend."),
    ("04", "Xác thực SMS OTP", "man_hinh_bo_sung.dart; server/bin/server.dart", "Chọn SMS OTP, gửi mã và xác nhận. Gửi SMS thật cần cấu hình Twilio."),
    ("05", "Quên mật khẩu", "man_hinh_bo_sung.dart", "Yêu cầu khôi phục và xác thực theo kênh OTP đã cấu hình; hiển thị lỗi nếu dịch vụ chưa sẵn sàng."),
    ("06", "Hồ sơ cá nhân", "man_hinh_bo_sung.dart", "Xem và chỉnh sửa họ tên, điện thoại, email, địa chỉ, ngày sinh, giới tính, BHYT và thông tin liên hệ."),
    ("07", "Hồ sơ gia đình", "ho_so_gia_dinh_page.dart", "Quản lý hồ sơ người thân để chọn đúng bệnh nhân khi đặt lịch hoặc theo dõi chăm sóc."),
    ("08", "Thông báo chuông", "man_hinh_bo_sung.dart; server/bin/server.dart", "Tải notification theo patient_id; nhận thông báo khi lịch, thanh toán, bệnh án, đơn thuốc hoặc lời dặn được cập nhật."),
    ("09", "Danh sách bác sĩ", "danh_sach_bac_si_page.dart", "Tìm/lọc bác sĩ theo tên, chuyên khoa, kinh nghiệm, đánh giá và mức phí."),
    ("10", "Chi tiết bác sĩ", "chi_tiet_bac_si_page.dart", "Xem hồ sơ, khoa, kinh nghiệm, phí tư vấn, lịch làm việc và các slot còn trống."),
    ("11", "Danh sách chuyên khoa", "man_hinh_bo_sung.dart; man_hinh_don_gian.dart", "Chọn chuyên khoa để xem mô tả, dịch vụ và danh sách bác sĩ thuộc khoa."),
    ("12", "Đặt lịch khám", "dat_lich_kham_page.dart; man_hinh_bo_sung.dart", "Chọn bác sĩ, ngày, slot, lý do khám và gói; server kiểm tra công suất rồi tạo appointment."),
    ("13", "Xác nhận lịch hẹn", "man_hinh_bo_sung.dart", "Kiểm tra lại bác sĩ, thời gian, chi phí, gói khám và xác nhận gửi lịch."),
    ("14", "Lịch hẹn của tôi", "man_hinh_bo_sung.dart", "Xem lịch sắp tới/lịch sử và trạng thái chờ thanh toán, chờ duyệt, đã xác nhận, đã khám hoặc đã hủy."),
    ("15", "Chi tiết lịch hẹn", "man_hinh_bo_sung.dart", "Xem mã lịch, bác sĩ, phòng, chi phí; thanh toán, đổi ngày, hủy lịch, tạo check-in, nhận số và mở bệnh án."),
    ("16", "Đổi hoặc hủy lịch", "man_hinh_bo_sung.dart", "Gửi lý do đổi/hủy lên backend; server cập nhật trạng thái và tạo thông báo cho các bên liên quan."),
    ("17", "Thanh toán viện phí", "thanh_toan_vien_phi_page.dart", "Xem khoản phải trả, chọn phương thức, tạo giao dịch và chuyển sang QR hoặc chờ admin xác nhận."),
    ("18", "Ví bệnh nhân/nạp ví", "nap_vi_page.dart", "Tạo yêu cầu nạp tiền, xem số dư và lịch sử giao dịch; giao dịch chưa có webhook vẫn chờ duyệt thủ công."),
    ("19", "QR thanh toán", "thanh_toan_vien_phi_page.dart", "Hiển thị mã giao dịch, đúng số tiền và thông tin tài khoản nhận theo cấu hình VietQR; không tự báo thành công khi chưa xác minh."),
    ("20", "Gói khám tầm soát", "goi_kham_suc_khoe_page.dart", "Xem gói, danh sách hạng mục, chi phí và gửi yêu cầu đăng ký để tạo hồ sơ xử lý."),
    ("21", "Tiêm chủng", "tiem_chung_page.dart", "Xem nội dung tiêm, lịch/đối tượng và gửi yêu cầu đăng ký; admin tiếp nhận trong backend hiện có."),
    ("22", "Bảo lãnh viện phí", "bao_lanh_vien_phi_page.dart", "Tạo và theo dõi yêu cầu bảo lãnh; kết nối công ty bảo hiểm thật cần API riêng."),
    ("23", "Thẻ y tế điện tử/BHYT", "the_y_te_dien_tu_page.dart", "Hiển thị thông tin thẻ đã lưu, trạng thái và dữ liệu được che bớt; xác minh BHYT thật cần dịch vụ ngoài."),
    ("24", "Hàng đợi khám", "hang_doi_kham_page.dart", "Xem số của mình, số đang gọi, phòng và thời gian chờ; đồng bộ qua queue_state/SSE khi dùng chung server."),
    ("25", "QR check-in", "man_hinh_bo_sung.dart", "Tạo mã check-in cho lịch đã đủ điều kiện để bệnh viện/bác sĩ đối chiếu đúng appointment."),
    ("26", "Bệnh án điện tử", "ho_so_benh_an_page.dart", "Xem lịch sử khám, chẩn đoán, sinh hiệu, xét nghiệm, hình ảnh, đơn thuốc và lời dặn đã được bác sĩ gửi."),
    ("27", "Kết quả xét nghiệm", "giai_thich_xet_nghiem_page.dart; man_hinh_bo_sung.dart", "Xem danh sách kết quả, chi tiết chỉ số và nội dung giải thích; dữ liệu chính thức phải đến từ hồ sơ đã đồng bộ."),
    ("28", "Đơn thuốc điện tử", "don_thuoc_dien_tu_page.dart", "Xem tên thuốc, liều, số lần dùng, số ngày, hướng dẫn và cảnh báo do bác sĩ gửi."),
    ("29", "Theo dõi sinh hiệu", "theo_doi_sinh_hieu_page.dart", "Theo dõi huyết áp, nhịp tim, SpO2, nhiệt độ và cân nặng theo lần khám hoặc dữ liệu được cập nhật."),
    ("30", "Nhắc lịch uống thuốc", "nhac_lich_uong_thuoc_page.dart", "Tạo/xem lịch nhắc thuốc và nhận thông báo cục bộ trên thiết bị."),
    ("31", "Tiến độ khám", "tien_do_kham_page.dart", "Theo dõi các bước tiếp nhận, sinh hiệu, khám, cận lâm sàng, đơn thuốc và hoàn tất hồ sơ."),
    ("32", "Trợ lý sức khỏe AI", "tro_ly_suc_khoe_ai_page.dart", "Gửi câu hỏi đến /ai/chat; dùng Infermedica/Gemini khi đã cấu hình, nếu không có thì hiển thị fallback tham khảo."),
    ("33", "Tin tức sức khỏe", "tin_tuc_suc_khoe_page.dart", "Đọc tin từ /news theo RSS/cache/fallback; nội dung chỉ tham khảo, không thay tư vấn y tế."),
    ("34", "Sức khỏe tinh thần", "suc_khoe_tinh_than_page.dart", "Xem nội dung hỗ trợ tinh thần và hướng dẫn tự chăm sóc trong app."),
    ("35", "Bản đồ bệnh viện", "ban_do_benh_vien_page.dart", "Xem sơ đồ/khu vực bệnh viện; chỉ đường trực tuyến cần API bản đồ nếu triển khai production."),
    ("36", "Cấp cứu/hỗ trợ", "sos_cap_cuu_page.dart", "Hiển thị thao tác gọi hỗ trợ/cấp cứu và số liên hệ; điều xe cấp cứu thật cần API điều phối."),
    ("37", "Hỗ trợ và liên hệ", "man_hinh_bo_sung.dart", "Gửi yêu cầu hỗ trợ, xem phản hồi và liên hệ tổng đài theo backend support requests/messages."),
    ("38", "Đánh giá bác sĩ", "man_hinh_bo_sung.dart", "Bệnh nhân gửi đánh giá sau buổi khám; nội dung được ghi nhận theo lịch hẹn."),
]

table = doc.add_table(rows=1, cols=4)
table.style = "Table Grid"
table.autofit = False
widths = [Inches(0.42), Inches(1.42), Inches(1.82), Inches(3.15)]
headers = ["STT", "Chức năng bệnh nhân", "Màn hình / mã nguồn", "Luồng xử lý trong project"]
for i, header in enumerate(headers):
    c = table.rows[0].cells[i]
    c.width = widths[i]
    shade(c, "0B3B78")
    cell_text(c, header, 8.7, True, WD_ALIGN_PARAGRAPH.CENTER)
    for r in c.paragraphs[0].runs:
        r.font.color.rgb = RGBColor(255, 255, 255)

for row in rows:
    cells = table.add_row().cells
    for i, value in enumerate(row):
        cells[i].width = widths[i]
        cell_text(cells[i], value, 8.2 if i == 3 else 8.4, i == 0 or i == 1, WD_ALIGN_PARAGRAPH.CENTER if i == 0 else None)

real_46._p.addprevious(table._tbl)
doc.save(str(OUTPUT))
print(OUTPUT)
