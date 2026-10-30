from pathlib import Path
from docx import Document
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor

SOURCE = Path(r"C:\Users\hoangvu\Documents\2324801030027_2324801030077_2324801030052_Nhom09_XayDungUngDungHoTroKhamBenhVaChamSocSucKhoeBangFlutter_bang_benh_nhan_chuan.docx")
OUTPUT = SOURCE.with_name("2324801030027_2324801030077_2324801030052_Nhom09_XayDungUngDungHoTroKhamBenhVaChamSocSucKhoeBangFlutter_bao_cao_da_kiem_tra.docx")
doc = Document(str(SOURCE))

BLUE = "0B3B78"
LIGHT_BLUE = "EAF2FB"

def set_font(run, size=8.4, bold=False, color=None):
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

def set_cell_text(cell, text, size=8.4, bold=False, align=None):
    cell.text = ""
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(1)
    p.paragraph_format.line_spacing = 1.0
    p.paragraph_format.keep_together = True
    if align is not None:
        p.alignment = align
    r = p.add_run(text)
    set_font(r, size, bold)
    cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.TOP

def no_row_split(row):
    trpr = row._tr.get_or_add_trPr()
    cant = OxmlElement("w:cantSplit")
    trpr.append(cant)

def repeat_header(row):
    trpr = row._tr.get_or_add_trPr()
    tbl_header = OxmlElement("w:tblHeader")
    tbl_header.set(qn("w:val"), "true")
    trpr.append(tbl_header)

paragraphs = doc.paragraphs
real_45 = [p for p in paragraphs if p.text.strip().startswith("4.5.") and p.style.name.lower() == "2"][-1]
real_46 = [p for p in paragraphs if p.text.strip().startswith("4.6. Kiểm") and p.style.name.lower() == "2"][-1]

# Keep the TOC label and chapter label consistent, without creating subheadings.
for p in paragraphs:
    if p.text.strip().startswith("4.5."):
        p.text = "4.5. Các chức năng dành cho bệnh nhân" + ("\t24" if p.style.name.lower().startswith("toc") else "")
        for r in p.runs:
            set_font(r, 11 if p.style.name.lower() == "2" else 10, p.style.name.lower() == "2")

pos = next(i for i, p in enumerate(paragraphs) if p._p is real_45._p)
intro = paragraphs[pos + 1]
intro.text = (
    "Bảng 4.1 tổng hợp các chức năng dành cho bệnh nhân đang có trong mã nguồn project. "
    "Cột cuối phân biệt ba trạng thái: backend nội bộ đã có, chức năng cục bộ/giao diện, "
    "và phần còn cần cấu hình API bên ngoài."
)
for r in intro.runs:
    set_font(r, 10)
intro.paragraph_format.space_after = Pt(7)
intro.paragraph_format.line_spacing = 1.05
intro.paragraph_format.keep_with_next = True

# Correct outdated descriptions immediately before section 4.5.
for p in paragraphs:
    if p.text.strip().startswith("Bản làm việc bác sĩ tổ chức") or p.text.strip().startswith("Bàn làm việc bác sĩ tổ chức"):
        p.text = (
            "Bàn làm việc bác sĩ tổ chức các bước tiếp nhận, gọi số, sinh hiệu, khám và ICD-10, "
            "cận lâm sàng/hình ảnh, kê đơn, ký/gửi EMR, hội chẩn, tái khám, ra y lệnh và gửi lời dặn. "
            "Các thao tác có appointment hợp lệ được gửi về backend để bệnh nhân xem lại và nhận thông báo; "
            "chữ ký hiện tại là HMAC trong ứng dụng, chưa phải chữ ký số PKI."
        )
        for r in p.runs:
            set_font(r, 10)
    if p.text.strip().startswith("Quản trị slot khám cho phép"):
        p.text = (
            "Quản trị slot cho phép theo dõi bác sĩ, phòng, capacity, booked và số chỗ còn lại. "
            "Admin có thể điều chỉnh lịch/slot qua API được bảo vệ bằng JWT và RBAC; các giao dịch thanh toán "
            "chưa có webhook vẫn chuyển về màn hình duyệt thủ công."
        )
        for r in p.runs:
            set_font(r, 10)

table = next(t for t in doc.tables if t.rows and t.cell(0, 0).text.strip() == "STT")
headers = ["STT", "Chức năng bệnh nhân", "Màn hình / mã nguồn", "Luồng xử lý và mức triển khai"]
widths = [Inches(0.42), Inches(1.35), Inches(1.72), Inches(2.92)]
for i, cell in enumerate(table.rows[0].cells):
    cell.width = widths[i]
    shade(cell, BLUE)
    set_cell_text(cell, headers[i], 8.5, True, WD_ALIGN_PARAGRAPH.CENTER)
    for r in cell.paragraphs[0].runs:
        r.font.color.rgb = RGBColor(255, 255, 255)
repeat_header(table.rows[0])
no_row_split(table.rows[0])

status = {
    1: "Backend nội bộ: /auth/login trả JWT/refresh và phân quyền bệnh nhân.",
    2: "Backend nội bộ khi API chạy; bước gửi OTP phụ thuộc email/SMS đã cấu hình.",
    3: "Backend + Gmail SMTP: verify-otp có thật; chưa có SMTP thì báo chưa cấu hình.",
    4: "Backend + Twilio: có luồng mã; SMS thật cần khóa Twilio.",
    5: "Luồng giao diện/OTP; khôi phục thật phụ thuộc kênh gửi đã cấu hình.",
    6: "Backend nội bộ khi cập nhật hồ sơ qua API; dữ liệu hiển thị theo tài khoản.",
    7: "Màn hình và lưu trữ theo app; chưa phải hệ thống thân nhân production riêng.",
    8: "Backend nội bộ: notification theo patient_id; FCM đẩy nền chưa tích hợp.",
    9: "Backend nội bộ: danh sách bác sĩ và lọc dữ liệu.",
    10: "Backend nội bộ: xem chi tiết và slot theo bác sĩ.",
    11: "Màn hình nội bộ: danh sách/mô tả chuyên khoa.",
    12: "Backend nội bộ: kiểm tra slot/capacity và tạo appointment.",
    13: "Backend nội bộ: xác nhận dữ liệu trước khi ghi lịch.",
    14: "Backend nội bộ: tải lịch và trạng thái theo bệnh nhân.",
    15: "Backend nội bộ: thao tác phụ thuộc trạng thái lịch và thanh toán.",
    16: "Backend nội bộ: cập nhật trạng thái và gửi thông báo.",
    17: "Backend nội bộ: tạo giao dịch; cổng thanh toán tự động chưa tích hợp.",
    18: "Backend nội bộ: yêu cầu nạp/lịch sử; admin duyệt khi chưa có webhook.",
    19: "QR hiển thị theo cấu hình; chưa xác thực tiền tự động nếu thiếu webhook ngân hàng.",
    20: "Backend/support request nội bộ: ghi yêu cầu để admin xử lý.",
    21: "Backend/support request nội bộ; lịch tiêm thật cần cơ sở dữ liệu y tế bổ sung.",
    22: "Luồng yêu cầu nội bộ; bảo hiểm thật cần API công ty bảo hiểm.",
    23: "Màn hình/thông tin thẻ; xác minh BHYT thật chưa tích hợp API ngoài.",
    24: "Backend nội bộ + SSE /queue/events khi các thiết bị dùng chung server.",
    25: "Backend nội bộ: tạo mã theo appointment đủ điều kiện.",
    26: "Backend nội bộ: chỉ hiển thị record bác sĩ đã gửi/xác nhận.",
    27: "Backend record/file nội bộ; LIS/PACS thật chưa tích hợp.",
    28: "Backend nội bộ: đơn thuốc do bác sĩ gửi; liên thông đơn thuốc quốc gia chưa có.",
    29: "Backend nội bộ theo ca khám; thiết bị đo tự động chưa tích hợp.",
    30: "Cục bộ trên thiết bị: lịch nhắc và local notification.",
    31: "Backend nội bộ khi appointment có trạng thái; một số nội dung là hiển thị tiến độ.",
    32: "API tùy cấu hình Infermedica/Gemini; fallback không phải chẩn đoán thật.",
    33: "RSS/cache/fallback; nội dung phụ thuộc nguồn tin, không phải hồ sơ bệnh viện.",
    34: "Màn hình nội dung hỗ trợ sức khỏe tinh thần trong app.",
    35: "Màn hình sơ đồ; chỉ đường trực tuyến cần Google Maps/Mapbox.",
    36: "Màn hình gọi hỗ trợ/cấp cứu; điều xe thật cần dispatcher API.",
    37: "Backend support requests/messages nội bộ.",
    38: "Luồng đánh giá sau khám trong app; cần kiểm tra API lưu đánh giá trước production.",
}

for i, row in enumerate(table.rows[1:], start=1):
    for j, cell in enumerate(row.cells):
        cell.width = widths[j]
        shade(cell, "FFFFFF" if i % 2 else LIGHT_BLUE)
        text = cell.text.strip()
        if j == 3:
            text = status.get(i, text)
        set_cell_text(cell, text, 7.9 if j == 3 else 8.2, j in (0, 1), WD_ALIGN_PARAGRAPH.CENTER if j == 0 else None)
    no_row_split(row)

# Prevent the large table from exceeding the portrait text width.
table.autofit = False
tbl_pr = table._tbl.tblPr
tbl_w = tbl_pr.find(qn("w:tblW"))
if tbl_w is None:
    tbl_w = OxmlElement("w:tblW")
    tbl_pr.append(tbl_w)
tbl_w.set(qn("w:w"), "6480")
tbl_w.set(qn("w:type"), "dxa")

# Normalize table captions and body paragraphs in the nearby chapter without changing images.
for p in doc.paragraphs:
    if p.text.strip().startswith("Hình "):
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(3)
        p.paragraph_format.space_after = Pt(5)
        for r in p.runs:
            set_font(r, 9)

doc.save(str(OUTPUT))
print(OUTPUT)
