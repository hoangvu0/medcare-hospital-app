from docx import Document

SOURCE = r"C:\Users\hoangvu\Downloads\2324801030027_2324801030077_2324801030052_Nhom09_XayDungUngDungHoTroKhamBenhVaChamSocSucKhoeBangFlutter.docx"
OUTPUT = r"C:\Users\hoangvu\Downloads\2324801030027_2324801030077_2324801030052_Nhom09_XayDungUngDungHoTroKhamBenhVaChamSocSucKhoeBangFlutter_cap_nhat.docx"

doc = Document(SOURCE)

replacements = {
    "UC05 Thanh toán mô phỏng và xác nhận lịch":
        "UC05 Thanh toán, đối soát và xác nhận lịch",
    "Các giao dịch thanh toán, khám video, gửi đơn lên cổng quốc gia và ký số EMR được trình bày theo đúng mức độ mô phỏng trong mã nguồn. Việc vận hành trên dữ liệu y tế thật cần tiếp tục hoàn thiện cơ chế bảo vệ dữ liệu, tích hợp nhà cung cấp và kiểm thử trên thiết bị thực tế.":
        "Thanh toán đã có luồng VietQR theo số tiền giao dịch, ghi nhận yêu cầu xác nhận và cơ chế admin duyệt thủ công khi chưa cấu hình webhook. Đăng ký gói tầm soát và tiêm chủng được gửi thành yêu cầu dịch vụ về backend. Khám video, gửi đơn lên cổng quốc gia và chữ ký số có chứng thư vẫn cần tích hợp nhà cung cấp bên ngoài trước khi vận hành trên dữ liệu y tế thật.",
    "Phạm vi gồm xác thực, đặt lịch, giao dịch mô phỏng, bệnh án, đơn thuốc, sinh hiệu, nhắc thuốc và hàng đợi. Chưa triển khai HIS/LIS/PACS đầy đủ, thanh toán qua nhà cung cấp, gọi video thật hoặc chữ ký số có chứng thư.":
        "Phạm vi gồm xác thực OTP, đặt lịch, gói khám, tiêm chủng, thanh toán VietQR chờ admin duyệt, bệnh án, đơn thuốc, sinh hiệu, nhắc thuốc, thông báo và hàng đợi. Chưa triển khai HIS/LIS/PACS đầy đủ, webhook ngân hàng thật, gọi video thật hoặc chữ ký số có chứng thư.",
    "Các cổng thanh toán và chữ ký số thật chưa được tích hợp trong phiên bản hiện tại.":
        "Cổng thanh toán tự động và chữ ký số có chứng thư chưa được tích hợp; phiên bản hiện tại dùng VietQR cấu hình tài khoản và cơ chế admin đối soát thủ công.",
    "Trong client hiện tại, book thao tác trên MedicalStore và lưu SQLite, không trực tiếp gọi POST /appointments. Backend có endpoint tạo lịch độc lập; cần bổ sung repository chung nếu muốn các lịch client trở thành bản ghi nghiệp vụ trên máy chủ.":
        "Khi có cấu hình backend, bookOnlineFirst gọi POST /appointments, lưu lịch và giao dịch pending trên SQLite máy chủ; lịch có phí ở trạng thái awaiting_payment cho tới khi cổng thanh toán hoặc admin duyệt. Chế độ không cấu hình backend chỉ được dùng cho kiểm thử cục bộ.",
    "Màn hình viện phí hiển thị khoản phải trả, phần bảo hiểm và phương thức thanh toán. Xác nhận giao dịch thành công trong nguyên mẫu chuyển lịch hẹn liên quan sang confirmed. Các nhãn VietQR, MoMo, ZaloPay, VNPay hoặc thẻ thể hiện lựa chọn giao diện; chưa có quy trình xác thực và đối soát giao dịch với nhà cung cấp.":
        "Màn hình viện phí hiển thị đúng số tiền giao dịch, mã nội dung chuyển khoản và QR VietQR theo tài khoản nhận tiền được cấu hình. Khi chưa có webhook, bệnh nhân gửi yêu cầu xác nhận; admin kiểm tra giao dịch rồi duyệt hoặc từ chối trên màn hình Duyệt nghiệp vụ. Chỉ khi duyệt thành công lịch mới chuyển confirmed và mở mã QR check-in/số thứ tự. Webhook tự động của ngân hàng vẫn là phần cần tích hợp thêm.",
    "Một số nút mở nhóm chức năng chuyên sâu hoặc ghi nhận audit. Phát hành EMR cần lịch confirmed; tạo chuỗi token ký trong store hiện là mô phỏng, chưa có chứng thư và cơ chế xác minh chữ ký số độc lập.":
        "Bàn làm việc bác sĩ tổ chức tiếp nhận, sinh hiệu, khám và ICD-10, cận lâm sàng, hình ảnh, đơn thuốc, ký và đồng bộ EMR, theo dõi theo khoa, hội chẩn, tái khám và gửi lời dặn. Mỗi thao tác được gửi về backend theo patient_id và appointment_id, đồng thời tạo notification cho bệnh nhân. Ký EMR hiện dùng HMAC-SHA256 phía backend; chưa thay thế chữ ký số có chứng thư PKI.",
    "Quản trị slot khám cho phép theo dõi khung giờ theo bác sĩ và điều chỉnh capacity. Số booked và số chỗ còn lại hỗ trợ minh họa điều phối lịch. Route của màn hình được bảo vệ bằng vai trò admin; phần quản lý slot hiện gắn với kho trạng thái và SQLite client, chưa có bộ API CRUD slot riêng.":
        "Quản trị viên có thể theo dõi lịch, tài khoản, bác sĩ, doanh thu, audit, hồ sơ lâm sàng, yêu cầu dịch vụ và duyệt thanh toán. Quản lý slot theo bác sĩ có capacity, booked, số còn lại và trạng thái; các API nhạy cảm được bảo vệ bằng JWT và RBAC.",
    "Đề tài đã xây dựng nguyên mẫu MedCare với giao diện Flutter theo ba vai trò. Các chức năng chính liên kết thành quy trình từ đặt lịch, thanh toán mô phỏng và xác nhận lịch đến khám, phát hành bệnh án và đơn thuốc. Lớp MedicalStore tập trung quy tắc nghiệp vụ; MedicalDatabase lưu các nhóm dữ liệu cục bộ và AppSettingsStore quản lý trải nghiệm sử dụng.":
        "Đề tài đã xây dựng ứng dụng MedCare với giao diện Flutter theo ba vai trò. Quy trình liên kết từ đăng ký OTP, đặt lịch và chọn gói khám đến thanh toán VietQR, admin đối soát, cấp số, khám, phát hành bệnh án, đơn thuốc và thông báo về bệnh nhân. MedicalStore tập trung quy tắc nghiệp vụ; MedicalDatabase lưu dữ liệu cục bộ; backend Dart/SQLite lưu dữ liệu dùng chung giữa Chrome và Android.",
    "Một số tính năng mới dừng ở mức mô phỏng, đặc biệt là thanh toán, gọi video, ký số và gửi cổng đơn thuốc. Đồng bộ snapshot chưa tạo được cơ chế hợp nhất dữ liệu giữa các thiết bị. Phân tách hồ sơ theo tài khoản, lưu token an toàn và kiểm soát truy cập bản ghi cần được hoàn thiện. MedicalStore có phạm vi lớn nên việc bảo trì và kiểm tra tác động thay đổi còn khó khăn.":
        "Thanh toán tự động qua webhook, gọi video, ký số PKI, kết nối LIS/PACS và gửi đơn thuốc quốc gia vẫn cần dịch vụ bên ngoài. Tuy nhiên, phiên bản hiện tại đã có backend dùng chung cho lịch, payment pending, admin duyệt thủ công, clinical actions, hồ sơ, đơn thuốc, file y tế và notification. Khi triển khai production cần tiếp tục hoàn thiện bảo mật, HTTPS, secure storage, sao lưu và kiểm thử tải.",
    "[5] Mã nguồn MedCare. pubspec.yaml; lib/main.dart; lib/models/medical_models.dart; lib/state/medical_store.dart; lib/data/medical_database.dart; lib/data/medical_api_client.dart. Phiên bản được khảo sát ngày 19/10/2026.":
        "[5] Mã nguồn MedCare. pubspec.yaml; lib/main.dart; lib/models/medical_models.dart; lib/state/medical_store.dart; lib/data/medical_database.dart; lib/data/medical_api_client.dart. Phiên bản được khảo sát ngày 29/10/2026.",
    "[6] MedCare Backend. server/bin/server.dart; server/openapi.yaml; server/README.md và server/test/backend_api_test.dart. Phiên bản được khảo sát ngày 19/10/2026.":
        "[6] MedCare Backend. server/bin/server.dart; server/openapi.yaml; server/README.md và server/test/backend_api_test.dart. Phiên bản được khảo sát ngày 29/10/2026.",
}

for paragraph in doc.paragraphs:
    if paragraph.text in replacements:
        paragraph.text = replacements[paragraph.text]

# Some headings contain tabs/line breaks from the original Word layout; update
# these known sections by their stable paragraph positions as well.
direct_updates = {
    72: "UC05 Thanh toán, đối soát và xác nhận lịch",
    129: "Sản phẩm hướng đến phạm vi đồ án học phần. Thanh toán đã có QR theo số tiền giao dịch, yêu cầu xác nhận và quy trình admin duyệt thủ công khi chưa có webhook. Đăng ký gói tầm soát và tiêm chủng được gửi về backend để admin tiếp nhận. Khám video, gửi đơn lên cổng quốc gia và chữ ký số có chứng thư vẫn cần tích hợp dịch vụ bên ngoài.",
    175: "Ranh giới hệ thống gồm ứng dụng Flutter và backend MedCare. Ba tác nhân chính là bệnh nhân, bác sĩ và quản trị viên. Gemini, RSS/API tin tức và QR thanh toán là các dịch vụ tích hợp; webhook ngân hàng, video thật, LIS/PACS và chữ ký số có chứng thư vẫn là phần mở rộng production.",
    268: "Bàn làm việc bác sĩ tổ chức tiếp nhận, sinh hiệu, khám và ICD-10, cận lâm sàng, hình ảnh, đơn thuốc, ký và đồng bộ EMR, theo dõi theo khoa, hội chẩn, tái khám và gửi lời dặn. Mỗi thao tác được gửi về backend theo bệnh nhân và lịch hẹn, đồng thời tạo notification cho bệnh nhân. Ký EMR dùng HMAC-SHA256 phía backend; chưa thay thế chữ ký số PKI.",
    271: "Các tiện ích mở rộng gồm tin tức y khoa từ nhiều nguồn, gói tầm soát, tiêm chủng, hồ sơ gia đình, bảo lãnh viện phí, trợ lý AI, thông báo chuông, QR check-in, theo dõi sinh hiệu và các màn hình hỗ trợ sức khỏe. Những thao tác cần backend hiển thị trạng thái kết nối để phân biệt dữ liệu máy chủ và dữ liệu cục bộ.",
}
for index, text in direct_updates.items():
    if index < len(doc.paragraphs):
        doc.paragraphs[index].text = text

# Update compact tables that describe the current workflows.
for table in doc.tables:
    for row in table.rows:
        cells = [cell.text for cell in row.cells]
        if cells and cells[0] == "UC05":
            row.cells[1].text = "Thanh toán và xác nhận lịch"
            row.cells[3].text = "Giao dịch pending được xác minh; admin có thể duyệt thủ công; lịch chuyển confirmed."
        if cells and cells[0] == "Tiêm chủng, gói khám":
            row.cells[1].text = "Tra cứu danh mục, gửi đăng ký gói về backend và theo dõi xử lý."
            row.cells[2].text = "Có API yêu cầu dịch vụ, mã yêu cầu và khu vực admin xử lý."
        if cells and cells[0] == "Tin tức sức khỏe":
            row.cells[1].text = "Đọc bài viết bệnh viện, y tế và nghiên cứu khoa học từ RSS/API."
            row.cells[2].text = "Có API /news, bộ nhớ đệm và nguồn dự phòng."
        if cells and cells[0] == "Giao thuốc, bảo lãnh":
            row.cells[1].text = "Tạo yêu cầu, gửi backend và theo dõi trạng thái."
        if cells and cells[0] == "payment_transactions.visit_code":
            row.cells[2].text = "Liên hệ logic đến mã giao dịch và mã lịch khám."

# Fill the previously empty extension-screen paragraph.
for paragraph in doc.paragraphs:
    if paragraph.text.strip() == "" and paragraph._p.getprevious() is not None:
        previous = paragraph._p.getprevious()
        if previous is not None and "4.5. Các màn hình" in ''.join(previous.itertext()):
            paragraph.text = (
                "Các tiện ích mở rộng gồm tin tức y khoa từ nhiều nguồn, gói tầm soát, tiêm chủng, "
                "hồ sơ gia đình, bảo lãnh viện phí, trợ lý AI, thông báo chuông, QR check-in, "
                "theo dõi sinh hiệu và các màn hình hỗ trợ sức khỏe. Những thao tác cần backend "
                "đều hiển thị trạng thái kết nối hoặc lỗi để người dùng phân biệt dữ liệu thật và dữ liệu cục bộ."
            )
            break

doc.save(OUTPUT)
print(OUTPUT)
