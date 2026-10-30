from pathlib import Path
from docx import Document
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor

SOURCE = Path(r"C:\Users\hoangvu\Documents\2324801030027_2324801030077_2324801030052_Nhom09_XayDungUngDungHoTroKhamBenhVaChamSocSucKhoeBangFlutter_bao_cao_da_kiem_tra.docx")
OUTPUT = SOURCE.with_name("2324801030027_2324801030077_2324801030052_Nhom09_XayDungUngDungHoTroKhamBenhVaChamSocSucKhoeBangFlutter_bao_cao_khop_project.docx")
doc = Document(str(SOURCE))

def font_run(run, size=9.0, bold=False, color=None):
    run.font.name = "Arial"
    rpr = run._element.get_or_add_rPr()
    rfonts = rpr.get_or_add_rFonts()
    for key in ("ascii", "hAnsi", "eastAsia"):
        rfonts.set(qn("w:" + key), "Arial")
    run.font.size = Pt(size)
    run.bold = bold
    if color:
        run.font.color.rgb = color

def rewrite_start(start, text, size=10):
    for p in doc.paragraphs:
        if p.text.strip().startswith(start):
            p.text = text
            for r in p.runs:
                font_run(r, size)
            p.paragraph_format.line_spacing = 1.08
            p.paragraph_format.space_after = Pt(6)
            return p
    return None

rewrite_start(
    "MedicalApiClient phía Flutter",
    "Backend dùng HttpServer từ dart:io để nhận request và trả JSON. MedicalApiClient phía Flutter gọi các nhóm API xác thực, bác sĩ, lịch hẹn, thanh toán, hàng đợi, bệnh án, đơn thuốc, tệp, thông báo, AI và tin tức. URL được truyền qua MEDCARE_API_BASE_URL; Chrome, Android Emulator và điện thoại thật dùng các địa chỉ backend khác nhau theo môi trường chạy.",
)
rewrite_start(
    "Trợ lý sức khỏe gọi /ai/chat",
    "Trợ lý sức khỏe gọi /ai/chat; backend ưu tiên Infermedica khi có INFERMEDICA_APP_ID/INFERMEDICA_APP_KEY hoặc Gemini khi có GEMINI_API_KEY/GOOGLE_API_KEY. Nếu chưa có khóa hoặc dịch vụ lỗi, ứng dụng dùng fallback và phải báo đây là nội dung tham khảo. Tin tức đọc RSS qua /news, có cache và dữ liệu dự phòng.",
)
rewrite_start(
    "Trong client hiện tại",
    "Trong client hiện tại, thao tác đặt lịch dùng bookOnlineFirst: khi backend và phiên đăng nhập sẵn sàng, MedicalStore gọi POST /appointments để server kiểm tra slot/capacity và tạo lịch; khi không kết nối được, app mới dùng luồng cục bộ để phát triển. Payment tiếp tục ở trạng thái chờ xác nhận cho đến khi admin duyệt hoặc webhook hợp lệ cập nhật.",
)
rewrite_start(
    "Quyền gọi số ở API",
    "Quyền gọi số ở API được giới hạn cho doctor/admin; bệnh nhân chỉ xem queue của lịch hợp lệ. Các route bệnh nhân, bác sĩ và admin đều được _RoleGate điều hướng ở client và kiểm tra lại bằng JWT/RBAC tại server.",
)

# Correct the patient table's booking row to match bookOnlineFirst and add the two patient routes that were missing.
table = next(t for t in doc.tables if t.rows and t.cell(0, 0).text.strip() == "STT")
for row in table.rows:
    if row.cells[0].text.strip() == "12":
        row.cells[3].text = "Backend nội bộ: bookOnlineFirst gọi POST /appointments, server kiểm tra slot/capacity; mất backend mới dùng luồng cục bộ."
    if row.cells[0].text.strip() == "13":
        row.cells[3].text = "Backend/client: xác nhận dữ liệu trước khi gửi lịch; trạng thái trả về phụ thuộc appointment và thanh toán."
    if row.cells[0].text.strip() == "14":
        row.cells[3].text = "Backend nội bộ: tải lịch theo tài khoản; dữ liệu giữa nhiều thiết bị dùng chung server."

def shade(cell, fill):
    tcpr = cell._tc.get_or_add_tcPr()
    shd = tcpr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tcpr.append(shd)
    shd.set(qn("w:fill"), fill)

def no_split(row):
    trpr = row._tr.get_or_add_trPr()
    trpr.append(OxmlElement("w:cantSplit"))

def add_row(values, number):
    cells = table.add_row().cells
    widths = [Inches(0.42), Inches(1.35), Inches(1.72), Inches(2.92)]
    for i, text in enumerate(values):
        cells[i].width = widths[i]
        cells[i].text = ""
        p = cells[i].paragraphs[0]
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(1)
        p.paragraph_format.line_spacing = 1.0
        p.paragraph_format.keep_together = True
        if i == 0:
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run(text)
        font_run(r, 7.9 if i == 3 else 8.2, i in (0, 1))
        shade(cells[i], "EAF2FB" if number % 2 == 0 else "FFFFFF")
        cells[i].vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.TOP
    no_split(table.rows[-1])

add_row(("39", "Khám từ xa", "kham_tu_xa_page.dart", "Có màn hình và trạng thái phiên tư vấn. Kết nối video thật/WebRTC chưa được tích hợp; không trình bày là cuộc gọi video production."), 39)
add_row(("40", "Cài đặt tài khoản", "man_hinh_bo_sung.dart", "Quản lý tùy chọn ứng dụng, bảo mật/phiên và thiết lập hiển thị trong client; không thay thế quản trị tài khoản ở backend."), 40)

# Make admin diagnostics explicit in the admin subsection instead of mixing it into patient functions.
for p in doc.paragraphs:
    if p.text.strip().startswith("Quản trị slot cho phép"):
        p.text = p.text + " Màn hình chan_doan_he_thong_page.dart kiểm tra trạng thái database/API ở vai trò admin; đây không phải chức năng bệnh nhân."
        for r in p.runs:
            font_run(r, 10)
        break

doc.save(str(OUTPUT))
print(OUTPUT)
