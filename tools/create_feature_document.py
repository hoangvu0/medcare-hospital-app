from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_ALIGN_VERTICAL, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Chi_tiet_chuc_nang_de_tai_MedCare.docx"


def set_cell_shading(cell, fill: str) -> None:
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_border(cell, color: str = "D9D9D9") -> None:
    tc = cell._tc
    tc_pr = tc.get_or_add_tcPr()
    borders = tc_pr.first_child_found_in("w:tcBorders")
    if borders is None:
        borders = OxmlElement("w:tcBorders")
        tc_pr.append(borders)
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        tag = f"w:{edge}"
        element = borders.find(qn(tag))
        if element is None:
            element = OxmlElement(tag)
            borders.append(element)
        element.set(qn("w:val"), "single")
        element.set(qn("w:sz"), "6")
        element.set(qn("w:space"), "0")
        element.set(qn("w:color"), color)


def set_cell_margins(cell, top=100, start=120, bottom=100, end=120) -> None:
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


def set_width(cell, width_cm: float) -> None:
    tc_pr = cell._tc.get_or_add_tcPr()
    width = tc_pr.find(qn("w:tcW"))
    if width is None:
        width = OxmlElement("w:tcW")
        tc_pr.append(width)
    width.set(qn("w:w"), str(int(width_cm * 567)))
    width.set(qn("w:type"), "dxa")


def style_table(table, widths: list[float], header_fill: str = "1F4E79") -> None:
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    for row_idx, row in enumerate(table.rows):
        for col_idx, cell in enumerate(row.cells):
            set_cell_border(cell)
            set_cell_margins(cell)
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            if col_idx < len(widths):
                set_width(cell, widths[col_idx])
            for paragraph in cell.paragraphs:
                paragraph.paragraph_format.space_after = Pt(0)
                paragraph.paragraph_format.line_spacing = 1.08
                for run in paragraph.runs:
                    run.font.name = "Arial"
                    run._element.rPr.rFonts.set(qn("w:ascii"), "Arial")
                    run._element.rPr.rFonts.set(qn("w:hAnsi"), "Arial")
                    run.font.size = Pt(9)
            if row_idx == 0:
                set_cell_shading(cell, header_fill)
                for paragraph in cell.paragraphs:
                    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
                    for run in paragraph.runs:
                        run.font.bold = True
                        run.font.color.rgb = RGBColor(255, 255, 255)
            elif row_idx % 2 == 0:
                set_cell_shading(cell, "F7FBFF")


def add_table(document: Document, headers: list[str], rows: list[list[str]], widths: list[float]) -> None:
    table = document.add_table(rows=1, cols=len(headers))
    table.style = "Table Grid"
    for i, header in enumerate(headers):
        table.rows[0].cells[i].text = header
    for row_data in rows:
        cells = table.add_row().cells
        for i, value in enumerate(row_data):
            cells[i].text = value
    style_table(table, widths)
    document.add_paragraph()


def add_bullets(document: Document, items: list[str]) -> None:
    for item in items:
        p = document.add_paragraph(style="List Bullet")
        p.add_run(item)


def add_heading(document: Document, text: str, level: int = 1) -> None:
    paragraph = document.add_heading(text, level=level)
    for run in paragraph.runs:
        run.font.color.rgb = RGBColor(0, 0, 0)
        run.font.name = "Arial"
        run._element.rPr.rFonts.set(qn("w:ascii"), "Arial")
        run._element.rPr.rFonts.set(qn("w:hAnsi"), "Arial")


def add_paragraph(document: Document, text: str = "", bold_lead: str | None = None) -> None:
    p = document.add_paragraph()
    p.paragraph_format.space_after = Pt(6)
    p.paragraph_format.line_spacing = 1.15
    if bold_lead:
        run = p.add_run(bold_lead)
        run.bold = True
        p.add_run(text)
    else:
        p.add_run(text)


def apply_base_styles(document: Document) -> None:
    styles = document.styles
    for style_name in ("Normal", "Body Text", "List Bullet"):
        if style_name in styles:
            style = styles[style_name]
            style.font.name = "Arial"
            style._element.rPr.rFonts.set(qn("w:ascii"), "Arial")
            style._element.rPr.rFonts.set(qn("w:hAnsi"), "Arial")
            style.font.size = Pt(10.5)
    for style_name in ("Title", "Heading 1", "Heading 2", "Heading 3"):
        style = styles[style_name]
        style.font.name = "Arial"
        style._element.rPr.rFonts.set(qn("w:ascii"), "Arial")
        style._element.rPr.rFonts.set(qn("w:hAnsi"), "Arial")
        style.font.color.rgb = RGBColor(0, 0, 0)
    styles["Title"].font.size = Pt(20)
    styles["Heading 1"].font.size = Pt(15)
    styles["Heading 2"].font.size = Pt(12.5)


def main() -> None:
    doc = Document()
    apply_base_styles(doc)

    section = doc.sections[0]
    section.top_margin = Cm(1.8)
    section.bottom_margin = Cm(1.8)
    section.left_margin = Cm(2.0)
    section.right_margin = Cm(2.0)

    title = doc.add_paragraph(style="Title")
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    title.add_run("Chi tiết chức năng đề tài ứng dụng bệnh viện MedCare")

    subtitle = doc.add_paragraph()
    subtitle.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = subtitle.add_run("Đề tài Phát triển ứng dụng di động đa nền tảng")
    run.bold = True
    run.font.size = Pt(11)
    doc.add_paragraph()

    add_paragraph(
        doc,
        "Tài liệu này mô tả phạm vi chức năng, luồng xử lý và thành phần kỹ thuật chính của hệ thống MedCare. "
        "Ứng dụng được xây dựng theo hướng mô phỏng một hệ thống bệnh viện hiện đại, có phân quyền người dùng, "
        "quản lý lịch khám, hàng đợi, đơn thuốc, hồ sơ bệnh án, theo dõi sức khỏe và đồng bộ dữ liệu với backend.",
    )

    add_heading(doc, "1 Tổng quan đề tài")
    add_paragraph(
        doc,
        "MedCare là ứng dụng di động đa nền tảng phục vụ người bệnh, bác sĩ và quản trị viên bệnh viện. "
        "Hệ thống tập trung vào các nghiệp vụ thường gặp trong bệnh viện như đặt lịch, theo dõi số thứ tự khám, "
        "quản lý hồ sơ bệnh án, nhận đơn thuốc điện tử, thanh toán viện phí và nhận hỗ trợ sức khỏe từ xa.",
    )
    add_paragraph(
        doc,
        "Phiên bản hiện tại đã có ứng dụng Flutter, cơ sở dữ liệu SQLite cục bộ, backend API riêng, phân quyền theo vai trò "
        "và kiểm thử tự động cho các luồng quan trọng. Mức độ hoàn thiện được định hướng theo sản phẩm thật nhưng vẫn cần "
        "bổ sung triển khai production, mã hóa dữ liệu cục bộ bằng giải pháp chuyên dụng và kiểm thử thiết bị thật trước khi vận hành chính thức.",
    )

    add_heading(doc, "2 Mục tiêu hệ thống")
    add_bullets(
        doc,
        [
            "Hỗ trợ người bệnh quản lý lịch khám, hồ sơ sức khỏe, đơn thuốc, thẻ bệnh nhân và thông tin bảo hiểm trong một ứng dụng.",
            "Hỗ trợ bác sĩ thao tác với hàng đợi, kê đơn, cập nhật hồ sơ bệnh án và gửi dặn dò sau khám.",
            "Hỗ trợ quản trị viên quản lý khung giờ khám, giám sát hệ thống và xem nhật ký hoạt động.",
            "Đảm bảo phân quyền rõ ràng để bệnh nhân không truy cập được bàn làm việc của bác sĩ hoặc khu vực quản trị.",
            "Chuẩn hóa backend/API để dữ liệu có thể đồng bộ giữa ứng dụng và máy chủ.",
        ],
    )

    add_heading(doc, "3 Đối tượng sử dụng và phân quyền")
    role_rows = [
        [
            "Bệnh nhân",
            "Đăng nhập, đặt lịch, xem hàng đợi, xem đơn thuốc, hồ sơ bệnh án, theo dõi sinh hiệu, quản lý hồ sơ gia đình, thanh toán và bảo hiểm.",
            "Không được truy cập bàn làm việc bác sĩ, trang quản trị hoặc API tạo đơn thuốc, cập nhật hồ sơ, gọi số tiếp theo.",
        ],
        [
            "Bác sĩ",
            "Vào bàn làm việc bác sĩ, gọi số tiếp theo, ghi nhận sinh hiệu, chỉ định xét nghiệm, kê đơn, ký số EMR và dặn dò tái khám.",
            "Không được truy cập chức năng quản trị khung giờ hoặc audit admin.",
        ],
        [
            "Quản trị viên",
            "Quản lý khung giờ khám, xem audit log, kiểm tra trạng thái hệ thống và hỗ trợ điều phối vận hành.",
            "Chỉ sử dụng các chức năng quản trị, không thay thế vai trò chuyên môn của bác sĩ trong thao tác khám bệnh.",
        ],
    ]
    add_table(doc, ["Vai trò", "Quyền chính", "Giới hạn truy cập"], role_rows, [3.0, 7.0, 6.0])

    add_heading(doc, "4 Chi tiết chức năng theo phân hệ")
    feature_rows = [
        ["Đăng nhập và phân quyền", "Đăng nhập theo tài khoản bệnh nhân, bác sĩ, admin; điều hướng đến màn hình đúng vai trò; chặn truy cập sai quyền.", "Đã có app-side role gate và server-side RBAC."],
        ["Trang chủ bệnh nhân", "Hiển thị hồ sơ, lịch hẹn, lộ trình khám, nhắc tái khám, bác sĩ nổi bật, tiện ích nhanh và cảnh báo sức khỏe.", "Đã có giao diện và dữ liệu mẫu mở rộng."],
        ["Hồ sơ gia đình", "Quản lý nhiều thành viên, BHYT, dị ứng, bệnh nền, quan hệ gia đình và chọn hồ sơ đang sử dụng.", "Đã tối ưu hiển thị mobile."],
        ["Danh sách bác sĩ", "Tìm kiếm bác sĩ, lọc chuyên khoa, xem đánh giá, giá khám, lịch làm việc và chuyển sang đặt lịch.", "Có dữ liệu 20 bác sĩ chuyên khoa."],
        ["Đặt lịch khám", "Chọn bác sĩ, chuyên khoa, thời gian, gói khám và gửi yêu cầu lịch hẹn.", "Backend có API tạo lịch patient-only."],
        ["Hàng đợi trực tiếp", "Xem số hiện tại, số của bệnh nhân, phòng khám, thời gian chờ và cập nhật khi bác sĩ gọi số.", "Backend có SSE /queue/events."],
        ["Tư vấn từ xa", "Mô phỏng cuộc gọi video, chat trong phiên, kết thúc buổi khám và tạo đơn thuốc sau tư vấn.", "Có màn hình Telemedicine responsive."],
        ["Đơn thuốc điện tử", "Xem toa thuốc, thuốc đang dùng, hướng dẫn dùng thuốc, cảnh báo dị ứng và theo dõi tiến độ uống thuốc.", "Bác sĩ/admin có API tạo đơn thuốc."],
        ["Hồ sơ bệnh án EMR", "Xem lịch sử khám, chẩn đoán ICD-10, triệu chứng, khám thực thể, chữ ký số, xét nghiệm và ảnh chẩn đoán.", "Có màn bệnh án và dữ liệu lâm sàng chi tiết."],
        ["Theo dõi sinh hiệu", "Ghi nhận huyết áp, nhịp tim, SpO2, nhiệt độ, đường huyết và hiển thị cảnh báo.", "Có màn Vitals Tracker."],
        ["Diễn giải xét nghiệm AI", "Phân loại chỉ số bình thường, chú ý, vượt ngưỡng; giải thích ý nghĩa lâm sàng và khuyến nghị ăn uống.", "Có bộ lọc huyết học, sinh hóa, bất thường."],
        ["Bảo hiểm và bảo lãnh viện phí", "Mô phỏng bảo lãnh viện phí cashless, chọn hãng bảo hiểm, tính phần bảo hiểm chi trả và phần đồng chi trả.", "Có lịch sử yêu cầu đã duyệt."],
        ["Thanh toán viện phí", "Quản lý ví viện phí, hóa đơn, hoàn tiền tạm ứng và trạng thái thanh toán.", "Có chức năng ví và auto-refund trong store/test."],
        ["Sổ tiêm chủng", "Xem lịch sử tiêm, mũi nhắc lại, danh mục vắc xin và hộ chiếu vắc xin điện tử.", "Có màn Vaccination."],
        ["Gói khám sức khỏe", "Hiển thị gói khám tầm soát, quyền lợi, đối tượng phù hợp, giá và đăng ký tư vấn.", "Có màn Health Packages."],
        ["Bản đồ bệnh viện", "Chỉ đường nội viện từ điểm xuất phát đến phòng khám, mô tả lộ trình 4 bước và sơ đồ tòa nhà.", "Có màn Hospital Map."],
        ["Thẻ bệnh nhân số", "Hiển thị mã bệnh nhân, BHYT, QR/Kiosk và thông tin nhận diện nhanh.", "Có màn Digital Card."],
        ["SOS khẩn cấp", "Hiển thị hotline, thao tác gọi khẩn cấp, thông tin bệnh nhân và vị trí hỗ trợ.", "Có màn Emergency SOS."],
        ["Sức khỏe tinh thần", "Bài tập thở Box Breathing, trắc nghiệm PHQ-9 và kết quả tư vấn mức độ.", "Có màn Mental Health."],
        ["Cẩm nang sức khỏe", "Danh sách bài viết y khoa, nguồn/tác giả/ngày đọc và chi tiết bài viết.", "Có màn Health News."],
        ["Bàn làm việc bác sĩ", "Gọi số, ghi hồ sơ, kê đơn, dặn dò, ký số EMR, kiểm tra tương tác thuốc, dị ứng và tính liều theo thận.", "Có store logic và test chuyên sâu."],
        ["Quản trị khung giờ", "Quản lý slot khám, kiểm tra lịch, điều phối vận hành và phân quyền admin.", "Có màn Admin Slot."],
        ["Chẩn đoán hệ thống", "Hiển thị trạng thái SQLite, backend sync, cache, offline mode, bảo mật và kiểm thử.", "Có màn Diagnostics."],
    ]
    add_table(doc, ["Phân hệ", "Chức năng chi tiết", "Tình trạng hiện tại"], feature_rows, [3.7, 8.0, 4.3])

    add_heading(doc, "5 Luồng xử lý nghiệp vụ chính")
    flow_rows = [
        ["Đăng nhập", "Người dùng nhập tài khoản và mật khẩu. Hệ thống xác định vai trò patient, doctor hoặc admin. Ứng dụng điều hướng đến trang tương ứng và backend cấp access token, refresh token khi dùng API thật."],
        ["Đặt lịch khám", "Bệnh nhân chọn bác sĩ, chuyên khoa, thời gian và lý do khám. Backend kiểm tra quyền bệnh nhân, tạo lịch hẹn và trả trạng thái confirmed."],
        ["Theo dõi hàng đợi", "Bệnh nhân xem số hiện tại và số của mình. Bác sĩ gọi số tiếp theo từ bàn làm việc. Backend cập nhật queue và phát sự kiện realtime qua SSE."],
        ["Khám bệnh và kê đơn", "Bác sĩ ghi nhận dấu hiệu sinh tồn, chẩn đoán, chỉ định xét nghiệm, kê thuốc, kiểm tra dị ứng/tương tác thuốc và ký số hồ sơ."],
        ["Đồng bộ dữ liệu", "Ứng dụng gửi snapshot dữ liệu lên API /sync với Bearer token. Backend lưu snapshot và ghi audit log."],
        ["Bảo lãnh viện phí", "Người bệnh chọn khoản viện phí và đơn vị bảo hiểm. Hệ thống tính phần bảo hiểm chi trả, phần đồng chi trả và tạo lịch sử yêu cầu."],
    ]
    add_table(doc, ["Luồng", "Mô tả xử lý"], flow_rows, [4.0, 12.0])

    add_heading(doc, "6 Backend API và cơ sở dữ liệu")
    add_paragraph(
        doc,
        "Backend được xây dựng bằng Dart HttpServer, sử dụng SQLite server-side và JWT HMAC SHA-256. "
        "Hệ thống có access token thời hạn ngắn, refresh token lưu trong bảng riêng, audit log và phân quyền server-side cho các nghiệp vụ nhạy cảm.",
    )
    api_rows = [
        ["/health", "GET", "Kiểm tra trạng thái backend."],
        ["/auth/login", "POST", "Đăng nhập, trả user profile, access token và refresh token."],
        ["/auth/refresh", "POST", "Xoay vòng refresh token và cấp access token mới."],
        ["/auth/logout", "POST", "Thu hồi refresh token."],
        ["/me", "GET", "Lấy thông tin người dùng hiện tại."],
        ["/appointments", "GET POST", "Xem lịch hẹn theo vai trò và tạo lịch hẹn cho bệnh nhân."],
        ["/appointments/{id}", "PATCH", "Bác sĩ hoặc admin cập nhật trạng thái lịch hẹn."],
        ["/prescriptions", "GET POST", "Xem đơn thuốc và cho phép bác sĩ hoặc admin tạo đơn thuốc."],
        ["/records", "GET POST", "Xem hồ sơ bệnh án và cho phép bác sĩ hoặc admin tạo hồ sơ."],
        ["/queue", "GET", "Lấy trạng thái hàng đợi hiện tại."],
        ["/queue/call-next", "POST", "Bác sĩ hoặc admin gọi số tiếp theo."],
        ["/queue/events", "GET", "Realtime queue bằng Server-Sent Events."],
        ["/sync", "POST", "Đồng bộ snapshot từ app, yêu cầu Bearer token."],
        ["/audit", "GET", "Admin xem nhật ký hệ thống."],
    ]
    add_table(doc, ["Endpoint", "Phương thức", "Mục đích"], api_rows, [4.0, 2.5, 9.5])

    db_rows = [
        ["users", "Lưu tài khoản, vai trò, thông tin định danh bệnh nhân."],
        ["refresh_tokens", "Lưu hash refresh token, hạn dùng và trạng thái thu hồi."],
        ["appointments", "Lưu lịch hẹn, bác sĩ, bệnh nhân, thời gian, trạng thái và số phiếu."],
        ["prescriptions", "Lưu đơn thuốc, chẩn đoán và danh sách thuốc dạng JSON."],
        ["medical_records", "Lưu hồ sơ bệnh án, chẩn đoán, ghi chú và dữ liệu lâm sàng."],
        ["queue_state", "Lưu trạng thái hàng đợi phòng khám."],
        ["sync_snapshots", "Lưu dữ liệu đồng bộ từ ứng dụng."],
        ["audit_logs", "Lưu nhật ký đăng nhập, thao tác hàng đợi, tạo hồ sơ, tạo đơn thuốc và đồng bộ."],
    ]
    add_table(doc, ["Bảng dữ liệu", "Vai trò"], db_rows, [4.0, 12.0])

    add_heading(doc, "7 Kiểm thử và chất lượng giao diện")
    add_paragraph(
        doc,
        "Dự án có kiểm thử unit, widget, responsive overflow và integration test cho backend. "
        "Các màn hình bệnh nhân quan trọng đã được kiểm tra ở kích thước điện thoại hẹp để tránh lỗi chữ dọc, vàng đen hoặc tràn layout.",
    )
    test_rows = [
        ["flutter analyze", "Kiểm tra lỗi tĩnh trong ứng dụng Flutter.", "Đạt"],
        ["flutter test", "Chạy toàn bộ test Flutter gồm store, role routing, responsive overflow và widget tests.", "Đạt 48/48"],
        ["dart analyze trong server", "Kiểm tra lỗi tĩnh backend Dart.", "Đạt"],
        ["dart test trong server", "Chạy integration test HTTP cho login, refresh token, phân quyền và hàng đợi.", "Đạt"],
    ]
    add_table(doc, ["Hạng mục", "Nội dung kiểm thử", "Kết quả"], test_rows, [4.5, 8.0, 3.5])

    add_heading(doc, "8 So sánh với ứng dụng bệnh viện thực tế")
    add_paragraph(
        doc,
        "Khi so với các ứng dụng y tế đang được sử dụng thực tế như Medpro và MyVinmec, MedCare có nhiều điểm tương đồng về đặt lịch, hồ sơ sức khỏe, "
        "tư vấn từ xa và quản lý thông tin người bệnh. Điểm khác biệt của MedCare nằm ở việc mô phỏng sâu hơn luồng vận hành nội bộ bệnh viện, "
        "bao gồm bàn làm việc bác sĩ, phân quyền server-side, realtime queue, ký số EMR, lộ trình khám và các chức năng lâm sàng hỗ trợ bác sĩ.",
    )
    comparison_rows = [
        [
            "Đặt lịch và lấy số",
            "Cho phép chọn bệnh viện, chuyên khoa, bác sĩ, thời gian khám; sau thanh toán hiển thị phiếu khám điện tử và số thứ tự.",
            "Hỗ trợ đặt lịch, nhắc lịch và kết nối lịch hẹn với hồ sơ y tế Vinmec.",
            "Có đặt lịch, chọn bác sĩ, gói khám, hàng đợi trực tiếp và API tạo lịch chỉ dành cho bệnh nhân.",
        ],
        [
            "Hồ sơ cá nhân và gia đình",
            "Tạo hồ sơ bệnh nhân, có thể quét BHYT hoặc nhập số hồ sơ cũ khi đăng ký khám.",
            "Tạo hồ sơ cá nhân và người thân, lưu mã khách hàng để check-in nhanh tại bệnh viện.",
            "Quản lý hồ sơ gia đình, BHYT, dị ứng, bệnh nền, quan hệ thành viên và hồ sơ đang hoạt động.",
        ],
        [
            "Hồ sơ khám và kết quả",
            "Theo dõi lịch sử khám, nhận thông báo tái khám và có tra cứu kết quả cận lâm sàng trực tuyến.",
            "Xem lịch sử khám bệnh trên điện thoại và kết nối hồ sơ y tế khi thông tin trùng khớp.",
            "Có EMR chi tiết gồm ICD-10, triệu chứng, khám thực thể, xét nghiệm, ảnh chẩn đoán và chữ ký số.",
        ],
        [
            "Tư vấn từ xa",
            "Có gọi video với bác sĩ và tư vấn sức khỏe từ xa.",
            "Định hướng chăm sóc liên tục, cá nhân hóa và nội dung y tế tin cậy.",
            "Có màn Telemedicine mô phỏng cuộc gọi, chat trong phiên, kết thúc khám và tạo đơn thuốc.",
        ],
        [
            "Thanh toán và bảo hiểm",
            "Hỗ trợ thanh toán trực tuyến, hoàn tiền khi hủy khám và thanh toán viện phí.",
            "Tập trung vào trải nghiệm Vinmec, lịch hẹn và hồ sơ khách hàng.",
            "Có ví viện phí, auto-refund, bảo lãnh viện phí cashless, tính phần bảo hiểm chi trả và đồng chi trả.",
        ],
        [
            "Luồng nội bộ bác sĩ",
            "Tập trung nhiều vào phía người bệnh và kết nối cơ sở y tế.",
            "Tập trung vào khách hàng trong hệ sinh thái Vinmec.",
            "Có bàn làm việc bác sĩ, gọi số, kê đơn, ghi hồ sơ, kiểm tra dị ứng, tương tác thuốc và ký số EMR.",
        ],
        [
            "Backend và phân quyền",
            "Không công bố chi tiết kỹ thuật backend trong tài liệu người dùng.",
            "Không công bố chi tiết kỹ thuật backend trong tài liệu người dùng.",
            "Có backend riêng, JWT, refresh token, RBAC server-side, audit log, OpenAPI và integration test.",
        ],
    ]
    add_table(doc, ["Tiêu chí", "Medpro", "MyVinmec", "MedCare"], comparison_rows, [3.0, 4.5, 4.2, 4.3])

    add_heading(doc, "9 Điểm nổi trội và hướng phát triển tương lai")
    add_paragraph(
        doc,
        "Các điểm nổi trội của MedCare nên được phát triển theo hướng bổ sung chiều sâu lâm sàng và khả năng vận hành bệnh viện, thay vì chỉ dừng ở đặt lịch hoặc xem hồ sơ. "
        "Nếu hoàn thiện đúng hướng, MedCare có thể trở thành mô hình ứng dụng kết hợp patient app, doctor workstation và hospital operation dashboard.",
    )
    future_rows = [
        [
            "Điểm nổi trội hiện có",
            "Bàn làm việc bác sĩ tích hợp gọi số, ghi nhận sinh hiệu, kê đơn, chỉ định xét nghiệm, kiểm tra tương tác thuốc và ký số EMR.",
            "Biến app từ công cụ bệnh nhân thành hệ thống hai chiều giữa bệnh nhân và bác sĩ.",
        ],
        [
            "Điểm nổi trội hiện có",
            "Clinical Pathway Tracker theo dõi lộ trình khám từng bước, vị trí phòng khám, dặn dò bác sĩ và trạng thái hoàn thành.",
            "Giúp người bệnh biết phải làm gì tiếp theo trong quy trình khám, giảm lạc quy trình và giảm hỏi quầy tiếp nhận.",
        ],
        [
            "Điểm nổi trội hiện có",
            "Bảo lãnh viện phí cashless, ví viện phí và auto-refund.",
            "Mô phỏng nghiệp vụ tài chính bệnh viện mà nhiều app đặt khám đơn thuần chưa thể hiện sâu.",
        ],
        [
            "Phát triển tương lai",
            "Nối đăng nhập Flutter trực tiếp với backend, lưu token an toàn, tự refresh token và logout khi phiên hết hạn.",
            "Hoàn thiện trải nghiệm đăng nhập thật, tránh cấu hình thủ công bằng dart-define.",
        ],
        [
            "Phát triển tương lai",
            "Tích hợp HL7 FHIR cho hồ sơ bệnh án, đơn thuốc, xét nghiệm, lịch hẹn và thông tin bệnh nhân.",
            "Giúp hệ thống dễ kết nối HIS/LIS/PACS và chuẩn hóa trao đổi dữ liệu y tế.",
        ],
        [
            "Phát triển tương lai",
            "Bổ sung AI triage và chatbot y tế có kiểm soát, phân loại triệu chứng ban đầu, gợi ý chuyên khoa và cảnh báo đi cấp cứu khi cần.",
            "Tăng giá trị trước khám nhưng vẫn giữ nguyên tắc không thay thế chẩn đoán của bác sĩ.",
        ],
        [
            "Phát triển tương lai",
            "Đồng bộ thiết bị đeo và IoT y tế như huyết áp, SpO2, đường huyết, nhịp tim, cân nặng.",
            "Chuyển theo dõi sinh hiệu từ nhập tay sang dữ liệu liên tục, hỗ trợ bác sĩ theo dõi bệnh mạn tính.",
        ],
        [
            "Phát triển tương lai",
            "Mã hóa SQLite at-rest bằng SQLCipher, bổ sung secure storage cho token và chính sách khóa app nâng cao.",
            "Tăng bảo mật dữ liệu y tế cá nhân trên thiết bị.",
        ],
        [
            "Phát triển tương lai",
            "Realtime đa kênh bằng WebSocket/SSE/Firebase cho hàng đợi, thông báo thuốc, kết quả xét nghiệm và gọi vào phòng khám.",
            "Cập nhật tức thời thay vì người dùng phải tự tải lại màn hình.",
        ],
        [
            "Phát triển tương lai",
            "Dashboard quản trị vận hành gồm tải phòng khám, thời gian chờ, tỷ lệ hủy lịch, hiệu suất bác sĩ và cảnh báo quá tải.",
            "Hỗ trợ bệnh viện điều phối nguồn lực dựa trên dữ liệu.",
        ],
    ]
    add_table(doc, ["Nhóm", "Nội dung nổi trội hoặc hướng phát triển", "Giá trị mang lại"], future_rows, [3.2, 7.6, 5.2])

    add_heading(doc, "10 Nguồn tham khảo so sánh")
    source_rows = [
        [
            "Medpro",
            "Trang giới thiệu và hướng dẫn đặt lịch khám online, lấy số thứ tự, thanh toán, lịch sử khám, tái khám, tư vấn từ xa, xét nghiệm, y tế tại nhà.",
            "https://medpro.vn/ và https://medpro.vn/tin-tuc/dat-lich-kham-lay-so-thu-tu-tren-medpro",
        ],
        [
            "MyVinmec",
            "Trang giới thiệu MyVinmec và hướng dẫn khai báo trước khám, hồ sơ cá nhân/người thân, lịch sử khám, mã khách hàng và kết nối hồ sơ y tế.",
            "https://www.vinmec.com/vie/bai-viet/my-vinmec-ung-dung-dien-thoai-giup-quan-ly-tron-ven-suc-khoe-ca-nhan-va-gia-dinh-vi",
        ],
    ]
    add_table(doc, ["Ứng dụng", "Nội dung tham khảo", "Nguồn"], source_rows, [3.0, 7.0, 6.0])

    add_heading(doc, "11 Mức độ hoàn thiện và hướng phát triển")
    add_paragraph(
        doc,
        "Hệ thống hiện đạt mức production-style khoảng 85 đến 88 phần trăm. Ứng dụng không còn chỉ là giao diện demo vì đã có backend, "
        "API contract, phân quyền server-side, realtime queue và kiểm thử tích hợp. Tuy nhiên để đạt 100 phần trăm production thật, "
        "cần bổ sung các hạng mục triển khai và bảo mật ở mức vận hành.",
    )
    add_bullets(
        doc,
        [
            "Nối màn hình đăng nhập Flutter trực tiếp với backend để tự nhận và lưu token thay vì cấu hình thủ công bằng dart-define.",
            "Mã hóa SQLite cục bộ at-rest bằng SQLCipher hoặc giải pháp native tương đương.",
            "Tách database server production như PostgreSQL hoặc MySQL nếu triển khai nhiều máy khách và cần backup tập trung.",
            "Bổ sung Docker, HTTPS reverse proxy, CI/CD, monitoring, log rotation và chính sách backup.",
            "Chạy E2E test trên emulator hoặc thiết bị thật, bao gồm đăng nhập, đặt lịch, gọi số, kê đơn và đồng bộ.",
            "Hoàn thiện chính sách bảo mật y tế như consent, data retention, audit policy, phân quyền theo khoa/phòng và quản lý phiên đăng nhập.",
        ],
    )

    add_heading(doc, "12 Kết luận")
    add_paragraph(
        doc,
        "MedCare đáp ứng tốt phạm vi của đề tài ứng dụng bệnh viện đa nền tảng: có nhiều phân hệ nghiệp vụ, luồng xử lý tương đối sát thực tế, "
        "giao diện tối ưu cho mobile và nền backend/API đủ để chứng minh đăng nhập, phân quyền, đồng bộ và realtime queue. "
        "Nếu tiếp tục hoàn thiện các hạng mục triển khai production, hệ thống có thể phát triển thành một nền tảng quản lý bệnh viện và chăm sóc người bệnh hoàn chỉnh hơn.",
    )

    doc.core_properties.title = "Chi tiết chức năng đề tài MedCare"
    doc.core_properties.subject = "Báo cáo chức năng ứng dụng bệnh viện"
    doc.core_properties.author = "Nguyễn Hoàng Vũ"
    doc.save(OUT)
    print(OUT)


if __name__ == "__main__":
    main()
