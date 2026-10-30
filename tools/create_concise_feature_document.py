from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.enum.table import WD_ALIGN_VERTICAL, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Mo_ta_chuc_nang_MedCare.docx"


def set_font(run, size: float | None = None, bold: bool | None = None) -> None:
    run.font.name = "Arial"
    run._element.rPr.rFonts.set(qn("w:ascii"), "Arial")
    run._element.rPr.rFonts.set(qn("w:hAnsi"), "Arial")
    if size is not None:
        run.font.size = Pt(size)
    if bold is not None:
        run.bold = bold


def set_cell_shading(cell, fill: str) -> None:
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_border(cell, color: str = "D9D9D9") -> None:
    tc_pr = cell._tc.get_or_add_tcPr()
    borders = tc_pr.first_child_found_in("w:tcBorders")
    if borders is None:
        borders = OxmlElement("w:tcBorders")
        tc_pr.append(borders)
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        node = borders.find(qn(f"w:{edge}"))
        if node is None:
            node = OxmlElement(f"w:{edge}")
            borders.append(node)
        node.set(qn("w:val"), "single")
        node.set(qn("w:sz"), "6")
        node.set(qn("w:space"), "0")
        node.set(qn("w:color"), color)


def set_cell_margins(cell, top=90, start=110, bottom=90, end=110) -> None:
    tc_pr = cell._tc.get_or_add_tcPr()
    margins = tc_pr.first_child_found_in("w:tcMar")
    if margins is None:
        margins = OxmlElement("w:tcMar")
        tc_pr.append(margins)
    for name, value in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        node = margins.find(qn(f"w:{name}"))
        if node is None:
            node = OxmlElement(f"w:{name}")
            margins.append(node)
        node.set(qn("w:w"), str(value))
        node.set(qn("w:type"), "dxa")


def set_cell_width(cell, width_cm: float) -> None:
    tc_pr = cell._tc.get_or_add_tcPr()
    width = tc_pr.find(qn("w:tcW"))
    if width is None:
        width = OxmlElement("w:tcW")
        tc_pr.append(width)
    width.set(qn("w:w"), str(int(width_cm * 567)))
    width.set(qn("w:type"), "dxa")


def style_table(table, widths: list[float]) -> None:
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    for row_index, row in enumerate(table.rows):
        if row_index == 0:
            tr_pr = row._tr.get_or_add_trPr()
            tbl_header = OxmlElement("w:tblHeader")
            tbl_header.set(qn("w:val"), "true")
            tr_pr.append(tbl_header)
        for col_index, cell in enumerate(row.cells):
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            set_cell_border(cell)
            set_cell_margins(cell)
            if col_index < len(widths):
                set_cell_width(cell, widths[col_index])
            if row_index == 0:
                set_cell_shading(cell, "1F4E79")
            elif row_index % 2 == 0:
                set_cell_shading(cell, "F7FBFF")
            for paragraph in cell.paragraphs:
                paragraph.paragraph_format.space_after = Pt(0)
                paragraph.paragraph_format.line_spacing = 1.08
                if row_index == 0:
                    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
                for run in paragraph.runs:
                    set_font(run, 9.2, row_index == 0)
                    if row_index == 0:
                        run.font.color.rgb = RGBColor(255, 255, 255)


def add_table(doc: Document, headers: list[str], rows: list[list[str]], widths: list[float]) -> None:
    table = doc.add_table(rows=1, cols=len(headers))
    table.style = "Table Grid"
    for index, header in enumerate(headers):
        table.rows[0].cells[index].text = header
    for row in rows:
        cells = table.add_row().cells
        for index, value in enumerate(row):
            cells[index].text = value
    style_table(table, widths)
    doc.add_paragraph()


def add_heading(doc: Document, text: str, level: int = 1) -> None:
    paragraph = doc.add_heading(text, level=level)
    paragraph.paragraph_format.space_before = Pt(8)
    paragraph.paragraph_format.space_after = Pt(4)
    for run in paragraph.runs:
        set_font(run)
        run.font.color.rgb = RGBColor(0, 0, 0)


def add_paragraph(doc: Document, text: str) -> None:
    paragraph = doc.add_paragraph()
    paragraph.paragraph_format.space_after = Pt(5)
    paragraph.paragraph_format.line_spacing = 1.12
    run = paragraph.add_run(text)
    set_font(run, 10.3)


def add_bullets(doc: Document, items: list[str]) -> None:
    for item in items:
        paragraph = doc.add_paragraph(style="List Bullet")
        paragraph.paragraph_format.space_after = Pt(2)
        paragraph.paragraph_format.line_spacing = 1.08
        run = paragraph.add_run(item)
        set_font(run, 10.1)


def apply_styles(doc: Document) -> None:
    for style_name in ("Normal", "Body Text", "List Bullet"):
        style = doc.styles[style_name]
        style.font.name = "Arial"
        style._element.rPr.rFonts.set(qn("w:ascii"), "Arial")
        style._element.rPr.rFonts.set(qn("w:hAnsi"), "Arial")
        style.font.size = Pt(10.3)
    for style_name, size in (("Title", 19), ("Heading 1", 14), ("Heading 2", 12)):
        style = doc.styles[style_name]
        style.font.name = "Arial"
        style._element.rPr.rFonts.set(qn("w:ascii"), "Arial")
        style._element.rPr.rFonts.set(qn("w:hAnsi"), "Arial")
        style.font.size = Pt(size)
        style.font.color.rgb = RGBColor(0, 0, 0)


def main() -> None:
    doc = Document()
    apply_styles(doc)

    section = doc.sections[0]
    section.top_margin = Cm(1.6)
    section.bottom_margin = Cm(1.6)
    section.left_margin = Cm(1.8)
    section.right_margin = Cm(1.8)

    title = doc.add_paragraph()
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    title.paragraph_format.space_after = Pt(8)
    run = title.add_run("Mô tả chức năng ứng dụng bệnh viện MedCare")
    set_font(run, 19, True)

    subtitle = doc.add_paragraph()
    subtitle.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = subtitle.add_run("Đề tài phát triển ứng dụng di động đa nền tảng")
    set_font(run, 10.5, True)

    add_paragraph(
        doc,
        "Tài liệu tóm tắt các chức năng chính của MedCare theo hướng một ứng dụng bệnh viện thực tế: có app Flutter, backend API, dữ liệu SQLite, phân quyền người dùng và các luồng khám bệnh cơ bản.",
    )

    add_heading(doc, "1 Tổng quan")
    add_paragraph(
        doc,
        "MedCare phục vụ ba nhóm người dùng gồm bệnh nhân, bác sĩ và quản trị viên. Hệ thống hỗ trợ đặt lịch khám, theo dõi hàng đợi, quản lý hồ sơ bệnh án, đơn thuốc, sinh hiệu, thanh toán, bảo hiểm và đồng bộ dữ liệu với backend.",
    )

    add_heading(doc, "2 Phân quyền người dùng")
    add_table(
        doc,
        ["Vai trò", "Chức năng được dùng", "Giới hạn"],
        [
            ["Bệnh nhân", "Đăng nhập, đặt lịch, xem hồ sơ, đơn thuốc, hàng đợi, sinh hiệu, thanh toán, BHYT và hồ sơ gia đình.", "Không vào được bàn làm việc bác sĩ hoặc trang quản trị."],
            ["Bác sĩ", "Xem ca khám, gọi số tiếp theo, cập nhật hồ sơ bệnh án, kê đơn và theo dõi thông tin khám.", "Không truy cập chức năng quản trị hệ thống."],
            ["Quản trị viên", "Quản lý khung giờ, giám sát hệ thống, xem nhật ký hoạt động và hỗ trợ điều phối.", "Không thay thế thao tác chuyên môn của bác sĩ."],
        ],
        [3.0, 8.0, 5.3],
    )

    add_heading(doc, "3 Chức năng chính")
    add_table(
        doc,
        ["Phân hệ", "Mô tả chức năng", "Trạng thái"],
        [
            ["Đăng nhập", "Đăng nhập theo tài khoản, nhận access token và refresh token, tự điều hướng theo vai trò.", "Đã có"],
            ["Đặt lịch khám", "Chọn bác sĩ, chuyên khoa, thời gian, lý do khám và lưu lịch hẹn.", "Đã có"],
            ["Hàng đợi khám", "Hiển thị số đang gọi, số của bệnh nhân, phòng khám, thời gian chờ và cập nhật realtime bằng SSE.", "Đã có"],
            ["Bàn làm việc bác sĩ", "Bác sĩ xem danh sách chờ, gọi số kế tiếp, xem thông tin bệnh nhân và xử lý hồ sơ.", "Đã có"],
            ["Hồ sơ bệnh án", "Lưu chẩn đoán, kết quả khám, chỉ định, lịch sử khám và thông tin y tế liên quan.", "Đã có"],
            ["Đơn thuốc", "Hiển thị thuốc, liều dùng, thời gian uống, hướng dẫn sử dụng và trạng thái đơn.", "Đã có"],
            ["Theo dõi sinh hiệu", "Theo dõi huyết áp, nhịp tim, SpO2, cân nặng, nhiệt độ và lịch sử đo.", "Đã có"],
            ["Hồ sơ gia đình", "Quản lý nhiều thành viên, BHYT, dị ứng, nhóm máu và quan hệ gia đình.", "Đã có"],
            ["Thanh toán và bảo hiểm", "Theo dõi viện phí, giao dịch, thông tin BHYT và bảo lãnh viện phí.", "Đã có"],
            ["Telemedicine", "Hỗ trợ khám từ xa, thông tin phiên tư vấn và chuyển sang đơn thuốc sau tư vấn.", "Đã có"],
            ["Quản trị lịch", "Admin quản lý khung giờ khám và điều phối vận hành.", "Đã có"],
            ["Đồng bộ dữ liệu", "Ứng dụng gửi snapshot dữ liệu lên backend qua API có xác thực.", "Đã có"],
        ],
        [3.1, 10.0, 3.2],
    )

    add_heading(doc, "4 Luồng xử lý chính")
    add_bullets(
        doc,
        [
            "Bệnh nhân đăng nhập, hệ thống xác định vai trò và chuyển về trang chủ bệnh nhân.",
            "Bệnh nhân chọn bác sĩ hoặc chuyên khoa, đặt lịch khám và theo dõi lịch hẹn.",
            "Khi đến khám, bệnh nhân xem màn hình hàng đợi để biết số đang gọi và thời gian chờ.",
            "Bác sĩ đăng nhập vào bàn làm việc, gọi số tiếp theo và xử lý hồ sơ khám.",
            "Sau khám, bác sĩ cập nhật hồ sơ bệnh án, tạo đơn thuốc và gửi dữ liệu về backend.",
            "Admin theo dõi vận hành, quản lý khung giờ và kiểm tra nhật ký hệ thống.",
        ],
    )

    add_heading(doc, "5 Backend API và dữ liệu")
    add_table(
        doc,
        ["Thành phần", "Nội dung"],
        [
            ["Backend", "Dart HTTP server riêng cho đăng nhập, lịch hẹn, đơn thuốc, hồ sơ bệnh án, hàng đợi, đồng bộ và audit."],
            ["API chính", "/auth/login, /auth/refresh, /appointments, /prescriptions, /records, /queue, /queue/events, /sync, /audit."],
            ["Dữ liệu", "App dùng SQLite local; backend hiện dùng SQLite server-side. PostgreSQL chưa chuyển đổi."],
            ["Bảo mật", "Có JWT, refresh token, phân quyền server-side, role gate trong app và audit log."],
            ["Realtime", "Hàng đợi dùng Server-Sent Events để cập nhật khi bác sĩ hoặc admin gọi số tiếp theo."],
        ],
        [4.0, 11.5],
    )

    add_heading(doc, "6 Đánh giá mức hoàn thiện")
    add_paragraph(
        doc,
        "Sản phẩm đã có đầy đủ khung chức năng bệnh viện ở mức demo nâng cao và có backend/API thật để trình bày. Các phần còn cần làm nếu triển khai production thật gồm chuyển backend sang PostgreSQL, bật mã hóa SQLite at-rest bằng SQLCipher, deploy lên server/domain thật, chạy CI/CD thực tế và kiểm thử E2E trên thiết bị thật.",
    )

    doc.core_properties.title = "Mô tả chức năng ứng dụng bệnh viện MedCare"
    doc.core_properties.subject = "Chi tiết chức năng đề tài"
    doc.core_properties.author = "MedCare"
    doc.save(OUT)
    print(OUT)


if __name__ == "__main__":
    main()
