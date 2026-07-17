# 01. Tài liệu yêu cầu hệ thống CivicHub

## 1. Giới thiệu hệ thống

CivicHub là hệ thống hỗ trợ tiếp nhận, quản lý và theo dõi phản ánh của cộng đồng về các vấn đề phát sinh trong đời sống đô thị, khu dân cư hoặc địa phương như hạ tầng hư hỏng, vệ sinh môi trường, an ninh trật tự, chiếu sáng công cộng và các vấn đề tương tự.

Hệ thống gồm ba thành phần chính:

- Ứng dụng Flutter Mobile dành cho người dân gửi và theo dõi phản ánh.
- Trang React Admin dành cho nhân viên xử lý và quản trị viên quản lý dữ liệu.
- Backend Spring Boot kết nối PostgreSQL để lưu trữ và xử lý nghiệp vụ.

Trong phiên bản MVP, CivicHub tập trung vào luồng nghiệp vụ cốt lõi: người dùng gửi phản ánh, đơn vị phụ trách tiếp nhận và cập nhật trạng thái xử lý, quản trị viên quản lý danh mục và tài khoản. Các chức năng AI chưa phải yêu cầu bắt buộc, chỉ được xem là hướng phát triển sau này.

## 2. Mục tiêu nghiệp vụ

Mục tiêu của CivicHub là xây dựng một kênh tiếp nhận phản ánh cộng đồng đơn giản, minh bạch và dễ sử dụng.

Cụ thể, hệ thống cần đạt các mục tiêu sau:

- Giúp người dân gửi phản ánh nhanh chóng qua thiết bị di động.
- Giúp người dân theo dõi trạng thái xử lý phản ánh đã gửi.
- Giúp nhân viên đơn vị xử lý tiếp nhận, phân loại và cập nhật tiến độ xử lý phản ánh.
- Giúp quản trị viên quản lý người dùng, danh mục phản ánh và các đơn vị xử lý ở mức cơ bản.
- Giảm tình trạng phản ánh bị thất lạc hoặc không có thông tin phản hồi.
- Tạo nền tảng ban đầu để có thể mở rộng thêm các chức năng nâng cao trong tương lai.

## 3. Phạm vi hệ thống

Phiên bản MVP của CivicHub bao gồm các phạm vi chính sau:

- Đăng ký, đăng nhập và quản lý thông tin tài khoản cơ bản.
- Người dùng tạo phản ánh mới kèm nội dung mô tả, hình ảnh và vị trí.
- Người dùng xem danh sách phản ánh của mình, theo dõi trạng thái xử lý và hủy phản ánh khi còn ở trạng thái cho phép.
- Người dùng xem thông báo nội bộ trong ứng dụng khi trạng thái phản ánh thay đổi.
- Nhân viên đơn vị xử lý xem danh sách phản ánh được phân công hoặc thuộc phạm vi xử lý.
- Nhân viên tiếp nhận, cập nhật trạng thái và ghi chú xử lý cho phản ánh.
- Quản trị viên quản lý tài khoản, danh mục phản ánh và đơn vị xử lý.
- Hệ thống phân quyền cơ bản theo vai trò: người dùng, nhân viên xử lý và quản trị viên.

Các nội dung không thuộc phạm vi MVP:

- Tích hợp bản đồ nâng cao hoặc điều hướng chi tiết.
- Tự động phân loại phản ánh bằng AI.
- Chat trực tiếp giữa người dân và nhân viên xử lý.
- Quy trình phê duyệt nhiều cấp phức tạp.
- Tích hợp thanh toán, chữ ký số hoặc hệ thống hành chính bên ngoài.
- Ứng dụng riêng cho từng đơn vị xử lý.

## 4. Các đối tượng sử dụng

### 4.1. Người dùng

Người dùng là người dân hoặc thành viên cộng đồng sử dụng ứng dụng di động để gửi phản ánh và theo dõi kết quả xử lý.

Nhu cầu chính:

- Gửi phản ánh nhanh, dễ thao tác.
- Đính kèm hình ảnh minh chứng.
- Cung cấp vị trí xảy ra sự việc.
- Theo dõi trạng thái phản ánh sau khi gửi.
- Nhận thông báo trong ứng dụng khi phản ánh có thay đổi trạng thái.

### 4.2. Nhân viên đơn vị xử lý

Nhân viên đơn vị xử lý là người tiếp nhận và xử lý các phản ánh thuộc trách nhiệm của đơn vị mình.

Nhu cầu chính:

- Xem danh sách phản ánh cần xử lý.
- Xem thông tin chi tiết của từng phản ánh.
- Cập nhật trạng thái xử lý.
- Ghi chú kết quả hoặc tiến độ xử lý.

### 4.3. Quản trị viên

Quản trị viên là người quản lý hệ thống ở mức tổng thể.

Nhu cầu chính:

- Quản lý tài khoản người dùng và nhân viên.
- Quản lý danh mục phản ánh.
- Quản lý đơn vị xử lý.
- Theo dõi tổng quan tình trạng phản ánh trong hệ thống.

## 5. Yêu cầu chức năng

### 5.1. Chức năng dành cho người dùng

#### Đăng ký và đăng nhập

- Người dùng có thể đăng ký tài khoản bằng các thông tin cơ bản như họ tên, email hoặc số điện thoại và mật khẩu.
- Người dùng có thể đăng nhập vào ứng dụng bằng tài khoản đã đăng ký.
- Người dùng có thể đăng xuất khỏi hệ thống.
- Hệ thống cần kiểm tra thông tin đăng nhập hợp lệ trước khi cho phép truy cập.

#### Quản lý thông tin cá nhân

- Người dùng có thể xem thông tin cá nhân của mình.
- Người dùng có thể cập nhật một số thông tin cơ bản như họ tên, số điện thoại hoặc địa chỉ liên hệ.
- Người dùng có thể đổi mật khẩu khi cần.

#### Gửi phản ánh

- Người dùng có thể tạo phản ánh mới.
- Mỗi phản ánh cần có các thông tin tối thiểu:
  - Tiêu đề phản ánh.
  - Nội dung mô tả.
  - Danh mục phản ánh.
  - Vị trí xảy ra sự việc.
  - Hình ảnh đính kèm nếu có.
- Sau khi gửi thành công, phản ánh được lưu vào hệ thống với trạng thái ban đầu phù hợp, ví dụ: Chờ tiếp nhận.

#### Theo dõi phản ánh

- Người dùng có thể xem danh sách các phản ánh mình đã gửi.
- Người dùng có thể xem chi tiết từng phản ánh.
- Người dùng có thể theo dõi trạng thái xử lý của phản ánh.
- Người dùng có thể xem ghi chú hoặc kết quả xử lý do nhân viên cập nhật.
- Người dùng có thể xem thông báo nội bộ trong ứng dụng khi phản ánh thay đổi trạng thái.

#### Hủy phản ánh

- Người dùng có thể hủy phản ánh do mình đã gửi khi phản ánh chưa được tiếp nhận hoặc chưa bắt đầu xử lý.
- Người dùng chỉ được hủy phản ánh khi phản ánh đang ở trạng thái Chờ tiếp nhận.
- Khi phản ánh đã ở trạng thái Đã tiếp nhận, Đang xử lý, Đã xử lý hoặc Từ chối xử lý thì người dùng không được hủy.
- Sau khi hủy thành công, trạng thái phản ánh được cập nhật thành Đã hủy.

#### Tìm kiếm và lọc cơ bản

- Người dùng có thể lọc phản ánh của mình theo trạng thái.
- Người dùng có thể tìm kiếm phản ánh theo từ khóa cơ bản trong tiêu đề hoặc nội dung.

### 5.2. Chức năng dành cho nhân viên đơn vị xử lý

#### Đăng nhập hệ thống

- Nhân viên có thể đăng nhập vào trang quản trị bằng tài khoản được cấp.
- Hệ thống chỉ cho phép nhân viên truy cập các chức năng phù hợp với vai trò của mình.

#### Xem danh sách phản ánh

- Nhân viên có thể xem danh sách phản ánh thuộc phạm vi xử lý.
- Danh sách phản ánh cần hiển thị các thông tin cơ bản như tiêu đề, danh mục, thời gian gửi, trạng thái và vị trí.
- Nhân viên có thể lọc phản ánh theo trạng thái, danh mục hoặc thời gian gửi ở mức cơ bản.

#### Xem chi tiết phản ánh

- Nhân viên có thể xem đầy đủ thông tin của một phản ánh.
- Thông tin chi tiết gồm nội dung mô tả, hình ảnh, vị trí, người gửi, trạng thái hiện tại và lịch sử cập nhật cơ bản.

#### Tiếp nhận phản ánh

- Nhân viên có thể tiếp nhận hoặc nhận xử lý một phản ánh thuộc phạm vi đơn vị của mình.
- Sau khi nhân viên tiếp nhận, trạng thái phản ánh được chuyển từ Chờ tiếp nhận sang Đã tiếp nhận.
- Nhân viên chỉ tiếp nhận các phản ánh chưa ở trạng thái Đã hủy và chưa được xử lý bởi trạng thái khác.

#### Cập nhật trạng thái xử lý

- Nhân viên có thể cập nhật trạng thái xử lý của phản ánh.
- Các trạng thái phản ánh được sử dụng thống nhất trong hệ thống gồm:
  - Chờ tiếp nhận.
  - Đã tiếp nhận.
  - Đang xử lý.
  - Đã xử lý.
  - Từ chối xử lý.
  - Đã hủy.
- Khi cập nhật trạng thái, nhân viên có thể nhập ghi chú xử lý.
- Người dùng có thể xem trạng thái và ghi chú mới nhất sau khi nhân viên cập nhật.

#### Quản lý công việc xử lý cá nhân

- Nhân viên có thể xem các phản ánh đang xử lý.
- Nhân viên có thể xem các phản ánh đã hoàn tất.
- Hệ thống hỗ trợ nhân viên theo dõi công việc ở mức danh sách, không yêu cầu quy trình điều phối phức tạp trong MVP.

### 5.3. Chức năng dành cho quản trị viên

#### Quản lý tài khoản

- Quản trị viên có thể xem danh sách tài khoản trong hệ thống.
- Quản trị viên có thể tạo tài khoản nhân viên xử lý.
- Quản trị viên có thể cập nhật thông tin cơ bản của tài khoản.
- Quản trị viên có thể khóa hoặc mở khóa tài khoản khi cần.
- Quản trị viên có thể phân vai trò cơ bản cho tài khoản.

#### Quản lý danh mục phản ánh

- Quản trị viên có thể xem danh sách danh mục phản ánh.
- Quản trị viên có thể thêm, sửa hoặc tạm ngưng sử dụng danh mục phản ánh.
- Danh mục phản ánh giúp người dùng chọn đúng loại vấn đề khi gửi phản ánh.
- Dữ liệu danh mục mẫu trong MVP có thể gồm:
  - Giao thông và đường bộ.
  - Chiếu sáng công cộng.
  - Vệ sinh môi trường.
  - An ninh trật tự.
  - Cây xanh.
  - Thoát nước và ngập úng.
  - Khác.
- Quản trị viên có thể quản lý các danh mục mẫu này để phù hợp với phạm vi triển khai thử nghiệm.

#### Quản lý đơn vị xử lý

- Quản trị viên có thể xem danh sách đơn vị xử lý.
- Quản trị viên có thể thêm, sửa hoặc tạm ngưng sử dụng đơn vị xử lý.
- Quản trị viên có thể gán nhân viên vào đơn vị xử lý ở mức cơ bản.

#### Theo dõi tổng quan phản ánh

- Quản trị viên có thể xem danh sách toàn bộ phản ánh trong hệ thống.
- Quản trị viên có thể lọc phản ánh theo trạng thái, danh mục hoặc đơn vị xử lý.
- Dashboard MVP của quản trị viên cần hiển thị các thông tin tổng quan sau:
  - Tổng số phản ánh.
  - Số phản ánh chờ tiếp nhận.
  - Số phản ánh đã tiếp nhận.
  - Số phản ánh đang xử lý.
  - Số phản ánh đã xử lý.
  - Số phản ánh bị từ chối.
  - Biểu đồ thống kê theo danh mục.
  - Danh sách 5 phản ánh mới nhất.
- Các thống kê trong dashboard chỉ cần phục vụ theo dõi nhanh ở mức MVP, không yêu cầu báo cáo phân tích nâng cao.

## 6. Yêu cầu phi chức năng

### 6.1. Tính dễ sử dụng

- Giao diện mobile cần đơn giản, dễ thao tác với người dùng phổ thông.
- Các luồng chính như đăng nhập, gửi phản ánh và xem trạng thái cần ít bước và dễ hiểu.
- Trang quản trị cần ưu tiên hiển thị rõ danh sách phản ánh và trạng thái xử lý.

### 6.2. Hiệu năng

- Hệ thống cần đáp ứng tốt với quy mô dữ liệu nhỏ đến trung bình trong phạm vi đồ án MVP.
- Các màn hình danh sách cần có phân trang hoặc cơ chế tải dữ liệu hợp lý.
- Thời gian phản hồi cho các thao tác thông thường nên ở mức chấp nhận được trong môi trường triển khai thử nghiệm.

### 6.3. Bảo mật

- Mật khẩu người dùng cần được lưu trữ an toàn, không lưu dưới dạng văn bản thuần.
- Hệ thống cần phân quyền truy cập theo vai trò.
- Người dùng chỉ được xem phản ánh của chính mình.
- Nhân viên chỉ được truy cập các chức năng xử lý phù hợp với vai trò được cấp.
- Các chức năng quản trị chỉ dành cho quản trị viên.

### 6.4. Khả năng bảo trì

- Mã nguồn cần được tổ chức rõ ràng theo từng thành phần: Mobile, Admin, Backend.
- Nghiệp vụ cốt lõi cần được tách biệt tương đối rõ để dễ chỉnh sửa trong quá trình phát triển.
- Tài liệu dự án cần đủ để người phát triển có thể tiếp tục mở rộng sau MVP.

### 6.5. Tính tương thích

- Ứng dụng mobile ưu tiên chạy tốt trên Android trong phạm vi MVP.
- Trang quản trị ưu tiên hoạt động tốt trên các trình duyệt phổ biến như Chrome hoặc Edge.
- Backend cần hoạt động ổn định trong môi trường phát triển và triển khai thử nghiệm.

### 6.6. Sao lưu và phục hồi dữ liệu

- Trong phạm vi MVP, hệ thống cần có cách sao lưu dữ liệu thủ công hoặc theo hướng dẫn triển khai.
- Không yêu cầu cơ chế sao lưu tự động phức tạp.

## 7. Giới hạn của phiên bản MVP

Phiên bản MVP được giới hạn để phù hợp với thời gian thực hiện khoảng 1 tháng và do một sinh viên phát triển.

Các giới hạn chính:

- Chỉ tập trung vào các chức năng cốt lõi của tiếp nhận và theo dõi phản ánh.
- Không triển khai AI trong phiên bản bắt buộc.
- Không triển khai chat thời gian thực.
- Chỉ triển khai thông báo nội bộ trong ứng dụng khi trạng thái phản ánh thay đổi; Push Notification chưa phải yêu cầu bắt buộc của MVP.
- Không triển khai quy trình xử lý nhiều cấp hoặc phê duyệt phức tạp.
- Không tích hợp hệ thống bản đồ nâng cao; vị trí có thể được lưu và hiển thị ở mức cơ bản.
- Không tích hợp với các hệ thống hành chính, tổng đài hoặc cổng dịch vụ công bên ngoài.
- Không yêu cầu báo cáo phân tích nâng cao.
- Không xây dựng ứng dụng mobile riêng cho nhân viên xử lý.

## 8. Giả định và ràng buộc

### 8.1. Giả định

- Người dùng có thiết bị di động có kết nối Internet.
- Nhân viên xử lý và quản trị viên sử dụng trình duyệt web để truy cập trang quản trị.
- Dữ liệu phản ánh trong giai đoạn MVP phục vụ mục đích thử nghiệm hoặc mô phỏng nghiệp vụ.
- Số lượng người dùng và phản ánh trong giai đoạn đầu chưa quá lớn.
- Một phản ánh thuộc một danh mục chính và được xử lý bởi một đơn vị phù hợp.

### 8.2. Ràng buộc

- Thời gian phát triển khoảng 1 tháng.
- Nguồn lực phát triển là một sinh viên.
- Công nghệ sử dụng gồm Flutter Mobile, React Admin, Spring Boot và PostgreSQL.
- Phạm vi chức năng cần được giữ gọn để đảm bảo hoàn thành được sản phẩm chạy được.
- Các chức năng nâng cao chỉ nên được phát triển sau khi luồng nghiệp vụ cốt lõi đã ổn định.

## 9. Hướng phát triển trong tương lai

Sau khi hoàn thành MVP, CivicHub có thể được mở rộng theo các hướng sau:

- Bổ sung thông báo đẩy để người dùng nhận cập nhật khi phản ánh thay đổi trạng thái.
- Tích hợp bản đồ trực quan hơn để hiển thị vị trí phản ánh.
- Bổ sung chức năng phân công phản ánh chi tiết cho từng nhân viên.
- Xây dựng dashboard thống kê nâng cao theo khu vực, danh mục, thời gian và hiệu quả xử lý.
- Cho phép người dùng đánh giá mức độ hài lòng sau khi phản ánh được xử lý.
- Bổ sung AI để gợi ý danh mục phản ánh, phát hiện phản ánh trùng lặp hoặc hỗ trợ tóm tắt nội dung.
- Bổ sung chatbot hỗ trợ người dùng tra cứu và gửi phản ánh.
- Tích hợp với các hệ thống quản lý đô thị hoặc cổng dịch vụ công nếu có nhu cầu thực tế.
- Hỗ trợ triển khai đa địa phương hoặc nhiều tổ chức sử dụng chung nền tảng.
