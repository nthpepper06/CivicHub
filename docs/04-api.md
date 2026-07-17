# 04. Tài liệu thiết kế REST API CivicHub

## 1. Mục tiêu tài liệu API

Tài liệu này mô tả các REST API phục vụ phiên bản MVP của CivicHub dựa trên tài liệu yêu cầu, use case và thiết kế cơ sở dữ liệu đã thống nhất.

Mục tiêu chính:

- Xác định các endpoint cần thiết cho Flutter Mobile và React Admin.
- Mô tả mục đích, phương thức, URL, request, response và quyền truy cập của từng API.
- Giữ phạm vi API đúng với MVP một tháng.
- Không mô tả source code, Spring Boot Controller, SQL, migration hoặc chi tiết triển khai nội bộ.
- Không bổ sung API ngoài phạm vi use case đã chốt.

## 2. Quy ước REST API

### 2.1. Base URL

Toàn bộ API sử dụng tiền tố:

```text
/api
```

Ví dụ:

```text
POST /api/auth/login
```

### 2.2. Định dạng dữ liệu

- Request body sử dụng `application/json`, trừ trường hợp tạo phản ánh có hình ảnh có thể dùng `multipart/form-data`.
- Response mặc định sử dụng `application/json`.
- Thời gian sử dụng định dạng ISO 8601, ví dụ `2026-07-18T10:30:00`.
- Trạng thái phản ánh sử dụng mã tiếng Anh:
  - `PENDING`
  - `RECEIVED`
  - `PROCESSING`
  - `RESOLVED`
  - `REJECTED`
  - `CANCELLED`

### 2.3. Authentication

- Các API cần đăng nhập sử dụng Bearer Token.
- Client gửi token trong header:

```text
Authorization: Bearer {accessToken}
```

### 2.4. Phân quyền

| Role | Mô tả |
| --- | --- |
| `USER` | Người dùng gửi và theo dõi phản ánh. |
| `STAFF` | Nhân viên đơn vị xử lý phản ánh. |
| `ADMIN` | Quản trị viên hệ thống. |

### 2.5. Quy ước phân trang và lọc

Các API danh sách có thể hỗ trợ query parameters:

| Tham số | Ý nghĩa |
| --- | --- |
| `page` | Trang hiện tại, bắt đầu từ 0. |
| `size` | Số bản ghi mỗi trang. |
| `keyword` | Từ khóa tìm kiếm cơ bản. |
| `status` | Lọc theo trạng thái phản ánh. |
| `categoryId` | Lọc theo danh mục. |
| `departmentId` | Lọc theo đơn vị xử lý. |
| `fromDate` | Lọc từ ngày. |
| `toDate` | Lọc đến ngày. |

Không phải API danh sách nào cũng bắt buộc hỗ trợ toàn bộ tham số trên; từng API sẽ mô tả phạm vi phù hợp.

## 3. Authentication API

### 3.1. Đăng ký tài khoản

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Cho phép người dùng tạo tài khoản `USER`. |
| HTTP Method | `POST` |
| URL | `/api/auth/register` |
| Quyền truy cập | Public |

**Request Body**

| Trường | Bắt buộc | Mô tả |
| --- | --- | --- |
| `fullName` | Có | Họ tên người dùng. |
| `email` | Không | Email đăng ký. |
| `phone` | Không | Số điện thoại đăng ký. |
| `password` | Có | Mật khẩu. |

Ghi chú: Người dùng phải cung cấp ít nhất `email` hoặc `phone`.

**Response**

```json
{
  "success": true,
  "message": "Đăng ký tài khoản thành công",
  "data": {
    "id": 1,
    "fullName": "Nguyễn Văn A",
    "email": "user@example.com",
    "phone": "0900000000",
    "role": "USER"
  }
}
```

### 3.2. Đăng nhập

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Xác thực tài khoản và trả về token truy cập. |
| HTTP Method | `POST` |
| URL | `/api/auth/login` |
| Quyền truy cập | Public |

**Request Body**

| Trường | Bắt buộc | Mô tả |
| --- | --- | --- |
| `username` | Có | Email hoặc số điện thoại. |
| `password` | Có | Mật khẩu. |

**Response**

```json
{
  "success": true,
  "message": "Đăng nhập thành công",
  "data": {
    "accessToken": "jwt-token",
    "tokenType": "Bearer",
    "user": {
      "id": 1,
      "fullName": "Nguyễn Văn A",
      "role": "USER",
      "departmentId": null
    }
  }
}
```

### 3.3. Đăng xuất

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Thống nhất luồng đăng xuất trong nghiệp vụ MVP. |
| HTTP Method | `POST` |
| URL | `/api/auth/logout` |
| Quyền truy cập | `USER`, `STAFF`, `ADMIN` |

**Request Body**

Không có.

Ghi chú: MVP sử dụng stateless JWT. Client chịu trách nhiệm xóa `accessToken` khi người dùng đăng xuất. API này không dùng token blacklist và không lưu session trong database.

**Response**

```json
{
  "success": true,
  "message": "Đăng xuất thành công",
  "data": null
}
```

### 3.4. Đổi mật khẩu

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Cho phép tài khoản đang đăng nhập đổi mật khẩu. |
| HTTP Method | `PUT` |
| URL | `/api/auth/change-password` |
| Quyền truy cập | `USER`, `STAFF`, `ADMIN` |

**Request Body**

| Trường | Bắt buộc | Mô tả |
| --- | --- | --- |
| `currentPassword` | Có | Mật khẩu hiện tại. |
| `newPassword` | Có | Mật khẩu mới. |

Ghi chú: Việc xác nhận mật khẩu mới được frontend kiểm tra trước khi gửi request.

**Response**

```json
{
  "success": true,
  "message": "Đổi mật khẩu thành công",
  "data": null
}
```

## 4. User API

### 4.1. Xem thông tin cá nhân

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Lấy thông tin tài khoản của người dùng đang đăng nhập. |
| HTTP Method | `GET` |
| URL | `/api/users/me` |
| Quyền truy cập | `USER`, `STAFF`, `ADMIN` |

**Request Parameters/Body**

Không có.

**Response**

```json
{
  "success": true,
  "message": "Lấy thông tin cá nhân thành công",
  "data": {
    "id": 1,
    "fullName": "Nguyễn Văn A",
    "email": "user@example.com",
    "phone": "0900000000",
    "address": "Quận 1, TP.HCM",
    "role": "USER",
    "departmentId": null,
    "isActive": true
  }
}
```

### 4.2. Cập nhật thông tin cá nhân

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Cập nhật thông tin hồ sơ cơ bản của tài khoản đang đăng nhập. |
| HTTP Method | `PUT` |
| URL | `/api/users/me` |
| Quyền truy cập | `USER`, `STAFF`, `ADMIN` |

**Request Body**

| Trường | Bắt buộc | Mô tả |
| --- | --- | --- |
| `fullName` | Có | Họ tên. |
| `email` | Không | Email liên hệ. |
| `phone` | Không | Số điện thoại liên hệ. |
| `address` | Không | Địa chỉ liên hệ. |

Ghi chú: Sau khi cập nhật, tài khoản vẫn phải có ít nhất `email` hoặc `phone`.

**Response**

```json
{
  "success": true,
  "message": "Cập nhật thông tin cá nhân thành công",
  "data": {
    "id": 1,
    "fullName": "Nguyễn Văn A",
    "email": "user@example.com",
    "phone": "0900000000",
    "address": "Quận 1, TP.HCM"
  }
}
```

## 5. Report API

### 5.1. Tạo phản ánh

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Cho phép người dùng gửi phản ánh mới. |
| HTTP Method | `POST` |
| URL | `/api/reports` |
| Quyền truy cập | `USER` |

**Request Body**

Có thể sử dụng `multipart/form-data` nếu gửi kèm hình ảnh.

| Trường | Bắt buộc | Mô tả |
| --- | --- | --- |
| `title` | Có | Tiêu đề phản ánh. |
| `description` | Có | Nội dung mô tả. |
| `categoryId` | Có | Danh mục phản ánh. |
| `locationText` | Có | Mô tả vị trí. |
| `latitude` | Không | Vĩ độ nếu có. |
| `longitude` | Không | Kinh độ nếu có. |
| `images` | Không | Danh sách hình ảnh đính kèm. |

**Response**

```json
{
  "success": true,
  "message": "Gửi phản ánh thành công",
  "data": {
    "id": 100,
    "reportCode": "CH-2026-000001",
    "title": "Đèn đường bị hỏng",
    "status": "PENDING",
    "createdAt": "2026-07-18T10:30:00"
  }
}
```

### 5.2. Xem danh sách phản ánh của tôi

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Lấy danh sách phản ánh do người dùng hiện tại đã gửi. |
| HTTP Method | `GET` |
| URL | `/api/reports/my` |
| Quyền truy cập | `USER` |

**Request Parameters**

| Tham số | Bắt buộc | Mô tả |
| --- | --- | --- |
| `page` | Không | Trang hiện tại, bắt đầu từ 0. |
| `size` | Không | Số bản ghi mỗi trang. |
| `status` | Không | Lọc theo trạng thái. |
| `keyword` | Không | Tìm theo tiêu đề, nội dung hoặc mã phản ánh. |

**Response**

```json
{
  "success": true,
  "message": "Lấy danh sách phản ánh thành công",
  "data": {
    "items": [
      {
        "id": 100,
        "reportCode": "CH-2026-000001",
        "title": "Đèn đường bị hỏng",
        "categoryName": "Chiếu sáng công cộng",
        "status": "PENDING",
        "createdAt": "2026-07-18T10:30:00"
      }
    ],
    "page": 0,
    "size": 10,
    "totalItems": 1,
    "totalPages": 1
  }
}
```

### 5.3. Xem chi tiết phản ánh

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Xem thông tin chi tiết của một phản ánh. |
| HTTP Method | `GET` |
| URL | `/api/reports/{id}` |
| Quyền truy cập | `USER`, `STAFF`, `ADMIN` |

**Request Parameters**

| Tham số | Bắt buộc | Mô tả |
| --- | --- | --- |
| `id` | Có | ID phản ánh trên URL. |

Ghi chú quyền truy cập:

- `USER` chỉ xem phản ánh của chính mình.
- `STAFF` chỉ xem phản ánh thuộc phạm vi đơn vị.
- `ADMIN` có thể xem toàn bộ phản ánh.

**Response**

```json
{
  "success": true,
  "message": "Lấy chi tiết phản ánh thành công",
  "data": {
    "id": 100,
    "reportCode": "CH-2026-000001",
    "title": "Đèn đường bị hỏng",
    "description": "Đèn đường trước nhà văn hóa không sáng.",
    "categoryId": 2,
    "categoryName": "Chiếu sáng công cộng",
    "departmentId": 3,
    "departmentName": "Đơn vị chiếu sáng công cộng",
    "locationText": "Đường A, phường B",
    "latitude": 10.1234567,
    "longitude": 106.1234567,
    "status": "PENDING",
    "images": [
      {
        "id": 1,
        "imageUrl": "https://example.com/image.jpg"
      }
    ],
    "histories": [],
    "createdAt": "2026-07-18T10:30:00",
    "updatedAt": "2026-07-18T10:30:00"
  }
}
```

### 5.4. Hủy phản ánh

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Cho phép người dùng hủy phản ánh khi phản ánh còn ở trạng thái `PENDING`. |
| HTTP Method | `PATCH` |
| URL | `/api/reports/{id}/cancel` |
| Quyền truy cập | `USER` |

**Request Parameters/Body**

| Tham số | Bắt buộc | Mô tả |
| --- | --- | --- |
| `id` | Có | ID phản ánh trên URL. |

Request body không bắt buộc.

**Response**

```json
{
  "success": true,
  "message": "Hủy phản ánh thành công",
  "data": {
    "id": 100,
    "reportCode": "CH-2026-000001",
    "status": "CANCELLED",
    "cancelledAt": "2026-07-18T11:00:00"
  }
}
```

## 6. Notification API

### 6.1. Xem danh sách thông báo

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Lấy danh sách thông báo nội bộ của người dùng đang đăng nhập. |
| HTTP Method | `GET` |
| URL | `/api/notifications` |
| Quyền truy cập | `USER` |

**Request Parameters**

| Tham số | Bắt buộc | Mô tả |
| --- | --- | --- |
| `page` | Không | Trang hiện tại, bắt đầu từ 0. |
| `size` | Không | Số bản ghi mỗi trang. |
| `isRead` | Không | Lọc theo trạng thái đã đọc/chưa đọc. |

**Response**

```json
{
  "success": true,
  "message": "Lấy danh sách thông báo thành công",
  "data": {
    "items": [
      {
        "id": 10,
        "reportId": 100,
        "reportCode": "CH-2026-000001",
        "title": "Phản ánh đã được tiếp nhận",
        "message": "Phản ánh CH-2026-000001 đã được tiếp nhận.",
        "isRead": false,
        "createdAt": "2026-07-18T11:15:00"
      }
    ],
    "page": 0,
    "size": 10,
    "totalItems": 1,
    "totalPages": 1
  }
}
```

### 6.2. Đánh dấu đã đọc thông báo

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Đánh dấu một thông báo của người dùng hiện tại là đã đọc. |
| HTTP Method | `PATCH` |
| URL | `/api/notifications/{id}/read` |
| Quyền truy cập | `USER` |

**Request Parameters/Body**

| Tham số | Bắt buộc | Mô tả |
| --- | --- | --- |
| `id` | Có | ID thông báo trên URL. |

Request body không bắt buộc.

**Response**

```json
{
  "success": true,
  "message": "Đã đánh dấu thông báo là đã đọc",
  "data": {
    "id": 10,
    "isRead": true,
    "readAt": "2026-07-18T11:30:00"
  }
}
```

## 7. Staff API

### 7.1. Xem danh sách phản ánh thuộc phạm vi xử lý

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Cho phép nhân viên xem danh sách phản ánh thuộc đơn vị của mình. |
| HTTP Method | `GET` |
| URL | `/api/staff/reports` |
| Quyền truy cập | `STAFF` |

**Request Parameters**

| Tham số | Bắt buộc | Mô tả |
| --- | --- | --- |
| `page` | Không | Trang hiện tại, bắt đầu từ 0. |
| `size` | Không | Số bản ghi mỗi trang. |
| `status` | Không | Lọc theo trạng thái. |
| `categoryId` | Không | Lọc theo danh mục. |
| `fromDate` | Không | Lọc từ ngày gửi. |
| `toDate` | Không | Lọc đến ngày gửi. |

**Response**

```json
{
  "success": true,
  "message": "Lấy danh sách phản ánh thành công",
  "data": {
    "items": [
      {
        "id": 100,
        "reportCode": "CH-2026-000001",
        "title": "Đèn đường bị hỏng",
        "categoryName": "Chiếu sáng công cộng",
        "status": "PENDING",
        "createdAt": "2026-07-18T10:30:00"
      }
    ],
    "page": 0,
    "size": 10,
    "totalItems": 1,
    "totalPages": 1
  }
}
```

### 7.2. Tiếp nhận phản ánh

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Cho phép nhân viên tiếp nhận phản ánh đang ở trạng thái `PENDING`. |
| HTTP Method | `PATCH` |
| URL | `/api/staff/reports/{id}/receive` |
| Quyền truy cập | `STAFF` |

**Request Parameters/Body**

| Tham số | Bắt buộc | Mô tả |
| --- | --- | --- |
| `id` | Có | ID phản ánh trên URL. |

Request body không bắt buộc.

**Response**

```json
{
  "success": true,
  "message": "Tiếp nhận phản ánh thành công",
  "data": {
    "id": 100,
    "reportCode": "CH-2026-000001",
    "status": "RECEIVED",
    "assignedStaffId": 5,
    "receivedAt": "2026-07-18T11:15:00"
  }
}
```

### 7.3. Cập nhật trạng thái phản ánh

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Cho phép nhân viên cập nhật tiến độ hoặc kết quả xử lý phản ánh. |
| HTTP Method | `PATCH` |
| URL | `/api/staff/reports/{id}/status` |
| Quyền truy cập | `STAFF` |

**Request Parameters**

| Tham số | Bắt buộc | Mô tả |
| --- | --- | --- |
| `id` | Có | ID phản ánh trên URL. |

**Request Body**

| Trường | Bắt buộc | Mô tả |
| --- | --- | --- |
| `status` | Có | Trạng thái mới: `PROCESSING`, `RESOLVED` hoặc `REJECTED`. |
| `note` | Bắt buộc khi `status = RESOLVED` hoặc `status = REJECTED` | Ghi chú xử lý, kết quả xử lý hoặc lý do từ chối. Không bắt buộc khi `status = PROCESSING`. |

Ghi chú: API này tuân thủ luồng trạng thái hợp lệ:

- `RECEIVED -> PROCESSING`
- `RECEIVED -> REJECTED`
- `PROCESSING -> RESOLVED`
- `PROCESSING -> REJECTED`

**Response**

```json
{
  "success": true,
  "message": "Cập nhật trạng thái phản ánh thành công",
  "data": {
    "id": 100,
    "reportCode": "CH-2026-000001",
    "status": "PROCESSING",
    "updatedAt": "2026-07-18T11:45:00"
  }
}
```

### 7.4. Xem công việc xử lý cá nhân

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Lấy danh sách phản ánh đã được gán cho nhân viên đang đăng nhập. |
| HTTP Method | `GET` |
| URL | `/api/staff/my-reports` |
| Quyền truy cập | `STAFF` |

**Request Parameters**

| Tham số | Bắt buộc | Mô tả |
| --- | --- | --- |
| `page` | Không | Trang hiện tại, bắt đầu từ 0. |
| `size` | Không | Số bản ghi mỗi trang. |
| `status` | Không | Lọc theo trạng thái. |

**Response**

```json
{
  "success": true,
  "message": "Lấy danh sách công việc xử lý thành công",
  "data": {
    "items": [
      {
        "id": 100,
        "reportCode": "CH-2026-000001",
        "title": "Đèn đường bị hỏng",
        "status": "PROCESSING",
        "updatedAt": "2026-07-18T11:45:00"
      }
    ],
    "page": 0,
    "size": 10,
    "totalItems": 1,
    "totalPages": 1
  }
}
```

## 8. Admin API

### 8.1. Xem dashboard tổng quan

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Lấy số liệu tổng quan dashboard MVP cho quản trị viên. |
| HTTP Method | `GET` |
| URL | `/api/admin/dashboard` |
| Quyền truy cập | `ADMIN` |

**Request Parameters/Body**

Không có.

**Response**

```json
{
  "success": true,
  "message": "Lấy dashboard thành công",
  "data": {
    "totalReports": 120,
    "pendingReports": 10,
    "receivedReports": 20,
    "processingReports": 30,
    "resolvedReports": 45,
    "rejectedReports": 10,
    "cancelledReports": 5,
    "reportsByCategory": [
      {
        "categoryId": 2,
        "categoryName": "Chiếu sáng công cộng",
        "total": 18
      }
    ],
    "latestReports": [
      {
        "id": 100,
        "reportCode": "CH-2026-000001",
        "title": "Đèn đường bị hỏng",
        "status": "PENDING",
        "createdAt": "2026-07-18T10:30:00"
      }
    ]
  }
}
```

### 8.2. Xem danh sách tài khoản

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Quản trị viên xem danh sách tài khoản trong hệ thống. |
| HTTP Method | `GET` |
| URL | `/api/admin/users` |
| Quyền truy cập | `ADMIN` |

**Request Parameters**

| Tham số | Bắt buộc | Mô tả |
| --- | --- | --- |
| `page` | Không | Trang hiện tại, bắt đầu từ 0. |
| `size` | Không | Số bản ghi mỗi trang. |
| `role` | Không | Lọc theo `USER`, `STAFF`, `ADMIN`. |
| `keyword` | Không | Tìm theo họ tên, email hoặc số điện thoại. |
| `isActive` | Không | Lọc theo trạng thái hoạt động. |

**Response**

Trả về danh sách tài khoản theo format phân trang chuẩn.

### 8.3. Tạo tài khoản

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Quản trị viên tạo tài khoản, chủ yếu cho nhân viên xử lý hoặc quản trị viên. |
| HTTP Method | `POST` |
| URL | `/api/admin/users` |
| Quyền truy cập | `ADMIN` |

**Request Body**

| Trường | Bắt buộc | Mô tả |
| --- | --- | --- |
| `fullName` | Có | Họ tên. |
| `email` | Không | Email. |
| `phone` | Không | Số điện thoại. |
| `password` | Có | Mật khẩu ban đầu. |
| `role` | Có | `USER`, `STAFF` hoặc `ADMIN`. |
| `departmentId` | Bắt buộc nếu `role = STAFF` | Đơn vị xử lý của nhân viên. |
| `isActive` | Có | Trạng thái hoạt động. |

Ghi chú: Tài khoản phải có ít nhất `email` hoặc `phone`.

**Response**

Trả về thông tin tài khoản vừa tạo, không trả về mật khẩu.

### 8.4. Cập nhật tài khoản

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Quản trị viên cập nhật thông tin, vai trò, đơn vị hoặc trạng thái tài khoản. |
| HTTP Method | `PUT` |
| URL | `/api/admin/users/{id}` |
| Quyền truy cập | `ADMIN` |

**Request Parameters**

| Tham số | Bắt buộc | Mô tả |
| --- | --- | --- |
| `id` | Có | ID tài khoản trên URL. |

**Request Body**

| Trường | Bắt buộc | Mô tả |
| --- | --- | --- |
| `fullName` | Có | Họ tên. |
| `email` | Không | Email. |
| `phone` | Không | Số điện thoại. |
| `role` | Có | Vai trò tài khoản. |
| `departmentId` | Bắt buộc nếu `role = STAFF` | Đơn vị xử lý. |
| `isActive` | Có | Khóa hoặc mở khóa tài khoản. |

**Response**

Trả về thông tin tài khoản sau khi cập nhật.

### 8.5. Xem danh sách danh mục

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Quản trị viên xem danh sách danh mục phản ánh. |
| HTTP Method | `GET` |
| URL | `/api/admin/categories` |
| Quyền truy cập | `ADMIN` |

**Request Parameters**

| Tham số | Bắt buộc | Mô tả |
| --- | --- | --- |
| `page` | Không | Trang hiện tại, bắt đầu từ 0. |
| `size` | Không | Số bản ghi mỗi trang. |
| `keyword` | Không | Tìm theo mã hoặc tên danh mục. |
| `isActive` | Không | Lọc danh mục còn sử dụng hoặc tạm ngưng. |

**Response**

Trả về danh sách danh mục theo format phân trang chuẩn.

### 8.6. Tạo danh mục

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Quản trị viên tạo danh mục phản ánh mới. |
| HTTP Method | `POST` |
| URL | `/api/admin/categories` |
| Quyền truy cập | `ADMIN` |

**Request Body**

| Trường | Bắt buộc | Mô tả |
| --- | --- | --- |
| `code` | Có | Mã danh mục. |
| `name` | Có | Tên danh mục. |
| `description` | Không | Mô tả danh mục. |
| `departmentId` | Có | Đơn vị phụ trách danh mục. |
| `isActive` | Có | Trạng thái sử dụng. |

**Response**

Trả về thông tin danh mục vừa tạo.

### 8.7. Cập nhật danh mục

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Quản trị viên cập nhật hoặc tạm ngưng danh mục phản ánh. |
| HTTP Method | `PUT` |
| URL | `/api/admin/categories/{id}` |
| Quyền truy cập | `ADMIN` |

**Request Parameters**

| Tham số | Bắt buộc | Mô tả |
| --- | --- | --- |
| `id` | Có | ID danh mục trên URL. |

**Request Body**

| Trường | Bắt buộc | Mô tả |
| --- | --- | --- |
| `code` | Có | Mã danh mục. |
| `name` | Có | Tên danh mục. |
| `description` | Không | Mô tả danh mục. |
| `departmentId` | Có | Đơn vị phụ trách. |
| `isActive` | Có | Trạng thái sử dụng. |

**Response**

Trả về thông tin danh mục sau khi cập nhật.

### 8.8. Xem danh sách đơn vị xử lý

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Quản trị viên xem danh sách đơn vị xử lý. |
| HTTP Method | `GET` |
| URL | `/api/admin/departments` |
| Quyền truy cập | `ADMIN` |

**Request Parameters**

| Tham số | Bắt buộc | Mô tả |
| --- | --- | --- |
| `page` | Không | Trang hiện tại, bắt đầu từ 0. |
| `size` | Không | Số bản ghi mỗi trang. |
| `keyword` | Không | Tìm theo mã hoặc tên đơn vị. |
| `isActive` | Không | Lọc đơn vị còn hoạt động hoặc tạm ngưng. |

**Response**

Trả về danh sách đơn vị xử lý theo format phân trang chuẩn.

### 8.9. Tạo đơn vị xử lý

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Quản trị viên tạo đơn vị xử lý mới. |
| HTTP Method | `POST` |
| URL | `/api/admin/departments` |
| Quyền truy cập | `ADMIN` |

**Request Body**

| Trường | Bắt buộc | Mô tả |
| --- | --- | --- |
| `code` | Có | Mã đơn vị. |
| `name` | Có | Tên đơn vị. |
| `description` | Không | Mô tả phạm vi phụ trách. |
| `isActive` | Có | Trạng thái hoạt động. |

**Response**

Trả về thông tin đơn vị xử lý vừa tạo.

### 8.10. Cập nhật đơn vị xử lý

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Quản trị viên cập nhật hoặc tạm ngưng đơn vị xử lý. |
| HTTP Method | `PUT` |
| URL | `/api/admin/departments/{id}` |
| Quyền truy cập | `ADMIN` |

**Request Parameters**

| Tham số | Bắt buộc | Mô tả |
| --- | --- | --- |
| `id` | Có | ID đơn vị trên URL. |

**Request Body**

| Trường | Bắt buộc | Mô tả |
| --- | --- | --- |
| `code` | Có | Mã đơn vị. |
| `name` | Có | Tên đơn vị. |
| `description` | Không | Mô tả phạm vi phụ trách. |
| `isActive` | Có | Trạng thái hoạt động. |

**Response**

Trả về thông tin đơn vị xử lý sau khi cập nhật.

### 8.11. Xem danh sách toàn bộ phản ánh

| Thuộc tính | Nội dung |
| --- | --- |
| Mục đích | Quản trị viên xem và lọc toàn bộ phản ánh trong hệ thống. |
| HTTP Method | `GET` |
| URL | `/api/admin/reports` |
| Quyền truy cập | `ADMIN` |

**Request Parameters**

| Tham số | Bắt buộc | Mô tả |
| --- | --- | --- |
| `page` | Không | Trang hiện tại, bắt đầu từ 0. |
| `size` | Không | Số bản ghi mỗi trang. |
| `status` | Không | Lọc theo trạng thái. |
| `categoryId` | Không | Lọc theo danh mục. |
| `departmentId` | Không | Lọc theo đơn vị xử lý. |
| `keyword` | Không | Tìm theo tiêu đề, nội dung hoặc mã phản ánh. |

**Response**

Trả về danh sách toàn bộ phản ánh theo format phân trang chuẩn.

## 9. Response format chuẩn

### 9.1. Response thành công

```json
{
  "success": true,
  "message": "Thao tác thành công",
  "data": {}
}
```

### 9.2. Response lỗi

```json
{
  "success": false,
  "message": "Dữ liệu không hợp lệ",
  "errors": [
    {
      "field": "email",
      "message": "Email đã được sử dụng"
    }
  ]
}
```

### 9.3. Response phân trang

```json
{
  "success": true,
  "message": "Lấy danh sách thành công",
  "data": {
    "items": [],
    "page": 0,
    "size": 10,
    "totalItems": 0,
    "totalPages": 0
  }
}
```

## 10. HTTP Status Code

| HTTP Status | Ý nghĩa | Trường hợp sử dụng |
| --- | --- | --- |
| `200 OK` | Thành công | Lấy dữ liệu, cập nhật, đăng xuất, đổi mật khẩu thành công. |
| `201 Created` | Tạo mới thành công | Đăng ký, tạo phản ánh, tạo tài khoản, tạo danh mục, tạo đơn vị. |
| `400 Bad Request` | Request không hợp lệ | Thiếu dữ liệu bắt buộc, sai định dạng, trạng thái chuyển đổi không hợp lệ. |
| `401 Unauthorized` | Chưa xác thực | Thiếu token, token không hợp lệ hoặc hết hạn. |
| `403 Forbidden` | Không có quyền | Role không phù hợp hoặc truy cập dữ liệu ngoài phạm vi. |
| `404 Not Found` | Không tìm thấy | Không tìm thấy tài khoản, phản ánh, danh mục, đơn vị hoặc thông báo. |
| `409 Conflict` | Xung đột dữ liệu | Email, phone, code hoặc report code bị trùng. |
| `500 Internal Server Error` | Lỗi hệ thống | Lỗi không mong muốn phía server. |

## 11. Bảng mapping Use Case ↔ API

| Use Case | API liên quan |
| --- | --- |
| UC-USER-01: Đăng ký tài khoản | `POST /api/auth/register` |
| UC-USER-02: Đăng nhập | `POST /api/auth/login` |
| UC-USER-03: Đăng xuất | `POST /api/auth/logout` |
| UC-USER-04: Quản lý thông tin cá nhân | `GET /api/users/me`, `PUT /api/users/me` |
| UC-USER-05: Đổi mật khẩu | `PUT /api/auth/change-password` |
| UC-USER-06: Gửi phản ánh | `POST /api/reports` |
| UC-USER-07: Xem danh sách phản ánh đã gửi | `GET /api/reports/my` |
| UC-USER-08: Xem chi tiết phản ánh | `GET /api/reports/{id}` |
| UC-USER-09: Tìm kiếm và lọc phản ánh | `GET /api/reports/my` |
| UC-USER-10: Hủy phản ánh | `PATCH /api/reports/{id}/cancel` |
| UC-USER-11: Xem thông báo trong ứng dụng | `GET /api/notifications`, `PATCH /api/notifications/{id}/read` |
| UC-STAFF-01: Đăng nhập trang quản trị | `POST /api/auth/login`, `POST /api/auth/logout` |
| UC-STAFF-02: Xem danh sách phản ánh thuộc phạm vi xử lý | `GET /api/staff/reports` |
| UC-STAFF-03: Lọc phản ánh cần xử lý | `GET /api/staff/reports` |
| UC-STAFF-04: Xem chi tiết phản ánh | `GET /api/reports/{id}` |
| UC-STAFF-05: Tiếp nhận phản ánh | `PATCH /api/staff/reports/{id}/receive` |
| UC-STAFF-06: Cập nhật trạng thái xử lý phản ánh | `PATCH /api/staff/reports/{id}/status` |
| UC-STAFF-07: Xem công việc xử lý cá nhân | `GET /api/staff/my-reports` |
| UC-ADMIN-01: Đăng nhập trang quản trị | `POST /api/auth/login`, `POST /api/auth/logout` |
| UC-ADMIN-02: Quản lý tài khoản | `GET /api/admin/users`, `POST /api/admin/users`, `PUT /api/admin/users/{id}` |
| UC-ADMIN-03: Quản lý danh mục phản ánh | `GET /api/admin/categories`, `POST /api/admin/categories`, `PUT /api/admin/categories/{id}` |
| UC-ADMIN-04: Quản lý đơn vị xử lý | `GET /api/admin/departments`, `POST /api/admin/departments`, `PUT /api/admin/departments/{id}` |
| UC-ADMIN-05: Xem danh sách toàn bộ phản ánh | `GET /api/admin/reports`, `GET /api/reports/{id}` |
| UC-ADMIN-06: Lọc phản ánh | `GET /api/admin/reports` |
| UC-ADMIN-07: Xem Dashboard tổng quan | `GET /api/admin/dashboard` |
