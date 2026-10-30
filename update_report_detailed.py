from copy import deepcopy
from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.shared import Inches, Pt
from docx.text.paragraph import Paragraph
from docx.oxml import OxmlElement


BASE = Path(r"C:\Users\hoangvu\Downloads\2324801030027_2324801030077_2324801030052_Nhom09_XayDungUngDungHoTroKhamBenhVaChamSocSucKhoeBangFlutter_cap_nhat.docx")
OUTPUT = Path(r"C:\Users\hoangvu\Downloads\2324801030027_2324801030077_2324801030052_Nhom09_XayDungUngDungHoTroKhamBenhVaChamSocSucKhoeBangFlutter_ban_cuoi.docx")

IMG_ADMIN = Path(r"C:\Users\hoangvu\Pictures\Screenshots\Screenshot (1873).png")
IMG_DOCTOR = Path(r"C:\Users\hoangvu\Pictures\Screenshots\Screenshot (1874).png")
IMG_PAYMENT = Path(r"C:\Users\hoangvu\AppData\Local\Temp\codex-clipboard-4d2247f0-0256-4b67-adce-7cdd2cc16de0.png")
IMG_NOTIFICATION = Path(r"C:\Users\hoangvu\AppData\Local\Temp\codex-clipboard-0064f444-b50d-4fe4-9312-62ee9b8bbbb3.png")
IMG_LOGIN = Path(r"C:\Users\hoangvu\AppData\Local\Temp\codex-clipboard-c5c16d98-6b54-4067-a111-d14915f8eb2b.png")
IMG_REGISTER = Path(r"C:\Users\hoangvu\AppData\Local\Temp\codex-clipboard-85290dd5-82ec-4bba-bce6-37b5ee17a517.png")


def set_text(doc, index, text):
    if index < len(doc.paragraphs):
        doc.paragraphs[index].text = text


def insert_paragraph_before(anchor, text="", bold=False, size=None, style=None):
    new_p = OxmlElement("w:p")
    anchor._p.addprevious(new_p)
    paragraph = Paragraph(new_p, anchor._parent)
    if style:
        paragraph.style = style
    run = paragraph.add_run(text)
    run.bold = bold
    if size:
        run.font.size = Pt(size)
    return paragraph


def insert_image_before(anchor, image_path, caption):
    paragraph = insert_paragraph_before(anchor)
    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = paragraph.add_run()
    run.add_picture(str(image_path), width=Inches(6.0))
    cap = insert_paragraph_before(anchor, caption)
    cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
    for run in cap.runs:
        run.italic = True
        run.font.size = Pt(10)


def remove_paragraph(paragraph):
    element = paragraph._element
    element.getparent().remove(element)


doc = Document(str(BASE))

# Cập nhật danh mục hình ở đầu báo cáo theo ảnh đăng nhập/đăng ký mới.
set_text(doc, 115, "Hình 4.1. Màn hình đăng nhập cập nhật\t20")
set_text(doc, 116, "Hình 4.2. Màn hình đăng ký cập nhật\t20")

# Chương 1: làm rõ bài toán, đối tượng sử dụng, phạm vi và tiêu chí đánh giá.
set_text(doc, 135, """Trong thực tế, người bệnh thường phải thực hiện nhiều bước rời rạc: tìm bác sĩ, gọi điện đặt lịch, xếp hàng, thanh toán, nhận kết quả và theo dõi sau khám. Dữ liệu bị phân tán làm tăng nguy cơ nhập sai thông tin, thất lạc kết quả và khiến bệnh nhân không biết trạng thái xử lý. Ứng dụng MedCare được xây dựng để gom các bước này vào một quy trình thống nhất, có xác thực tài khoản, phân quyền theo vai trò và đồng bộ qua backend dùng chung.""")
set_text(doc, 136, """Bài toán của đề tài không chỉ là tạo giao diện đặt lịch mà còn là bảo đảm tính liên tục của dữ liệu: một lịch hẹn phải liên kết được với bệnh nhân, bác sĩ, gói khám, giao dịch, số thứ tự, hồ sơ bệnh án và thông báo. Vì vậy, thiết kế được chia thành ba lớp: Flutter client cho trải nghiệm người dùng, REST API Dart cho nghiệp vụ trung tâm và SQLite cho lưu trữ có cấu trúc. Khi chạy đồng thời Chrome và Android, hai thiết bị cùng đọc/ghi dữ liệu máy chủ thay vì tạo hai bản dữ liệu độc lập.""")
set_text(doc, 138, """Mục tiêu tổng quát là xây dựng một nền tảng hỗ trợ khám bệnh có thể dùng thử theo quy trình thật ở mức đồ án: bệnh nhân đăng ký và xác thực, tìm bác sĩ, chọn lịch hoặc gói dịch vụ, gửi thanh toán, nhận số thứ tự và thông báo; bác sĩ tiếp nhận, ghi nhận sinh hiệu, khám, kê đơn, cập nhật bệnh án; admin điều phối tài khoản, lịch, giao dịch, yêu cầu dịch vụ và nhật ký. Mọi chức năng phải có trạng thái thành công, chờ xử lý hoặc lỗi, không chỉ là nút chuyển màn hình.""")
set_text(doc, 145, """Phạm vi triển khai bao gồm: đăng nhập/đăng ký OTP; quản lý hồ sơ bệnh nhân; danh sách bác sĩ và chuyên khoa; lịch hẹn và hàng đợi; gói khám tầm soát, tiêm chủng; QR thanh toán theo đúng số tiền; duyệt thủ công khi chưa có webhook; bệnh án, sinh hiệu, xét nghiệm, hình ảnh, đơn thuốc; thông báo chuông; cổng bác sĩ; cổng quản trị; audit log và hỗ trợ AI. Các dịch vụ bên ngoài như SMS, email SMTP, ngân hàng, LIS/PACS, WebRTC, bảo hiểm và đơn thuốc quốc gia được tách thành điểm tích hợp rõ ràng để không làm sai luồng nội bộ.""")
set_text(doc, 147, """Phương pháp thực hiện gồm khảo sát nghiệp vụ, thiết kế use case và mô hình dữ liệu, phát triển theo từng vai trò, kiểm thử API, kiểm thử giao diện responsive và chạy thử đồng thời trên Chrome/Android. Tiêu chí kiểm thử chính là: dữ liệu tạo ở thiết bị bệnh nhân phải xuất hiện ở admin/bác sĩ; thay đổi lâm sàng phải tạo thông báo cho bệnh nhân; số thứ tự phải lấy theo lịch và phòng; thanh toán chưa xác nhận không được tự chuyển thành công; bản ghi sai vai trò phải bị chặn bởi JWT/RBAC.""")
set_text(doc, 148, """Kết quả đánh giá dựa trên các ca kiểm thử đại diện: đăng ký tài khoản mới không lấy nhầm hồ sơ cũ; đặt lịch tạo appointment và payment pending; admin duyệt giao dịch làm lịch chuyển confirmed; bác sĩ gọi số, nhập vitals, chẩn đoán, kê đơn và ký gửi; bệnh nhân nhận notification và xem lại bệnh án. Những phần phụ thuộc nhà cung cấp bên ngoài được ghi rõ là điểm cấu hình, không đánh đồng với dữ liệu production.""")

# Chương 2: giải thích công nghệ theo vai trò trong hệ thống.
set_text(doc, 154, """Flutter được chọn vì cho phép dùng chung một codebase cho Android và web, đồng thời hỗ trợ responsive layout. Ứng dụng tổ chức theo màn hình/route, model dữ liệu, state store và lớp API. MedicalStore giữ trạng thái phiên đăng nhập, hồ sơ và quy tắc chuyển trạng thái; MedicalApiClient đóng gói request, token và lỗi; các màn hình bệnh nhân, bác sĩ và admin chỉ gọi nghiệp vụ thông qua các lớp này để tránh trộn giao diện với truy cập dữ liệu.""")
set_text(doc, 155, """Đối với màn hình rộng, cổng admin và bác sĩ dùng bố cục dashboard, bảng và thanh điều hướng; đối với Android, cổng bệnh nhân dùng thẻ, bottom navigation và các bước tuần tự. Các trạng thái loading, empty, unauthorized, expired token và server error được biểu diễn riêng. Đây là cơ sở để chạy đồng thời Chrome và emulator mà vẫn giữ cùng một hợp đồng dữ liệu.""")
set_text(doc, 159, """SQLite được dùng ở backend để lưu dữ liệu nghiệp vụ có cấu trúc và có thể truy vấn theo user_id, doctor_id, appointment_id, status và thời gian. Các bảng cốt lõi gồm users, doctors, appointments, payment_transactions, queue_tickets, medical_records, prescriptions, clinical_actions, notifications, support_requests, uploaded_files và audit_logs. Dữ liệu nhạy cảm không nên chỉ nằm trong bộ nhớ giao diện; backend là nguồn dữ liệu chung khi chạy nhiều thiết bị.""")
set_text(doc, 160, """Các thao tác có ảnh hưởng trạng thái được xử lý theo transaction hoặc kiểm tra điều kiện trước khi ghi: không cho đặt lịch khi slot hết chỗ, không cho duyệt hai lần một giao dịch, không cho bác sĩ ghi dữ liệu nếu chưa chọn lịch, không cho bệnh nhân xem hồ sơ của người khác và không cho role thường gọi endpoint admin. Trường status được chuẩn hóa để frontend hiển thị đúng “chờ thanh toán”, “chờ admin duyệt”, “đã xác nhận”, “từ chối” hoặc “đã hủy”.""")
set_text(doc, 161, """SQLite của client chỉ phục vụ cache và trải nghiệm offline có kiểm soát. Khi có backend, dữ liệu cần đồng bộ bằng API và client phải hiển thị thời điểm cập nhật. Quy tắc này ngăn lỗi thường gặp khi bệnh nhân thấy một trạng thái cũ trong máy nhưng admin đã xử lý trên Chrome.""")
set_text(doc, 165, """REST API dùng HTTP JSON với nhóm endpoint theo nghiệp vụ: /auth, /doctors, /appointments, /payments, /queue, /clinical, /medical-records, /prescriptions, /notifications, /support/requests, /files, /admin và /news. Mỗi request được kiểm tra Authorization Bearer JWT; response lỗi trả mã HTTP và thông báo để giao diện hiển thị nguyên nhân, thay vì coi mọi response là thành công.""")
set_text(doc, 167, """JWT access token dùng cho request ngắn hạn; refresh token được lưu riêng và có endpoint cấp lại phiên. Middleware xác định user_id, role và các claim cần thiết. Quyền được kiểm tra ở backend theo nguyên tắc tối thiểu: patient chỉ thao tác dữ liệu của mình, doctor thao tác ca được phân công, admin điều hành nghiệp vụ và xem audit.""")
set_text(doc, 168, """SSE được dùng cho queue dispatch và cập nhật theo thời gian gần thực; notification vẫn được lưu bền vững để bệnh nhân có thể mở chuông sau khi offline. Gemini/Infermedica, RSS tin tức và VietQR là adapter độc lập. Nếu adapter không cấu hình hoặc timeout, hệ thống trả trạng thái rõ ràng và không tự ghi dữ liệu giả vào hồ sơ.""")

# Chương 3: bổ sung mô hình nghiệp vụ, luồng và dữ liệu.
set_text(doc, 181, """Use case được chia theo ba vai trò. Bệnh nhân bắt đầu từ đăng ký/đăng nhập, tìm bác sĩ hoặc gói dịch vụ, chọn slot, thanh toán và nhận thông báo/số thứ tự. Bác sĩ nhận ca đã xác nhận, tiếp nhận bệnh nhân, nhập sinh hiệu, khám theo ICD-10, chỉ định cận lâm sàng, kê đơn, ký và gửi kết quả. Admin duyệt tài khoản/nghiệp vụ, quản lý bác sĩ-slot, đối soát thanh toán, theo dõi audit và điều hành toàn hệ thống.""")
set_text(doc, 196, """Luồng đăng nhập gồm nhập email/số điện thoại và mật khẩu, gửi POST /auth/login, nhận access/refresh token, tải /auth/me rồi điều hướng theo role. Luồng đăng ký gồm nhập hồ sơ, request OTP, xác minh OTP, tạo user và khởi tạo patient profile. Khi đổi tài khoản, client thay toàn bộ profile theo patient_id mới và xóa cache dân số cũ để tránh hiện sai tên, tuổi hoặc mã bệnh nhân.""")
set_text(doc, 199, """Luồng đặt lịch gồm: bệnh nhân chọn bác sĩ/chuyên khoa và slot còn chỗ; client gửi POST /appointments; backend kiểm tra slot, capacity, lịch trùng và trạng thái tài khoản; nếu có phí thì tạo payment pending; bệnh nhân xem QR đúng số tiền và gửi yêu cầu xác nhận; admin đối soát rồi approve/reject; approve tạo hoặc kích hoạt queue ticket và gửi notification. Số thứ tự không tự lấy từ số hiển thị trên giao diện mà do backend cấp theo phòng, ngày và appointment.""")
set_text(doc, 202, """Mô hình dữ liệu được thiết kế quanh appointment_id. users xác định người dùng và vai trò; doctors mở rộng hồ sơ chuyên khoa; appointments liên kết patient, doctor, slot, package và payment; queue_tickets liên kết appointment với phòng và số thứ tự; clinical_actions lưu từng thao tác lâm sàng; medical_records và prescriptions là kết quả phát hành; notifications thông báo thay đổi; audit_logs ghi actor, action, entity, thời gian và metadata.""")
set_text(doc, 203, """Các quan hệ quan trọng là một bệnh nhân có nhiều lịch hẹn, một bác sĩ có nhiều lịch/ca khám, một lịch có tối đa một giao dịch chính và một số thứ tự, nhưng có thể có nhiều clinical_actions, file và notification. Dữ liệu phải tham chiếu bằng ID ổn định, không tham chiếu bằng tên hiển thị, để khi bệnh nhân đổi tên hoặc bác sĩ đổi lịch hệ thống không làm mất liên kết.""")
set_text(doc, 214, """Schema được chuẩn hóa để phục vụ truy vấn và audit. Mọi bảng nghiệp vụ có khóa chính, created_at, updated_at và status phù hợp; các file lớn được tách thành uploaded_files với mime_type, size, checksum và đường dẫn; dữ liệu xét nghiệm/hình ảnh lưu metadata và trạng thái ký, còn nội dung thật có thể đưa lên object storage khi triển khai production.""")
set_text(doc, 221, """appointments lưu patient_id, doctor_id, package_id, slot_id, start_at, room, reason, status, fee và payment_id. Các trạng thái điển hình là requested, awaiting_payment, pending_admin_review, confirmed, checked_in, in_progress, completed, cancelled và rejected. Chuyển trạng thái phải được backend kiểm tra theo vai trò và trạng thái trước đó.""")
set_text(doc, 222, """Khi lịch chuyển confirmed, backend tạo notification và có thể tạo queue ticket theo chính sách phòng khám. Khi bác sĩ gọi số, ticket chuyển called/in_service; khi kết thúc khám, appointment chuyển completed sau khi lưu bệnh án/đơn thuốc. Nhờ vậy bệnh nhân và bác sĩ nhìn cùng một tiến trình, không tự sinh hai số thứ tự khác nhau.""")
set_text(doc, 233, """Đồng bộ gồm pull theo user/role, refresh thủ công và SSE cho queue. Mỗi bản ghi trả updated_at/version để client biết dữ liệu mới hơn. Notification được ghi ngay tại backend sau các sự kiện: lịch được ghi nhận, thanh toán được duyệt, bác sĩ cập nhật bệnh án, đơn thuốc được gửi, lịch bị hủy hoặc có lịch tái khám.""")
set_text(doc, 234, """Trong trường hợp mất mạng, giao diện giữ bản nháp và báo chưa đồng bộ; không hiển thị bản nháp như hồ sơ chính thức. Khi kết nối lại, client gửi request có idempotency key để tránh tạo trùng lịch, trùng giao dịch hoặc trùng clinical action. Đây là điểm cần giữ khi mở rộng sang FCM và lưu trữ file thật.""")

# Chương 4: bổ sung ảnh chụp mới và phần thuyết minh theo màn hình thực tế.
anchor = doc.paragraphs[271]._p
anchor_para = Paragraph(anchor, doc.paragraphs[271]._parent)
insert_paragraph_before(anchor_para, "4.5.1. Ảnh cập nhật từ các vai trò vận hành", bold=True, size=13)
insert_paragraph_before(anchor_para, "Phần này cập nhật theo các màn hình đã chạy trên Chrome và Android Emulator. Ảnh minh họa thể hiện đúng ba vai trò và luồng đồng bộ: admin điều hành hàng đợi, bác sĩ thao tác EMR, bệnh nhân theo dõi thanh toán/thông báo.")
insert_image_before(anchor_para, IMG_DOCTOR, "Hình 4.9. Cổng bác sĩ: tiếp nhận ca, gọi số và nhập sinh hiệu trực tiếp theo lịch hẹn backend.")
insert_paragraph_before(anchor_para, "Cổng bác sĩ không chỉ là biểu mẫu nhập liệu. Bác sĩ chọn ca đã xác nhận, kiểm tra mã bệnh nhân và gói khám, gọi số tiếp theo, nhập huyết áp/nhịp tim/SpO2/nhiệt độ/cân nặng, chuyển bước khám, chỉ định cận lâm sàng, kê đơn, ký gửi EMR và tạo lời dặn. Mỗi bước gắn với appointment_id, được ghi audit và tạo thông báo cho bệnh nhân.")
insert_image_before(anchor_para, IMG_ADMIN, "Hình 4.10. Cổng admin: quản lý slot, phòng, bác sĩ phụ trách và hàng đợi đang chờ khám.")
insert_paragraph_before(anchor_para, "Cổng admin dùng để điều hành thay vì chỉ xem báo cáo: cấu hình bác sĩ/khoa/phòng, theo dõi capacity và số chỗ còn lại, điều phối hàng đợi, duyệt hoặc từ chối thanh toán thủ công, tiếp nhận yêu cầu gói tầm soát/tiêm chủng, xem audit và xử lý tài khoản. Đây là nơi xử lý khi các cổng ngân hàng, SMS hoặc email chưa cấu hình.")
insert_image_before(anchor_para, IMG_PAYMENT, "Hình 4.11. Luồng thanh toán: bệnh nhân gửi yêu cầu xác nhận và admin đối soát giao dịch pending.")
insert_paragraph_before(anchor_para, "Khi bệnh nhân đăng ký gói khám, số tiền được lấy từ gói đã chọn và hiển thị trong QR/nội dung chuyển khoản. Hệ thống không tự đánh dấu thành công chỉ vì người dùng mở màn hình QR. Bệnh nhân phải gửi yêu cầu xác nhận; admin kiểm tra sao kê hoặc bằng chứng giao dịch rồi duyệt. Sau khi duyệt, lịch chuyển confirmed, mã check-in và số thứ tự mới được cấp/hiển thị.")
insert_image_before(anchor_para, IMG_NOTIFICATION, "Hình 4.12. Chuông thông báo bệnh nhân: nhận cập nhật từ lịch hẹn, thanh toán và bác sĩ.")
insert_paragraph_before(anchor_para, "Thông báo được lưu ở backend theo user_id và hiển thị tại chuông của đúng bệnh nhân. Các sự kiện gồm lịch được ghi nhận, thanh toán được duyệt, lịch hủy, bác sĩ gửi bệnh án/đơn thuốc/lời dặn và lịch tái khám. Bệnh nhân có thể mở danh sách, đánh dấu đã đọc và tải lại để kiểm tra đồng bộ giữa emulator và Chrome.")

# Update the short chapter 4 descriptions to match the added figures.
set_text(doc, 250, """Màn hình đăng nhập/đăng ký là điểm vào của ba vai trò. Sau khi xác thực, hệ thống tải phiên từ backend và điều hướng theo patient, doctor hoặc admin; đăng ký mới tạo đúng hồ sơ theo tài khoản vừa xác minh, không dùng lại thông tin bệnh nhân trước đó.""")
set_text(doc, 251, """Trang chủ bệnh nhân hiển thị dịch vụ, bác sĩ nổi bật, lịch gần nhất, ví viện phí, gói khám, tin tức y khoa và chuông thông báo. Hình nền và thẻ thông tin được thiết kế responsive; dữ liệu động lấy từ API và có trạng thái rỗng/lỗi rõ ràng.""")
set_text(doc, 256, """Đặt lịch kiểm tra bác sĩ, slot, phòng, phí, gói dịch vụ và khả năng trùng lịch. Sau khi tạo, bệnh nhân xem tiến trình thanh toán; chỉ lịch đã được backend xác nhận mới đi vào hàng đợi và có số thứ tự.""")
set_text(doc, 262, """Bệnh án trình bày hồ sơ nhận dạng, dị ứng, BHYT, lịch sử khám, chẩn đoán, sinh hiệu, xét nghiệm, hình ảnh, đơn thuốc và lời dặn. Dữ liệu bác sĩ gửi về được gắn đúng bệnh nhân, cập nhật thời gian và báo qua chuông.""")
set_text(doc, 263, """Hàng đợi hiển thị số đang gọi, số tiếp theo, phòng và trạng thái. Số thứ tự được cấp ở backend theo ngày/phòng, vì vậy bệnh nhân và bác sĩ cùng thấy một giá trị khi chạy song song.""")

# Thay cụm ảnh cũ của mục 4.1 bằng hai ảnh giao diện mới: đăng nhập và đăng ký.
# Ảnh cũ được đặt trong một paragraph ghép; xóa cả paragraph ảnh và hai caption cũ
# rồi chèn lại theo thứ tự để Word không giữ ảnh lỗi thời.
if len(doc.paragraphs) > 250 and "Hình 4.1." in doc.paragraphs[248].text:
    remove_paragraph(doc.paragraphs[247])
    remove_paragraph(doc.paragraphs[247])
    remove_paragraph(doc.paragraphs[247])
    login_anchor = next(p for p in doc.paragraphs if p.text.startswith("Màn hình đăng nhập/đăng ký"))
    insert_image_before(login_anchor, IMG_LOGIN, "Hình 4.1. Màn hình đăng nhập cập nhật trên Chrome, có phân vai trò và xác thực phiên backend.")
    insert_image_before(login_anchor, IMG_REGISTER, "Hình 4.2. Màn hình đăng ký cập nhật, thu thập họ tên, điện thoại, email và mật khẩu trước bước OTP.")
    login_anchor.text = "Màn hình đăng nhập cho phép nhập email/số điện thoại hoặc mã bệnh nhân, mật khẩu, xem/ẩn mật khẩu và chuyển sang đăng ký mới. Sau khi xác thực, hệ thống tải phiên từ backend và điều hướng theo patient, doctor hoặc admin."
    # Giữ nguyên thứ tự hình gốc cho các nhóm đặt lịch, bệnh án, bác sĩ và admin.
    for p in doc.paragraphs:
        if p.text == "Hình 4.3. Màn hình đặt lịch khám bên trái":
            p.text = "Hình 4.3. Màn hình đặt lịch khám bên trái"
        elif p.text == "Hình 4.4. Màn hình thanh toán viện phí bên phải":
            p.text = "Hình 4.4. Màn hình thanh toán viện phí bên phải"
        elif p.text == "Hình 4.5. Màn hình hồ sơ bệnh án bên trái":
            p.text = "Hình 4.5. Màn hình hồ sơ bệnh án bên trái"
        elif p.text == "Hình 4.6. Màn hình hàng đợi khám bên phải":
            p.text = "Hình 4.6. Màn hình hàng đợi khám bên phải"

doc.save(str(OUTPUT))
print(OUTPUT)
