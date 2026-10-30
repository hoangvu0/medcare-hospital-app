from pathlib import Path
from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.shared import Pt

SOURCE = Path(r"C:\Users\hoangvu\Downloads\2324801030027_2324801030077_2324801030052_Nhom09_XayDungUngDungHoTroKhamBenhVaChamSocSucKhoeBangFlutter_cap_nhat.docx")
OUTPUT = SOURCE.with_name(SOURCE.stem + "_muc_4_5_dep" + SOURCE.suffix)

doc = Document(str(SOURCE))

def set_font(run, name="Arial"):
    run.font.name = name
    run._element.get_or_add_rPr().get_or_add_rFonts().set(qn("w:ascii"), name)
    run._element.get_or_add_rPr().get_or_add_rFonts().set(qn("w:hAnsi"), name)
    run._element.get_or_add_rPr().get_or_add_rFonts().set(qn("w:eastAsia"), name)

def format_paragraph(p, size=11, bold=None, before=0, after=6, line=1.15):
    pf = p.paragraph_format
    pf.space_before = Pt(before)
    pf.space_after = Pt(after)
    pf.line_spacing = line
    pf.keep_together = True
    for r in p.runs:
        set_font(r)
        r.font.size = Pt(size)
        if bold is not None:
            r.bold = bold

# Normalize the base styles so Vietnamese text uses a Unicode-capable font.
for style_name in ("Normal", "Body Text"):
    try:
        style = doc.styles[style_name]
        style.font.name = "Arial"
        style._element.rPr.rFonts.set(qn("w:eastAsia"), "Arial")
        style.font.size = Pt(11)
    except KeyError:
        pass

# Locate the current section instead of relying on paragraph indexes.
heading = next(p for p in doc.paragraphs if p.text.strip().startswith("4.5."))
heading.text = "4.5. Các màn hình và tiện ích mở rộng"
format_paragraph(heading, size=14, bold=True, before=10, after=8, line=1.0)
heading.paragraph_format.keep_with_next = True

body = next(p for p in doc.paragraphs if p.text.strip().startswith("Các tiện ích mở rộng gồm"))
body.text = (
    "Các màn hình mở rộng được tổ chức theo nhóm để người dùng dễ theo dõi và không nhầm giữa dữ liệu nội bộ với dịch vụ bên ngoài:\n"
    "- Sức khỏe: AI chat, chỉ số sinh hiệu, nhắc thuốc, cẩm nang y khoa và tin tức bệnh viện/y tế.\n"
    "- Khám chữa bệnh: gói tầm soát, tiêm chủng, hồ sơ gia đình, BHYT/bảo lãnh và QR check-in.\n"
    "- Tiện ích hệ thống: thông báo chuông, hỗ trợ, bản đồ bệnh viện, ví và lịch sử giao dịch.\n"
    "Các chức năng đã có API nội bộ sẽ đọc dữ liệu từ backend và tạo thông báo khi có cập nhật. AI, tin tức RSS, email/SMS OTP, FCM, bản đồ, bảo hiểm và thanh toán tự động chỉ hoạt động đầy đủ khi đã cấu hình dịch vụ tương ứng; trạng thái chưa cấu hình phải hiển thị rõ, không tạo kết quả giả."
)
format_paragraph(body, size=10.5, before=0, after=10, line=1.12)
body.paragraph_format.keep_together = True

# Make nearby captions/body paragraphs consistent and prevent heading/caption overlap.
for p in doc.paragraphs:
    t = p.text.strip()
    if t.startswith("Hình "):
        format_paragraph(p, size=9.5, bold=False, before=3, after=5, line=1.0)
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    elif t.startswith(("4.6.", "4.6.1.")):
        format_paragraph(p, size=13 if t.startswith("4.6.") and not t.startswith("4.6.1.") else 11.5,
                         bold=True, before=8, after=6, line=1.0)
    elif p.runs:
        for r in p.runs:
            set_font(r)

# Normalize table text too, preventing font fallback in screenshots/tables.
for table in doc.tables:
    for row in table.rows:
        for cell in row.cells:
            for p in cell.paragraphs:
                for r in p.runs:
                    set_font(r)
                    if r.font.size is None:
                        r.font.size = Pt(10)
                p.paragraph_format.line_spacing = 1.05
                p.paragraph_format.space_after = Pt(2)

doc.save(str(OUTPUT))
print(OUTPUT)
