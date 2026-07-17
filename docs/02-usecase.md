# 02. Tài liệu Use Case hệ thống CivicHub

## 1. Danh sách Actor

Hệ thống CivicHub trong phạm vi MVP có các actor chính sau:

- Người dùng.
- Nhân viên đơn vị xử lý.
- Quản trị viên.

## 2. Mô tả Actor

### 2.1. Người dùng

Người dùng là người dân hoặc thành viên cộng đồng sử dụng ứng dụng mobile để gửi phản ánh, theo dõi trạng thái xử lý, xem thông báo nội bộ và hủy phản ánh khi phản ánh chưa được tiếp nhận.

### 2.2. Nhân viên đơn vị xử lý

Nhân viên đơn vị xử lý là người thuộc một đơn vị phụ trách xử lý phản ánh. Nhân viên sử dụng trang quản trị để xem phản ánh thuộc phạm vi đơn vị, tiếp nhận phản ánh, cập nhật trạng thái xử lý và ghi chú kết quả xử lý.

### 2.3. Quản trị viên

Quản trị viên là người quản lý hệ thống ở mức tổng thể. Quản trị viên sử dụng trang quản trị để quản lý tài khoản, danh mục phản ánh, đơn vị xử lý và theo dõi dashboard tổng quan của hệ thống.

## 3. Use Case Theo Actor

## 3.1. Người dùng

### UC-USER-01: Đăng ký tài khoản

- **Tên:** Đăng ký tài khoản.
- **Mục tiêu:** Cho phép người dùng tạo tài khoản để sử dụng hệ thống CivicHub.
- **Tiền điều kiện:**
  - Người dùng chưa đăng nhập.
  - Người dùng chưa có tài khoản hợp lệ trong hệ thống.
- **Luồng chính:**
  1. Người dùng mở màn hình đăng ký.
  2. Người dùng nhập thông tin cơ bản như họ tên, email hoặc số điện thoại và mật khẩu.
  3. Người dùng gửi yêu cầu đăng ký.
  4. Hệ thống kiểm tra tính hợp lệ của thông tin.
  5. Hệ thống tạo tài khoản người dùng.
  6. Hệ thống thông báo đăng ký thành công.
- **Luồng thay thế:**
  - Nếu thông tin bắt buộc bị thiếu, hệ thống yêu cầu người dùng bổ sung.
  - Nếu email hoặc số điện thoại đã được sử dụng, hệ thống thông báo để người dùng nhập thông tin khác.
  - Nếu mật khẩu không hợp lệ theo quy định, hệ thống yêu cầu nhập lại.
- **Hậu điều kiện:**
  - Tài khoản người dùng được tạo thành công.
  - Người dùng có thể đăng nhập bằng tài khoản đã đăng ký.

### UC-USER-02: Đăng nhập

- **Tên:** Đăng nhập.
- **Mục tiêu:** Cho phép người dùng truy cập ứng dụng bằng tài khoản hợp lệ.
- **Tiền điều kiện:**
  - Người dùng đã có tài khoản.
  - Tài khoản không bị khóa.
- **Luồng chính:**
  1. Người dùng mở màn hình đăng nhập.
  2. Người dùng nhập thông tin đăng nhập và mật khẩu.
  3. Người dùng gửi yêu cầu đăng nhập.
  4. Hệ thống kiểm tra thông tin đăng nhập.
  5. Hệ thống cho phép người dùng truy cập ứng dụng.
- **Luồng thay thế:**
  - Nếu thông tin đăng nhập sai, hệ thống thông báo đăng nhập không thành công.
  - Nếu tài khoản bị khóa, hệ thống thông báo người dùng không thể đăng nhập.
- **Hậu điều kiện:**
  - Người dùng đăng nhập thành công và có thể sử dụng các chức năng dành cho người dùng.

### UC-USER-03: Đăng xuất

- **Tên:** Đăng xuất.
- **Mục tiêu:** Cho phép người dùng thoát khỏi phiên sử dụng hiện tại.
- **Tiền điều kiện:**
  - Người dùng đang đăng nhập.
- **Luồng chính:**
  1. Người dùng chọn chức năng đăng xuất.
  2. Hệ thống xác nhận thao tác đăng xuất.
  3. Hệ thống kết thúc phiên sử dụng hiện tại.
  4. Hệ thống đưa người dùng về màn hình đăng nhập hoặc màn hình bắt đầu.
- **Luồng thay thế:**
  - Nếu người dùng hủy thao tác xác nhận, hệ thống giữ nguyên phiên đăng nhập.
- **Hậu điều kiện:**
  - Người dùng đã đăng xuất khỏi hệ thống.

### UC-USER-04: Quản lý thông tin cá nhân

- **Tên:** Quản lý thông tin cá nhân.
- **Mục tiêu:** Cho phép người dùng xem và cập nhật thông tin cá nhân cơ bản.
- **Tiền điều kiện:**
  - Người dùng đã đăng nhập.
- **Luồng chính:**
  1. Người dùng mở màn hình thông tin cá nhân.
  2. Hệ thống hiển thị thông tin hiện tại của người dùng.
  3. Người dùng chỉnh sửa các thông tin được phép như họ tên, số điện thoại hoặc địa chỉ liên hệ.
  4. Người dùng lưu thay đổi.
  5. Hệ thống kiểm tra thông tin và cập nhật hồ sơ.
  6. Hệ thống thông báo cập nhật thành công.
- **Luồng thay thế:**
  - Nếu thông tin không hợp lệ, hệ thống hiển thị lỗi và yêu cầu chỉnh sửa.
  - Nếu người dùng không lưu thay đổi, thông tin cá nhân được giữ nguyên.
- **Hậu điều kiện:**
  - Thông tin cá nhân của người dùng được cập nhật nếu dữ liệu hợp lệ.

### UC-USER-05: Đổi mật khẩu

- **Tên:** Đổi mật khẩu.
- **Mục tiêu:** Cho phép người dùng thay đổi mật khẩu tài khoản.
- **Tiền điều kiện:**
  - Người dùng đã đăng nhập.
- **Luồng chính:**
  1. Người dùng mở chức năng đổi mật khẩu.
  2. Người dùng nhập mật khẩu hiện tại và mật khẩu mới.
  3. Người dùng xác nhận đổi mật khẩu.
  4. Hệ thống kiểm tra mật khẩu hiện tại.
  5. Hệ thống kiểm tra tính hợp lệ của mật khẩu mới.
  6. Hệ thống cập nhật mật khẩu.
  7. Hệ thống thông báo đổi mật khẩu thành công.
- **Luồng thay thế:**
  - Nếu mật khẩu hiện tại không đúng, hệ thống từ chối thay đổi.
  - Nếu mật khẩu mới không hợp lệ, hệ thống yêu cầu nhập lại.
- **Hậu điều kiện:**
  - Mật khẩu mới được áp dụng cho các lần đăng nhập tiếp theo.

### UC-USER-06: Gửi phản ánh

- **Tên:** Gửi phản ánh.
- **Mục tiêu:** Cho phép người dùng tạo phản ánh mới về vấn đề trong cộng đồng.
- **Tiền điều kiện:**
  - Người dùng đã đăng nhập.
  - Danh mục phản ánh đang khả dụng trong hệ thống.
- **Luồng chính:**
  1. Người dùng chọn chức năng tạo phản ánh mới.
  2. Người dùng nhập tiêu đề phản ánh.
  3. Người dùng nhập nội dung mô tả.
  4. Người dùng chọn danh mục phản ánh.
  5. Người dùng cung cấp vị trí xảy ra sự việc.
  6. Người dùng đính kèm hình ảnh nếu có.
  7. Người dùng gửi phản ánh.
  8. Hệ thống kiểm tra thông tin bắt buộc.
  9. Hệ thống lưu phản ánh với trạng thái Chờ tiếp nhận.
  10. Hệ thống thông báo gửi phản ánh thành công.
- **Luồng thay thế:**
  - Nếu thiếu tiêu đề, nội dung, danh mục hoặc vị trí, hệ thống yêu cầu bổ sung.
  - Nếu hình ảnh không hợp lệ, hệ thống thông báo để người dùng chọn lại hoặc gửi phản ánh không kèm hình ảnh.
  - Nếu người dùng hủy thao tác trước khi gửi, phản ánh không được tạo.
- **Hậu điều kiện:**
  - Phản ánh mới được ghi nhận trong hệ thống với trạng thái Chờ tiếp nhận.
  - Người dùng có thể xem phản ánh trong danh sách phản ánh của mình.

### UC-USER-07: Xem danh sách phản ánh đã gửi

- **Tên:** Xem danh sách phản ánh đã gửi.
- **Mục tiêu:** Cho phép người dùng theo dõi các phản ánh do mình tạo.
- **Tiền điều kiện:**
  - Người dùng đã đăng nhập.
- **Luồng chính:**
  1. Người dùng mở màn hình danh sách phản ánh.
  2. Hệ thống hiển thị danh sách phản ánh của người dùng.
  3. Người dùng xem các thông tin cơ bản như tiêu đề, danh mục, thời gian gửi và trạng thái.
  4. Người dùng có thể chọn một phản ánh để xem chi tiết.
- **Luồng thay thế:**
  - Nếu người dùng chưa có phản ánh nào, hệ thống hiển thị trạng thái danh sách trống.
- **Hậu điều kiện:**
  - Người dùng xem được danh sách phản ánh thuộc tài khoản của mình.

### UC-USER-08: Xem chi tiết phản ánh

- **Tên:** Xem chi tiết phản ánh.
- **Mục tiêu:** Cho phép người dùng xem đầy đủ thông tin và tiến độ của một phản ánh đã gửi.
- **Tiền điều kiện:**
  - Người dùng đã đăng nhập.
  - Phản ánh thuộc về người dùng hiện tại.
- **Luồng chính:**
  1. Người dùng chọn một phản ánh trong danh sách.
  2. Hệ thống hiển thị thông tin chi tiết phản ánh.
  3. Người dùng xem nội dung mô tả, danh mục, vị trí, hình ảnh, trạng thái hiện tại và ghi chú xử lý.
  4. Người dùng xem lịch sử cập nhật cơ bản nếu có.
- **Luồng thay thế:**
  - Nếu phản ánh không tồn tại hoặc không thuộc người dùng hiện tại, hệ thống không cho phép xem chi tiết.
- **Hậu điều kiện:**
  - Người dùng nắm được trạng thái và thông tin xử lý mới nhất của phản ánh.

### UC-USER-09: Tìm kiếm và lọc phản ánh

- **Tên:** Tìm kiếm và lọc phản ánh.
- **Mục tiêu:** Giúp người dùng nhanh chóng tìm lại phản ánh đã gửi.
- **Tiền điều kiện:**
  - Người dùng đã đăng nhập.
  - Người dùng có quyền xem danh sách phản ánh của mình.
- **Luồng chính:**
  1. Người dùng mở danh sách phản ánh.
  2. Người dùng nhập từ khóa hoặc chọn trạng thái cần lọc.
  3. Hệ thống hiển thị danh sách phản ánh phù hợp với điều kiện tìm kiếm hoặc lọc.
  4. Người dùng chọn phản ánh cần xem nếu cần.
- **Luồng thay thế:**
  - Nếu không có kết quả phù hợp, hệ thống hiển thị thông báo không có dữ liệu.
  - Nếu người dùng xóa điều kiện lọc, hệ thống hiển thị lại danh sách phản ánh mặc định.
- **Hậu điều kiện:**
  - Người dùng xem được kết quả phản ánh phù hợp với tiêu chí đã chọn.

### UC-USER-10: Hủy phản ánh

- **Tên:** Hủy phản ánh.
- **Mục tiêu:** Cho phép người dùng hủy phản ánh đã gửi khi phản ánh chưa được tiếp nhận.
- **Tiền điều kiện:**
  - Người dùng đã đăng nhập.
  - Phản ánh thuộc về người dùng hiện tại.
  - Phản ánh đang ở trạng thái Chờ tiếp nhận.
- **Luồng chính:**
  1. Người dùng mở chi tiết phản ánh.
  2. Người dùng chọn chức năng hủy phản ánh.
  3. Hệ thống yêu cầu xác nhận thao tác hủy.
  4. Người dùng xác nhận hủy.
  5. Hệ thống kiểm tra trạng thái hiện tại của phản ánh.
  6. Hệ thống cập nhật trạng thái phản ánh thành Đã hủy.
  7. Hệ thống thông báo hủy phản ánh thành công.
- **Luồng thay thế:**
  - Nếu người dùng không xác nhận, phản ánh được giữ nguyên.
  - Nếu phản ánh đã ở trạng thái Đã tiếp nhận, Đang xử lý, Đã xử lý hoặc Từ chối xử lý, hệ thống không cho phép hủy.
  - Nếu phản ánh đã bị hủy trước đó, hệ thống hiển thị trạng thái hiện tại là Đã hủy.
- **Hậu điều kiện:**
  - Phản ánh được chuyển sang trạng thái Đã hủy nếu đủ điều kiện.
  - Phản ánh đã hủy không tiếp tục đi vào luồng xử lý của nhân viên.

### UC-USER-11: Xem thông báo trong ứng dụng

- **Tên:** Xem thông báo trong ứng dụng.
- **Mục tiêu:** Cho phép người dùng xem các cập nhật nội bộ khi trạng thái phản ánh thay đổi.
- **Tiền điều kiện:**
  - Người dùng đã đăng nhập.
  - Người dùng có phản ánh phát sinh thay đổi trạng thái hoặc ghi chú xử lý.
- **Luồng chính:**
  1. Người dùng mở màn hình thông báo trong ứng dụng.
  2. Hệ thống hiển thị danh sách thông báo liên quan đến phản ánh của người dùng.
  3. Người dùng chọn một thông báo.
  4. Hệ thống điều hướng hoặc hiển thị thông tin phản ánh liên quan.
- **Luồng thay thế:**
  - Nếu chưa có thông báo nào, hệ thống hiển thị trạng thái danh sách trống.
- **Hậu điều kiện:**
  - Người dùng biết được thay đổi mới nhất liên quan đến phản ánh của mình.

## 3.2. Nhân viên đơn vị xử lý

### UC-STAFF-01: Đăng nhập trang quản trị

- **Tên:** Đăng nhập trang quản trị.
- **Mục tiêu:** Cho phép nhân viên truy cập các chức năng xử lý phản ánh.
- **Tiền điều kiện:**
  - Nhân viên đã được cấp tài khoản.
  - Tài khoản nhân viên không bị khóa.
- **Luồng chính:**
  1. Nhân viên mở trang đăng nhập quản trị.
  2. Nhân viên nhập thông tin đăng nhập và mật khẩu.
  3. Nhân viên gửi yêu cầu đăng nhập.
  4. Hệ thống kiểm tra thông tin tài khoản và vai trò.
  5. Hệ thống cho phép nhân viên truy cập màn hình phù hợp.
- **Luồng thay thế:**
  - Nếu thông tin đăng nhập sai, hệ thống thông báo đăng nhập không thành công.
  - Nếu tài khoản không có vai trò nhân viên xử lý, hệ thống từ chối truy cập chức năng xử lý.
  - Nếu tài khoản bị khóa, hệ thống thông báo không thể đăng nhập.
- **Hậu điều kiện:**
  - Nhân viên đăng nhập thành công và có thể xem phản ánh thuộc phạm vi xử lý.

### UC-STAFF-02: Xem danh sách phản ánh thuộc phạm vi xử lý

- **Tên:** Xem danh sách phản ánh thuộc phạm vi xử lý.
- **Mục tiêu:** Giúp nhân viên nắm được các phản ánh cần tiếp nhận hoặc xử lý.
- **Tiền điều kiện:**
  - Nhân viên đã đăng nhập.
  - Nhân viên thuộc một đơn vị xử lý hợp lệ.
- **Luồng chính:**
  1. Nhân viên mở danh sách phản ánh.
  2. Hệ thống hiển thị các phản ánh thuộc phạm vi đơn vị.
  3. Nhân viên xem thông tin cơ bản như tiêu đề, danh mục, thời gian gửi, trạng thái và vị trí.
  4. Nhân viên chọn một phản ánh để xem chi tiết nếu cần.
- **Luồng thay thế:**
  - Nếu chưa có phản ánh thuộc phạm vi xử lý, hệ thống hiển thị danh sách trống.
- **Hậu điều kiện:**
  - Nhân viên xem được danh sách phản ánh phù hợp với quyền xử lý.

### UC-STAFF-03: Lọc phản ánh cần xử lý

- **Tên:** Lọc phản ánh cần xử lý.
- **Mục tiêu:** Cho phép nhân viên tìm nhanh phản ánh theo trạng thái, danh mục hoặc thời gian gửi.
- **Tiền điều kiện:**
  - Nhân viên đã đăng nhập.
  - Nhân viên có quyền xem danh sách phản ánh thuộc đơn vị.
- **Luồng chính:**
  1. Nhân viên mở danh sách phản ánh.
  2. Nhân viên chọn tiêu chí lọc như trạng thái, danh mục hoặc thời gian gửi.
  3. Hệ thống hiển thị danh sách phản ánh phù hợp.
  4. Nhân viên chọn phản ánh cần xử lý.
- **Luồng thay thế:**
  - Nếu không có phản ánh phù hợp, hệ thống hiển thị thông báo không có dữ liệu.
  - Nếu nhân viên xóa tiêu chí lọc, hệ thống hiển thị lại danh sách mặc định.
- **Hậu điều kiện:**
  - Nhân viên xem được danh sách phản ánh theo tiêu chí đã chọn.

### UC-STAFF-04: Xem chi tiết phản ánh

- **Tên:** Xem chi tiết phản ánh.
- **Mục tiêu:** Cho phép nhân viên xem đầy đủ thông tin cần thiết để xử lý phản ánh.
- **Tiền điều kiện:**
  - Nhân viên đã đăng nhập.
  - Phản ánh thuộc phạm vi xử lý của đơn vị nhân viên.
- **Luồng chính:**
  1. Nhân viên chọn một phản ánh trong danh sách.
  2. Hệ thống hiển thị chi tiết phản ánh.
  3. Nhân viên xem nội dung mô tả, hình ảnh, vị trí, người gửi, trạng thái hiện tại và lịch sử cập nhật cơ bản.
  4. Nhân viên xác định bước xử lý tiếp theo.
- **Luồng thay thế:**
  - Nếu phản ánh không còn thuộc phạm vi xử lý, hệ thống không cho phép tiếp tục thao tác.
  - Nếu phản ánh đã ở trạng thái Đã hủy, hệ thống chỉ hiển thị thông tin để tham khảo và không cho tiếp nhận xử lý.
- **Hậu điều kiện:**
  - Nhân viên nắm được thông tin chi tiết của phản ánh.

### UC-STAFF-05: Tiếp nhận phản ánh

- **Tên:** Tiếp nhận phản ánh.
- **Mục tiêu:** Cho phép nhân viên nhận xử lý một phản ánh thuộc phạm vi đơn vị.
- **Tiền điều kiện:**
  - Nhân viên đã đăng nhập.
  - Phản ánh thuộc phạm vi đơn vị xử lý.
  - Phản ánh đang ở trạng thái Chờ tiếp nhận.
- **Luồng chính:**
  1. Nhân viên mở chi tiết phản ánh.
  2. Nhân viên chọn tiếp nhận hoặc nhận xử lý phản ánh.
  3. Hệ thống kiểm tra trạng thái hiện tại của phản ánh.
  4. Hệ thống cập nhật trạng thái phản ánh thành Đã tiếp nhận.
  5. Hệ thống ghi nhận thông tin tiếp nhận ở mức nghiệp vụ.
  6. Hệ thống thông báo tiếp nhận thành công.
- **Luồng thay thế:**
  - Nếu phản ánh đã ở trạng thái Đã hủy, hệ thống không cho phép tiếp nhận.
  - Nếu phản ánh đã ở trạng thái Đã tiếp nhận, Đang xử lý, Đã xử lý hoặc Từ chối xử lý, hệ thống thông báo phản ánh không còn đủ điều kiện tiếp nhận.
- **Hậu điều kiện:**
  - Phản ánh được chuyển sang trạng thái Đã tiếp nhận.
  - Người dùng có thể xem trạng thái mới và nhận thông báo nội bộ trong ứng dụng.

### UC-STAFF-06: Cập nhật trạng thái xử lý phản ánh

- **Tên:** Cập nhật trạng thái xử lý phản ánh.
- **Mục tiêu:** Cho phép nhân viên cập nhật tiến độ và kết quả xử lý phản ánh.
- **Tiền điều kiện:**
  - Nhân viên đã đăng nhập.
  - Phản ánh thuộc phạm vi xử lý của đơn vị.
  - Phản ánh chưa ở trạng thái Đã hủy.
- **Luồng chính:**
  1. Nhân viên mở chi tiết phản ánh.
  2. Nhân viên chọn trạng thái cần cập nhật.
  3. Nhân viên nhập ghi chú xử lý nếu cần.
  4. Hệ thống kiểm tra quyền và trạng thái hiện tại của phản ánh.
  5. Hệ thống cập nhật trạng thái phản ánh.
  6. Hệ thống lưu ghi chú xử lý.
  7. Hệ thống thông báo cập nhật thành công.
- **Luồng thay thế:**
  - Nếu trạng thái cập nhật không phù hợp với phạm vi xử lý, hệ thống từ chối thao tác.
  - Nếu thiếu ghi chú cần thiết khi từ chối xử lý hoặc hoàn tất xử lý, hệ thống yêu cầu bổ sung.
  - Nếu phản ánh đã ở trạng thái Đã hủy, hệ thống không cho phép cập nhật xử lý.
- **Hậu điều kiện:**
  - Trạng thái phản ánh được cập nhật theo một trong các trạng thái hợp lệ: Đã tiếp nhận, Đang xử lý, Đã xử lý hoặc Từ chối xử lý.
  - Người dùng có thể xem trạng thái và ghi chú mới nhất.
  - Hệ thống tạo thông báo nội bộ cho người dùng khi trạng thái thay đổi.

### UC-STAFF-07: Xem công việc xử lý cá nhân

- **Tên:** Xem công việc xử lý cá nhân.
- **Mục tiêu:** Giúp nhân viên theo dõi các phản ánh đang xử lý và đã hoàn tất ở mức danh sách.
- **Tiền điều kiện:**
  - Nhân viên đã đăng nhập.
- **Luồng chính:**
  1. Nhân viên mở màn hình công việc xử lý.
  2. Hệ thống hiển thị các phản ánh đang xử lý.
  3. Nhân viên chuyển sang xem các phản ánh đã hoàn tất nếu cần.
  4. Nhân viên chọn một phản ánh để xem chi tiết.
- **Luồng thay thế:**
  - Nếu chưa có công việc xử lý, hệ thống hiển thị danh sách trống.
- **Hậu điều kiện:**
  - Nhân viên nắm được các phản ánh đang xử lý và các phản ánh đã hoàn tất.

## 3.3. Quản trị viên

### UC-ADMIN-01: Đăng nhập trang quản trị

- **Tên:** Đăng nhập trang quản trị.
- **Mục tiêu:** Cho phép quản trị viên truy cập các chức năng quản lý hệ thống.
- **Tiền điều kiện:**
  - Quản trị viên đã có tài khoản quản trị.
  - Tài khoản không bị khóa.
- **Luồng chính:**
  1. Quản trị viên mở trang đăng nhập quản trị.
  2. Quản trị viên nhập thông tin đăng nhập và mật khẩu.
  3. Quản trị viên gửi yêu cầu đăng nhập.
  4. Hệ thống kiểm tra thông tin tài khoản và vai trò.
  5. Hệ thống cho phép truy cập khu vực quản trị.
- **Luồng thay thế:**
  - Nếu thông tin đăng nhập sai, hệ thống thông báo đăng nhập không thành công.
  - Nếu tài khoản không có vai trò quản trị viên, hệ thống từ chối truy cập chức năng quản trị.
  - Nếu tài khoản bị khóa, hệ thống thông báo không thể đăng nhập.
- **Hậu điều kiện:**
  - Quản trị viên đăng nhập thành công và có thể sử dụng các chức năng quản trị.

### UC-ADMIN-02: Quản lý tài khoản

- **Tên:** Quản lý tài khoản.
- **Mục tiêu:** Cho phép quản trị viên quản lý tài khoản người dùng và nhân viên ở mức cơ bản.
- **Tiền điều kiện:**
  - Quản trị viên đã đăng nhập.
- **Luồng chính:**
  1. Quản trị viên mở chức năng quản lý tài khoản.
  2. Hệ thống hiển thị danh sách tài khoản.
  3. Quản trị viên chọn tạo mới, cập nhật, khóa, mở khóa hoặc phân vai trò tài khoản.
  4. Quản trị viên nhập hoặc điều chỉnh thông tin cần thiết.
  5. Hệ thống kiểm tra tính hợp lệ của thông tin.
  6. Hệ thống lưu thay đổi.
  7. Hệ thống thông báo thao tác thành công.
- **Luồng thay thế:**
  - Nếu thông tin tài khoản không hợp lệ, hệ thống yêu cầu chỉnh sửa.
  - Nếu tài khoản cần cập nhật không tồn tại, hệ thống thông báo không tìm thấy dữ liệu.
  - Nếu thao tác ảnh hưởng đến quyền truy cập hiện tại, hệ thống yêu cầu quản trị viên xác nhận.
- **Hậu điều kiện:**
  - Thông tin tài khoản được cập nhật theo thao tác của quản trị viên.
  - Quyền truy cập của tài khoản được áp dụng theo vai trò đã thiết lập.

### UC-ADMIN-03: Quản lý danh mục phản ánh

- **Tên:** Quản lý danh mục phản ánh.
- **Mục tiêu:** Cho phép quản trị viên quản lý các danh mục để người dùng chọn khi gửi phản ánh.
- **Tiền điều kiện:**
  - Quản trị viên đã đăng nhập.
- **Luồng chính:**
  1. Quản trị viên mở chức năng quản lý danh mục phản ánh.
  2. Hệ thống hiển thị danh sách danh mục hiện có.
  3. Quản trị viên thêm, sửa hoặc tạm ngưng sử dụng danh mục.
  4. Hệ thống kiểm tra thông tin danh mục.
  5. Hệ thống lưu thay đổi.
  6. Hệ thống thông báo thao tác thành công.
- **Luồng thay thế:**
  - Nếu tên danh mục bị thiếu hoặc không hợp lệ, hệ thống yêu cầu chỉnh sửa.
  - Nếu danh mục đang được sử dụng, hệ thống ưu tiên tạm ngưng thay vì xóa để tránh ảnh hưởng dữ liệu phản ánh.
- **Hậu điều kiện:**
  - Danh mục phản ánh được cập nhật.
  - Người dùng nhìn thấy các danh mục đang khả dụng khi gửi phản ánh.

### UC-ADMIN-04: Quản lý đơn vị xử lý

- **Tên:** Quản lý đơn vị xử lý.
- **Mục tiêu:** Cho phép quản trị viên quản lý các đơn vị phụ trách xử lý phản ánh.
- **Tiền điều kiện:**
  - Quản trị viên đã đăng nhập.
- **Luồng chính:**
  1. Quản trị viên mở chức năng quản lý đơn vị xử lý.
  2. Hệ thống hiển thị danh sách đơn vị xử lý.
  3. Quản trị viên thêm, sửa hoặc tạm ngưng sử dụng đơn vị xử lý.
  4. Quản trị viên gán nhân viên vào đơn vị xử lý nếu cần.
  5. Hệ thống kiểm tra thông tin nhập vào.
  6. Hệ thống lưu thay đổi.
  7. Hệ thống thông báo thao tác thành công.
- **Luồng thay thế:**
  - Nếu thông tin đơn vị không hợp lệ, hệ thống yêu cầu chỉnh sửa.
  - Nếu nhân viên không tồn tại hoặc không phù hợp để gán vào đơn vị, hệ thống từ chối thao tác gán.
  - Nếu đơn vị đang được sử dụng, hệ thống ưu tiên tạm ngưng thay vì xóa.
- **Hậu điều kiện:**
  - Thông tin đơn vị xử lý được cập nhật.
  - Nhân viên được gán vào đơn vị xử lý phù hợp nếu thao tác thành công.

### UC-ADMIN-05: Xem danh sách toàn bộ phản ánh

- **Tên:** Xem danh sách toàn bộ phản ánh.
- **Mục tiêu:** Cho phép quản trị viên theo dõi toàn bộ phản ánh trong hệ thống.
- **Tiền điều kiện:**
  - Quản trị viên đã đăng nhập.
- **Luồng chính:**
  1. Quản trị viên mở danh sách phản ánh.
  2. Hệ thống hiển thị toàn bộ phản ánh trong hệ thống.
  3. Quản trị viên xem thông tin cơ bản như tiêu đề, danh mục, đơn vị xử lý, thời gian gửi và trạng thái.
  4. Quản trị viên chọn một phản ánh để xem chi tiết nếu cần.
- **Luồng thay thế:**
  - Nếu chưa có phản ánh nào trong hệ thống, hệ thống hiển thị danh sách trống.
- **Hậu điều kiện:**
  - Quản trị viên nắm được danh sách phản ánh hiện có trong hệ thống.

### UC-ADMIN-06: Lọc phản ánh

- **Tên:** Lọc phản ánh.
- **Mục tiêu:** Giúp quản trị viên tìm nhanh phản ánh theo trạng thái, danh mục hoặc đơn vị xử lý.
- **Tiền điều kiện:**
  - Quản trị viên đã đăng nhập.
  - Có quyền xem danh sách toàn bộ phản ánh.
- **Luồng chính:**
  1. Quản trị viên mở danh sách phản ánh.
  2. Quản trị viên chọn tiêu chí lọc theo trạng thái, danh mục hoặc đơn vị xử lý.
  3. Hệ thống hiển thị danh sách phản ánh phù hợp.
  4. Quản trị viên xem hoặc mở chi tiết phản ánh cần theo dõi.
- **Luồng thay thế:**
  - Nếu không có phản ánh phù hợp, hệ thống hiển thị thông báo không có dữ liệu.
  - Nếu quản trị viên xóa tiêu chí lọc, hệ thống hiển thị lại danh sách mặc định.
- **Hậu điều kiện:**
  - Quản trị viên xem được danh sách phản ánh theo tiêu chí đã chọn.

### UC-ADMIN-07: Xem Dashboard tổng quan

- **Tên:** Xem Dashboard tổng quan.
- **Mục tiêu:** Cung cấp cho quản trị viên cái nhìn nhanh về tình trạng phản ánh trong hệ thống.
- **Tiền điều kiện:**
  - Quản trị viên đã đăng nhập.
- **Luồng chính:**
  1. Quản trị viên mở dashboard.
  2. Hệ thống hiển thị tổng số phản ánh.
  3. Hệ thống hiển thị số phản ánh theo các trạng thái Chờ tiếp nhận, Đã tiếp nhận, Đang xử lý, Đã xử lý và Từ chối xử lý.
  4. Hệ thống hiển thị biểu đồ thống kê theo danh mục.
  5. Hệ thống hiển thị danh sách 5 phản ánh mới nhất.
  6. Quản trị viên xem thông tin tổng quan để theo dõi tình hình xử lý.
- **Luồng thay thế:**
  - Nếu chưa có dữ liệu phản ánh, hệ thống hiển thị các chỉ số bằng 0 hoặc trạng thái không có dữ liệu.
- **Hậu điều kiện:**
  - Quản trị viên nắm được tình hình phản ánh ở mức tổng quan MVP.

## Overall Use Case Summary

Trong CivicHub MVP, Người dùng là actor khởi tạo luồng nghiệp vụ chính bằng cách đăng ký, đăng nhập, gửi phản ánh, theo dõi trạng thái, nhận thông báo nội bộ và hủy phản ánh khi phản ánh còn ở trạng thái Chờ tiếp nhận.

Nhân viên đơn vị xử lý tiếp nhận các phản ánh thuộc phạm vi đơn vị, chuyển trạng thái sang Đã tiếp nhận, cập nhật tiến độ xử lý qua các trạng thái Đang xử lý, Đã xử lý hoặc Từ chối xử lý, đồng thời ghi chú để người dùng theo dõi.

Quản trị viên duy trì dữ liệu vận hành cơ bản của hệ thống, bao gồm tài khoản, danh mục phản ánh, đơn vị xử lý và dashboard tổng quan. Quản trị viên không tham gia xử lý chi tiết từng phản ánh trong MVP, mà tập trung bảo đảm hệ thống có đủ dữ liệu nền và khả năng theo dõi tình hình chung.

Ba actor phối hợp theo luồng đơn giản: Người dùng gửi phản ánh, Nhân viên tiếp nhận và xử lý, Quản trị viên quản lý cấu hình và giám sát tổng quan. Phạm vi này phù hợp với mục tiêu MVP một tháng, không bao gồm AI, thiết kế cơ sở dữ liệu, API hay các quy trình xử lý phức tạp.
