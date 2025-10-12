# Tính năng Edit Task - Hướng dẫn sử dụng

## Cách edit task

### 1. **Long Press (Giữ lâu)**
- Giữ lâu vào task để vào chế độ edit
- Có haptic feedback khi bắt đầu edit

### 2. **Nhấn nút Edit**
- Nhấn vào icon ✏️ bên cạnh task
- Tooltip hiển thị "Chỉnh sửa"

### 3. **Chế độ Edit**
Khi vào chế độ edit, bạn sẽ thấy:
- **Tiêu đề**: TextField để chỉnh sửa tên task
- **Ghi chú**: TextField để thêm/chỉnh sửa ghi chú
- **Nút Hủy**: Quay lại chế độ bình thường
- **Nút Lưu**: Lưu thay đổi

### 4. **Thao tác trong chế độ Edit**
- **Autofocus**: Cursor tự động focus vào ô tiêu đề
- **Enter**: Nhấn Enter để lưu (trong ô tiêu đề)
- **Hủy**: Nhấn nút Hủy hoặc icon ❌
- **Lưu**: Nhấn nút Lưu hoặc icon 💾

## Tính năng khác

### **Toggle Task**
- **Tap vào task**: Toggle checkbox (hoàn thành/chưa hoàn thành)
- **Tap vào checkbox**: Toggle trực tiếp
- **Haptic feedback**: Rung nhẹ khi toggle

### **Xóa Task**
- **Nhấn icon 🗑️**: Hiển thị dialog xác nhận
- **Dialog xác nhận**: "Bạn có chắc muốn xóa task [tên]?"
- **Hủy/Xóa**: Chọn hành động trong dialog

### **Thêm Task với Ghi chú**
- **Nhấn icon ⬇️**: Mở rộng để thêm ghi chú
- **Ô ghi chú**: Nhập ghi chú tùy chọn
- **Enter**: Lưu task (trong ô ghi chú)

## UI/UX Improvements

### **Animations**
- **Edit mode**: AnimatedContainer với duration 300ms
- **ListTile**: AnimatedContainer với duration 200ms
- **Smooth transitions**: Curves.easeInOut

### **Visual Feedback**
- **Haptic feedback**: 
  - Light impact: Edit, toggle, cancel
  - Medium impact: Save
- **Icons**: 
  - ✏️ Edit
  - 🗑️ Delete  
  - 💾 Save
  - ❌ Cancel
  - 📝 Note

### **Styling**
- **Completed tasks**: 
  - Text strikethrough
  - Grey color
  - Normal font weight
- **Active tasks**:
  - Normal color
  - Medium font weight
- **Notes**:
  - Smaller font size (13px)
  - Grey color
  - Top padding

## Keyboard Shortcuts

- **Enter**: Lưu task (trong edit mode)
- **Escape**: Hủy edit (có thể implement thêm)

## Tips & Tricks

1. **Quick toggle**: Tap vào task để toggle nhanh
2. **Long press**: Giữ lâu để edit (không cần nhấn icon)
3. **Auto-save**: Chỉ lưu khi có thay đổi
4. **Note support**: Có thể thêm ghi chú khi tạo task mới
5. **Confirmation**: Xóa task có dialog xác nhận

## Technical Details

### **State Management**
- `_isEditing`: Boolean để track edit mode
- `_titleController`: TextEditingController cho tiêu đề
- `_noteController`: TextEditingController cho ghi chú

### **Events**
- `UpdateWeeklyTask`: Event để update task
- `ToggleWeeklyTask`: Event để toggle trạng thái
- `DeleteWeeklyTask`: Event để xóa task

### **Performance**
- Controllers được dispose khi widget bị destroy
- AnimatedContainer với duration hợp lý
- Haptic feedback không block UI
