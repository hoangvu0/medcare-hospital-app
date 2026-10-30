from pathlib import Path
from docx import Document
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt

SOURCE = Path(r"C:\Users\hoangvu\Downloads\2324801030027_2324801030077_2324801030052_Nhom09_XayDungUngDungHoTroKhamBenhVaChamSocSucKhoeBangFlutter_cap_nhat_muc_4_5_chi_tiet_dung.docx")
OUTPUT = SOURCE.with_name(SOURCE.stem + "_gom_1_bang" + SOURCE.suffix)
doc = Document(str(SOURCE))

def set_font(run, size=9.2, bold=False, color=None):
    run.font.name = "Arial"
    rpr = run._element.get_or_add_rPr()
    rfonts = rpr.get_or_add_rFonts()
    for key in ("ascii", "hAnsi", "eastAsia"):
        rfonts.set(qn("w:" + key), "Arial")
    run.font.size = Pt(size)
    run.bold = bold
    if color:
        run.font.color.rgb = color

def clear_cell(cell):
    cell.text = ""
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(0)
    p.paragraph_format.line_spacing = 1.0
    return p

def shade(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)

# Use the real chapter heading, not the table-of-contents entry.
real_45 = [p for p in doc.paragraphs if p.text.strip().startswith("4.5.")][-1]
real_46 = [p for p in doc.paragraphs if p.text.strip().startswith("4.6. Kiểm")][-1]
real_45.text = "4.5. Các màn hình và tiện ích mở rộng có trong project"
for r in real_45.runs:
    set_font(r, 14, True)
real_45.paragraph_format.space_before = Pt(10)
real_45.paragraph_format.space_after = Pt(7)
real_45.paragraph_format.line_spacing = 1.0
real_45.paragraph_format.keep_with_next = True

# Keep one short introduction, then one table only.
pos = next(i for i, p in enumerate(doc.paragraphs) if p._p is real_45._p)
intro = doc.paragraphs[pos + 1]
intro.text = "Bảng dưới đây tổng hợp các màn hình và tiện ích đang có trong mã nguồn project; các dịch vụ ngoài chưa cấu hình được ghi rõ trong cột luồng xử lý."
for r in intro.runs:
    set_font(r, 10, False)
intro.paragraph_format.space_after = Pt(7)
intro.paragraph_format.line_spacing = 1.05

# Remove the previously inserted 4.5.1–4.5.11 paragraphs.
for p in list(doc.paragraphs):
    if p.text.strip().startswith(tuple(f"4.5.{i}." for i in range(1, 12))):
        p._element.getparent().remove(p._element)

rows = [
    ("Tài khoản, hồ sơ, thông báo", "man_hinh_bo_sung.dart; local_notification_service.dart", "Đăng nhập/đăng ký, Email/Gmail OTP hoặc SMS OTP, quên mật khẩu, xác thực OTP, hồ sơ cá nhân, hồ sơ gia đình và chuông notification theo patient_id."),
    ("Bác sĩ và đặt lịch", "danh_sach_bac_si_page.dart; chi_tiet_bac_si_page.dart; dat_lich_kham_page.dart", "Tìm theo tên/chuyên khoa, xem phí/kinh nghiệm/slot, chọn ngày–giờ–lý do–gói và tạo lịch trên backend khi có kết nối."),
    ("Lịch hẹn và số thứ tự", "hang_doi_kham_page.dart; tien_do_kham_page.dart", "Xem trạng thái lịch, đổi/hủy, tạo QR check-in, nhận số, phòng và thời gian chờ. queue_state và SSE giúp các thiết bị cùng thấy dữ liệu khi dùng chung server."),
    ("Thanh toán, ví và duyệt tay", "thanh_toan_vien_phi_page.dart; nap_vi_page.dart; admin_approval_page.dart", "Hiển thị viện phí, lịch sử, ví và QR. Khi chưa có webhook ngân hàng, bệnh nhân gửi yêu cầu và admin duyệt/từ chối; QR không tự chứng minh giao dịch ngân hàng."),
    ("Bệnh án, đơn thuốc, sinh hiệu", "ho_so_benh_an_page.dart; don_thuoc_dien_tu_page.dart; theo_doi_sinh_hieu_page.dart", "Xem lịch sử khám, chẩn đoán, vitals, xét nghiệm, hình ảnh, thuốc, liều, hướng dẫn và lời dặn. Chỉ dữ liệu bác sĩ đã gửi qua clinical actions/medical records là kết quả chính thức."),
    ("Gói khám, tiêm chủng, BHYT", "goi_kham_suc_khoe_page.dart; tiem_chung_page.dart; bao_lanh_vien_phi_page.dart; the_y_te_dien_tu_page.dart", "Hiển thị gói tầm soát, nội dung tiêm, yêu cầu bảo lãnh và thẻ y tế. Yêu cầu được ghi nhận cho admin xử lý; bảo hiểm/BHYT thật vẫn cần API đơn vị cung cấp."),
    ("AI, xét nghiệm, tin tức", "tro_ly_suc_khoe_ai_page.dart; giai_thich_xet_nghiem_page.dart; tin_tuc_suc_khoe_page.dart", "AI gọi /ai/chat với Infermedica/Gemini nếu có khóa, nếu không có thì fallback; xét nghiệm hiển thị/giải thích; tin tức lấy /news từ RSS/cache/fallback. Chỉ tham khảo, không thay chẩn đoán."),
    ("Nhắc thuốc và tiện ích bệnh viện", "nhac_lich_uong_thuoc_page.dart; suc_khoe_tinh_than_page.dart; ban_do_benh_vien_page.dart; sos_cap_cuu_page.dart", "Nhắc uống thuốc, sức khỏe tinh thần, sơ đồ bệnh viện, hỗ trợ/cấp cứu và tiến độ khám. Thông báo cục bộ có sẵn; gọi xe, chỉ đường và tổng đài thật cần dịch vụ ngoài."),
    ("Workstation bác sĩ", "ban_lam_viec_bac_si_page.dart", "Tiếp nhận/gọi số, sinh hiệu, ICD-10, cận lâm sàng/hình ảnh, kê đơn, ký/gửi EMR, hội chẩn, tái khám, ra y lệnh, lời dặn và upload file; server lưu clinical_actions/records/prescriptions/files và báo chuông bệnh nhân."),
    ("Portal admin", "admin_control_page.dart; quan_tri_slot_kham_page.dart; chan_doan_he_thong_page.dart", "Quản lý tài khoản, bác sĩ, lịch/slot/capacity, doanh thu/KPI, audit, hỗ trợ, duyệt thanh toán/bảo lãnh và kiểm tra hệ thống. Đây là nơi xử lý thủ công khi thiếu cổng thanh toán."),
    ("Dữ liệu và giới hạn tích hợp", "MedicalStore; MedicalApiClient; SQLite client/server; server/bin/server.dart", "Dữ liệu chia sẻ phải ghi ở SQLite server qua API. Đã có endpoint nội bộ cho auth, bác sĩ, lịch, thanh toán, queue, bệnh án, đơn, file, notification, AI, news và admin. SMTP/Twilio, webhook ngân hàng, FCM, video, PKI, HIS/LIS/PACS, bảo hiểm và đơn thuốc quốc gia cần cấu hình riêng."),
]

table = doc.add_table(rows=1, cols=3)
table.style = "Table Grid"
table.autofit = False
table.columns[0].width = Inches(1.35)
table.columns[1].width = Inches(2.25)
table.columns[2].width = Inches(3.25)
headers = ["Nhóm chức năng", "Màn hình / mã nguồn", "Luồng xử lý hiện có"]
for i, text in enumerate(headers):
    cell = table.rows[0].cells[i]
    cell.width = table.columns[i].width
    shade(cell, "0B3B78")
    p = clear_cell(cell)
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run(text)
    set_font(r, 9.2, True)
    r.font.color.rgb = __import__('docx').shared.RGBColor(255, 255, 255)
    cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER

for row_data in rows:
    cells = table.add_row().cells
    for i, text in enumerate(row_data):
        cells[i].width = table.columns[i].width
        p = clear_cell(cells[i])
        r = p.add_run(text)
        set_font(r, 8.8, i == 0)
        cells[i].vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.TOP

# Move the table immediately before Chapter 4.6.
real_46._p.addprevious(table._tbl)

doc.save(str(OUTPUT))
print(OUTPUT)
