# Weekly Todo App - Hướng dẫn sử dụng

## Tính năng mới: Todo theo tuần

Ứng dụng đã được mở rộng với tính năng **Todo theo tuần** dành cho couple. Tính năng này cho phép bạn và người yêu lập kế hoạch công việc theo từng ngày trong tuần.

## Cách sử dụng

### 1. Truy cập Weekly Todo
- Từ trang Home, nhấn vào icon 📅 (calendar_view_week) trên thanh AppBar
- Hoặc truy cập trực tiếp qua URL `/weekly`

### 2. Thêm task mới
1. **Chọn ngày**: Nhấn vào chip ngày (Thứ 2, Thứ 3, ..., Chủ nhật)
2. **Nhập task**: Gõ nội dung task vào ô input
3. **Thêm**: Nhấn nút "Thêm" hoặc Enter

### 3. Quản lý tasks
- **Đánh dấu hoàn thành**: Nhấn vào checkbox bên cạnh task
- **Xóa task**: Nhấn vào icon 🗑️ bên cạnh task
- **Xem chi tiết**: Nhấn vào card ngày để mở rộng xem danh sách tasks

### 4. Điều hướng tuần
- **Tuần trước**: Nhấn ← trên thanh điều hướng
- **Tuần sau**: Nhấn → trên thanh điều hướng
- **Tuần hiện tại**: Nhấn vào nút "Hôm nay" (nếu có)

## Cấu trúc dữ liệu

### WeeklyTask Model
```dart
class WeeklyTask {
  final String id;
  final String coupleId;
  final String title;
  final String? note;
  final DateTime weekStart;  // Ngày đầu tuần (Thứ 2)
  final DateTime weekEnd;    // Ngày cuối tuần (Chủ nhật)
  final int dayOfWeek;       // 1-7 (Thứ 2 = 1, Chủ nhật = 7)
  final bool isDone;
  final String createdBy;    // User ID của người tạo
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Database Schema
Bảng `weekly_tasks` với các trường:
- `id`: UUID primary key
- `couple_id`: ID của couple
- `title`: Tiêu đề task
- `note`: Ghi chú (optional)
- `week_start`: Ngày đầu tuần
- `week_end`: Ngày cuối tuần
- `day_of_week`: Ngày trong tuần (1-7)
- `is_done`: Trạng thái hoàn thành
- `created_by`: User tạo task
- `created_at`, `updated_at`: Timestamps

## Migration Database

Để sử dụng tính năng này, bạn cần chạy migration:

```sql
-- Chạy file migration_005_weekly_tasks.sql trong Supabase SQL Editor
```

## Tính năng nổi bật

1. **Group theo ngày**: Tasks được nhóm theo từng ngày trong tuần
2. **Điều hướng tuần**: Dễ dàng chuyển đổi giữa các tuần
3. **Thống kê**: Hiển thị số lượng tasks hoàn thành/tổng số
4. **Real-time sync**: Cập nhật real-time giữa các thiết bị
5. **Responsive UI**: Giao diện thân thiện, dễ sử dụng

## So sánh với Todo thường

| Tính năng | Todo thường | Todo tuần |
|-----------|-------------|-----------|
| Cấu trúc | Danh sách đơn giản | Nhóm theo ngày trong tuần |
| Thời gian | Không giới hạn | Theo tuần cụ thể |
| Mục đích | Ghi nhớ công việc | Lập kế hoạch tuần |
| Phù hợp | Công việc hàng ngày | Kế hoạch dài hạn |

## Lưu ý

- Tasks được lưu theo tuần, mỗi tuần có thể có nhiều tasks khác nhau
- Người dùng có thể xem và chỉnh sửa tasks của cả couple
- Tasks được đồng bộ real-time giữa các thiết bị
- Có thể thêm ghi chú cho từng task (tính năng có thể mở rộng)
