const fs=require('fs'),path=require('path');const m=require('./live-manifest.json');
const root=__dirname;const code=s=>'```sql\n'+s.trim()+'\n```\n';
let s=`# Kịch bản demo live DBI202 — SQL và lời thoại

Chuẩn bị cho ngày 06/11/2026, trước 30 sinh viên và giảng viên chấm thi.
Thời lượng chính khoảng 15 phút; có thể bỏ phần trigger mở rộng để giảm 2 phút.
Đã diễn tập trên PostgreSQL 18.6: **20/20 kiểm tra PASS**. Kết quả chi tiết tại
VERIFIED_LIVE.json, log tại rehearsal.log. Đây là bộ live riêng dùng schema
dbi202_live, không trộn với dbi202_demo của buổi thực hành trước.

## 1. Chuẩn bị trước khi bước lên thuyết trình

| Thời điểm | Thao tác | Mục đích |
| --- | --- | --- |
| Tập ở nhà | Chọn database học tập riêng, chạy toàn bộ kịch bản một lần | Ghi nhớ số liệu và kiểm tra kết nối |
| Trước buổi thi | Dùng một database học tập khác, chạy riêng 00_setup_demo.sql | Có 17 bảng và 10 function; chưa nạp dữ liệu để INSERT live |
| Trước khi nói | Mở một Query Tool đúng database, đặt search_path | Tránh chạy nhầm schema hoặc tab khác kết nối |
| Chuẩn bị màn hình | Cỡ chữ SQL khoảng 16–18, chỉ giữ cửa sổ cần thiết | Hàng ghế sau đọc được code và kết quả |
| Chuẩn bị tài liệu | Mở sẵn 01, 06, 07, 08 và các file flow02–05 | Không gõ câu dài khi đang nói |
| Dự phòng | Giữ VERIFIED_LIVE.json và phần kết quả mong đợi của tài liệu | Nếu máy chiếu hoặc kết nối trục trặc, vẫn giải thích được kết quả đã kiểm chứng |

00_setup_demo.sql đã chứa đủ schema và function. Không chạy thêm init_schema.sql
của repo. Không chạy lại00 nếu schema đã có, cũng không tự DROP/TRUNCATE để reset.
Nếu đã tập hết trên một database, dùng database học tập mới cho lượt diễn tập khác.

Mở đầu bằng câu kiểm tra này, sau đó phóng lớn Data Output:

`;
s+=code('SET search_path TO dbi202_live;\nSELECT current_database() AS database_demo, current_schema() AS schema_demo;');
s+=`
**Lời mở đầu, 25 giây:**

> “Thưa thầy/cô và các bạn, em xin demo cơ sở dữ liệu xử lý đơn hàng đa kênh.
> Em sẽ đi từ dữ liệu kênh bán, đơn hàng, tồn kho đến đóng gói và giao hàng.
> Ngoài trường hợp đúng, em sẽ cố tình đưa dữ liệu sai để chứng minh các quy tắc
> nào được database bảo vệ. Dữ liệu hôm nay là dữ liệu mô phỏng đồng bộ từ kênh.”

## 2. Lịch demo và file phải mở

| Thời gian | Màn hình/thao tác | File |
| --- | --- | --- |
| 00:00–00:40 | Giới thiệu và kiểm tra database/schema | Query ngắn phía trên |
| 00:40–02:20 | INSERT theo thứ tự cha → con | 01_insert_theo_tang.sql |
| 02:20–04:20 | JOIN, GROUP BY, COUNT, SUM | 06_queries.sql: Q1–Q3 |
| 04:20–06:20 | PK, FK, CHECK; thêm UNIQUE/NOT NULL nếu đủ giờ | 07_constraints_live.sql |
| 06:20–07:20 | Giữ hàng và thử gọi lặp | 02_reserve.sql |
| 07:20–08:50 | Chia2 kiện, dùng vật liệu, duyệt | 03_pack_and_approve.sql |
| 08:50–10:10 | Trigger tạm chặn dòng sai đơn, rồi rollback | 08_trigger_minh_hoa.sql |
| 10:10–12:00 | Bàn giao2 kiện và giao thành công | 04_handover.sql, 05_deliver.sql |
| 12:00–13:30 | Phí đóng gói, đối chiếu ledger, giá trị hàng đã giao | 06_queries.sql: Q5–Q7 |
| 13:30–15:00 | Kết luận và trả lời câu hỏi | Phần hỏi đáp cuối tài liệu |

Số file không phải thứ tự chạy: 06 chứa query dùng nhiều thời điểm; 07 là ca lỗi
tương tác; 08 phải chạy sau khi đã tạo kiện. Không chọn toàn bộ thư mục rồi chạy
theo tên file.

## 3. INSERT dữ liệu: vì sao phải cha trước, con sau?

Chạy từng nhóm A→E trong01_insert_theo_tang.sql. File có BEGIN ở đầu và COMMIT
ở cuối; chỉ commit sau khi tất cả INSERT thành công. Nếu đang thiếu thời gian,
chạy cả file rồi giải thích các nhóm thay vì gõ lại.

| Tầng | Thứ tự | Vì sao? |
| --- | --- | --- |
| A — độc lập | SALES_CHANNEL, WAREHOUSE, PRODUCT, STAFF, SHIPPING_CARRIER, BOX_TEMPLATE, PACKAGING_MATERIAL | Chưa cần mã cha từ bảng khác |
| B — phụ thuộc nguồn bán | SALES_ACCOUNT → CUSTOMER | Shop cần channel_id; khách cần sales_account_id |
| C — tồn và sổ biến động | INVENTORY → INVENTORY_TRANSACTION, thông qua stock_movement | Tồn cần kho/sản phẩm; lịch sử cần đúng cặp tồn |
| D — đơn và dòng | CUSTOMER_ORDER → ORDER_LINE | Đơn cần shop/khách/hãng; dòng cần đơn và sản phẩm |
| E — giai đoạn đóng gói | PACKAGE → PACKAGE_LINE và PACKAGE_MATERIAL | Phải có kiện trước khi ghi hàng/vật liệu bên trong |
| F — giai đoạn vận chuyển | SHIPMENT | Phải có kiện trước khi ghi vận đơn |

E và F chưa INSERT lúc nạp seed; được tạo trong flow qua function.

**Ví dụ nhỏ để chỉ trên màn hình:**
`;
s+=code(`INSERT INTO sales_channel(channel_id,channel_name,channel_code)
VALUES (1,'Shopee','DEMO-SHOPEE');

INSERT INTO sales_account(sales_account_id,channel_id,external_shop_id,shop_display_name)
VALUES (1,1,'SHOP-DEMO-A','Shop sách và ly');`);
s+=`
Đây là trích đoạn để giải thích, không chạy thêm sau khi đã nạp cả file01 vì sẽ
trùng PK. Trong file01 thực tế có cả hai kênh và hai shop.

**Lời thoại, 35 giây:**

> “Em thêm kênh bán trước vì đây là dữ liệu độc lập. Sau đó em mới thêm shop,
> vì shop phải tham chiếu đến một kênh có thật. Tương tự, em thêm kho và sản phẩm
> trước khi ghi tồn, thêm đơn trước khi ghi dòng sản phẩm. Thứ tự này đi từ bảng
> cha đến bảng con nên không tạo khóa ngoại mồ côi.”

> “INVENTORY dùng cặp warehouse_id và product_id làm khóa chính. Cùng một sản phẩm
> có thể ở nhiều kho, nhưng một cặp kho–sản phẩm chỉ có một dòng tồn.”

**Dữ liệu để nói nhanh:** đơn1 mua5 sách và2 ly; kho1 có10 sách và3 ly.
Đơn2 cố tình mua99 sách để thử thiếu tồn. Đơn3/4 dùng cho hủy/đổi kho ở phần dự phòng.
ID tường minh trong seed được đồng bộ lại SERIAL bằng setval để lần tạo kiện tự
động tiếp theo không đụng ID đã dùng.

## 4. Truy vấn nghiệp vụ

### Q1 — Đơn này đến từ đâu và gồm những món nào?
`+code(m.queries.Q1)+`
**Kết quả:**2 dòng, sách thành tiền50000; ly thành tiền40000.

**Lời thoại:**
> “Câu JOIN này đi qua5 bảng để nối đơn với shop, kênh bán, dòng đơn và sản phẩm.
> Thông tin được lưu đúng nơi: tên sản phẩm nằm ở PRODUCT, tên kênh nằm ở
> SALES_CHANNEL; dòng đơn lưu khóa tham chiếu, số lượng và giá tại lúc đặt.”

**Nhấn mạnh:** điều kiện ON nối đúng FK với PK, không JOIN các bảng không có điều kiện
vì có thể làm nhân số dòng.

### Q2 — Tính tiền hàng từng đơn bằng GROUP BY và SUM
`+code(m.queries.Q2)+`
| Đơn | Số dòng | Tiền hàng |
| --- | ---: | ---: |
| 1 | 2 | 90000 |
| 2 | 1 | 990000 |
| 3 | 1 | 20000 |
| 4 | 2 | 40000 |

**Lời thoại:**
> “COUNT đếm số dòng sản phẩm. SUM cộng số lượng nhân đơn giá. GROUP BY gom các
> dòng thuộc cùng đơn thành một kết quả. Đơn1 có5 sách giá10000 và2 ly giá20000,
> nên tiền hàng là90000. Đây là giá trị hàng đặt, chưa phải doanh thu đã thu.”

### Q3 — Mỗi kênh có bao nhiêu đơn?
`+code(m.queries.Q3)+`
**Kết quả:** Shopee3 đơn; Website1 đơn.

**Lời thoại:**
> “LEFT JOIN giúp vẫn giữ kênh chưa có đơn. Em đếm mã đơn thay vì COUNT(*) để
> không tính nhầm dòng NULL của kênh trống. DISTINCT cũng tránh đếm một đơn nhiều
> lần nếu truy vấn sau này nối thêm các quan hệ có nhiều dòng.”

## 5. Cố tình đưa dữ liệu sai: cách chạy để hiện lỗi đỏ

Mỗi ca trong07_constraints_live.sql có3 khối, phải chọn/chạy riêng:

1. Chạy BEGIN và SET LOCAL.
2. Chạy riêng câu dữ liệu sai để hiện lỗi đỏ; chỉ vào tên constraint/SQLSTATE.
3. Chạy riêng ROLLBACK rồi mới sang ca tiếp theo.

Không chạy cả file này một lần. Khi một câu bị lỗi trong transaction, phần còn
lại của cùng lệnh gửi có thể không chạy. ROLLBACK riêng giúp đưa phiên về trạng
thái sẵn sàng, không phải xóa hay sửa dữ liệu mẫu.

`;
for(const x of m.bad){
 s+='### '+x.id+' — '+x.name+'\n\n'+code('BEGIN;\nSET LOCAL search_path TO dbi202_live;')+'\nChọn riêng câu này để hiện lỗi:\n\n'+code(x.sql);
 const explanations={
 E1:['Cặp kho1–sản phẩm1 đã tồn tại.','“Em thử chèn thêm cùng cặp kho và sản phẩm. Khóa chính ghép từ chối dòng trùng, vì tồn kho của một sản phẩm tại một kho chỉ có một bản ghi.”'],
 E2:['Sản phẩm999 không tồn tại; các giá trị còn lại hợp lệ.','“Em cho một dòng đơn tham chiếu sản phẩm999 chưa tồn tại. Foreign key chặn dữ liệu mồ côi, nên mọi dòng đơn phải trỏ đến sản phẩm có thật.”'],
 E3:['Kho có10 nhưng cố giữ11.','“CHECK bảo vệ điều kiện lượng giữ không vượt tồn thực tế. Ngay cả khi viết UPDATE trực tiếp, giá trị11 vẫn bị database từ chối.”'],
 E4:['Shop1 đã có DEMO-SUCCESS.','“Mã đơn ngoài chỉ duy nhất trong một shop. Cùng shop và cùng mã sẽ bị chặn; một shop khác có thể dùng cùng mã ngoài.”'],
 E5:['Tên sản phẩm là cột NOT NULL.','“Sản phẩm bắt buộc có tên nên em không thể gán NULL. NOT NULL khác với kiểm tra chuỗi rỗng; phần chuỗi rỗng đã có CHECK riêng.”'],
 E6:['Đơn2 cần99 sách trong khi kho không đủ.','“Đây là lỗi do function nghiệp vụ chủ động báo, không phải lỗi Foreign Key. Việc giữ hàng thất bại và không để lại phần hàng bị giữ dở.”']
 };
 s+=`\n**Mong đợi:** SQLSTATE \`${x.code}\`${x.constraint?', constraint `'+x.constraint+'`':''}. ${explanations[x.id][0]}\n\n**Nói khi lỗi hiện:**\n> ${explanations[x.id][1]}\n\nSau đó chọn riêng và chạy:\n\n`+code('ROLLBACK;')+'\n';
}
s+=`
Chỉ cần E1/E2/E3 cho bản demo ngắn; E4/E5/E6 là phần bổ sung nếu thầy/cô muốn xem.
Không nói “báo lỗi chứng minh database đạt3NF”. Constraints chứng minh từng quy
tắc toàn vẹn; chuẩn hóa phải được giải thích bằng khóa và phụ thuộc hàm trong report.

## 6. Giữ hàng — file02_reserve.sql

Chạy cả file02. Hai lời gọi chính là:
`+code('SELECT reserve_order(1,1); -- TRUE\nSELECT reserve_order(1,1); -- FALSE, khong giu them')+`
**Kết quả:** sách physical10/reserved5; ly physical3/reserved2; đơn ASSIGNED.

**Lời thoại:**
> “Giữ hàng chỉ dành hàng cho đơn chứ chưa mang hàng ra khỏi kho. Vì vậy physical
> không đổi; reserved tăng. Function kiểm tra cả đơn trong một transaction.
> Nếu thiếu một món, toàn bộ lời gọi được hoàn tác. Lời gọi thứ hai trả FALSE,
> cho thấy hệ thống không giữ trùng cho cùng đơn.”

Nhấn mạnh ASSIGNED trong bản function review được dùng với nghĩa đã chọn kho và
giữ đủ. Đây là quyết định MVP cần khớp report của nhóm.

## 7. Đóng gói và duyệt — file03_pack_and_approve.sql

Chạy cả file03. Không chạy lại vì sẽ tạo kiện mới.

| Kiện | Hàng | Cân cả kiện | Vật liệu |
| --- | --- | ---: | --- |
| Kiện đầu | 3 sách +2 ly | 900g | 2 mét xốp |
| Kiện sau | 2 sách | 300g | 0,5 mét xốp |

**Lời thoại:**
> “PACKAGE là kiện vật lý. PACKAGE_LINE cho biết mỗi dòng đơn nằm bao nhiêu trong
> từng kiện; vì vậy một dòng mua5 sách có thể chia3 và2 qua hai kiện.
> PACKAGE_MATERIAL ghi lượng vật liệu đã dùng. Sau khi chia đủ hàng và nhân viên
> duyệt hết các kiện, đơn chuyển PACKED.”

> “Khối lượng kiện đầu900g gồm hàng800g và phần bao bì. Giới hạn hộp là1500g.
> Demo đã kiểm tra khối lượng và số lượng; chưa triển khai thuật toán xếp3D.”

## 8. Trigger minh họa riêng — file08_trigger_minh_hoa.sql

**Nói đúng trước khi chạy:**
> “Phần nghiệp vụ hiện tại dùng các function được gọi trực tiếp. Em bổ sung một
> trigger minh họa chạy tạm trong transaction để cho thấy cơ chế tự kiểm tra khi
> có INSERT. Trigger này chưa được tích hợp vào code core và sẽ được rollback
> sau phần demo.”

Thao tác đúng4 bước:

| Bước | Chọn/chạy | Điều cần quan sát |
| --- | --- | --- |
| A | BEGIN, SET LOCAL, CREATE FUNCTION và CREATE TRIGGER trong file08 | Tạo trigger trong transaction hiện tại |
| B | Chỉ INSERT dòng3 của đơn2 vào kiện thuộc đơn1 | Lỗi23514 có chữ TRIGGER DEMO |
| C | Chỉ ROLLBACK | Hoàn tác cả trigger/function minh họa và phần thử |
| D | SELECT COUNT user trigger ở cuối file | Trở về0 user trigger |

Câu INSERT cố ý sai:
`+code(m.triggerBad)+`
**Nói khi lỗi hiện:**
> “Lần này em không gọi function đóng gói. Chỉ một INSERT trực tiếp cũng làm
> trigger tự chạy trước khi ghi. Trigger phát hiện dòng thuộc đơn khác nên báo
> lỗi. Khóa ngoại riêng lẻ chỉ biết các mã có tồn tại; trigger bổ sung việc so
> sánh hai đơn đó có cùng nhau không.”

**Phân biệt để trả lời giảng viên:**

| Cơ chế | Khi nào chạy? | Vai trò trong demo |
| --- | --- | --- |
| Constraint | Database tự kiểm tra khi ghi dữ liệu liên quan | PK, FK, UNIQUE, NOT NULL, CHECK |
| Function nghiệp vụ | Khi ứng dụng/người dùng gọi SELECT function | Phối hợp giữ hàng, đóng gói, bàn giao |
| Trigger do người viết | Tự chạy khi xảy ra sự kiện đã khai báo | Ví dụ so đơn của kiện và dòng hàng |

Trigger minh họa chỉ kiểm tra quan hệ cùng đơn tại thao tác này; không phải bản
triển khai đầy đủ thay thế mọi validation, cập nhật bảng cha hoặc xử lý đồng thời.
Query đếm có lọc tgisinternal: không nhầm trigger nội bộ dùng cho FK với user trigger.

## 9. Bàn giao và giao hàng — file04 rồi05

Chạy04_handover.sql, quan sát query sau kiện đầu và cuối file.

| Thời điểm | Sách thực tế / giữ | Ly thực tế / giữ | Đơn |
| --- | --- | --- | --- |
| Trước giao | 10/5 | 3/2 | PACKED |
| Sau kiện đầu | 7/2 | 1/0 | PACKED |
| Gọi lặp kiện đầu | 7/2 | 1/0 | PACKED |
| Sau kiện cuối | 5/0 | 1/0 | SHIPPED |

**Lời thoại:**
> “Hàng rời kho nên em giảm cả physical và reserved của đúng kiện, đồng thời
> ghi lịch sử xuất và shipment. Những cập nhật đó nằm trong một transaction.
> Gọi bàn giao lại cùng nội dung không trừ thêm hàng. Sau kiện cuối, đơn mới
> chuyển SHIPPED.”

Sau đó chạy05_deliver.sql.

> “Một kiện giao thành công chưa đủ để hoàn thành cả đơn. Chỉ khi mọi kiện đã
> DELIVERED, hệ thống mới chuyển đơn sang DELIVERED. Đây là dữ liệu mô phỏng cập
> nhật từ đơn vị vận chuyển, không phải kết nối API thật.”

## 10. Các báo cáo để kết thúc demo

### Q5 — Chi phí đóng gói
`+code(m.queries.Q5)+`
**Kết quả:** kiện đầu4900; kiện sau3100.

> “Chi phí gồm mẫu hộp cộng tổng lượng vật liệu nhân đơn giá. LEFT JOIN giữ lại
> kiện chưa dùng vật liệu; COALESCE biến tổng NULL thành0. Em GROUP BY theo kiện
> để tính riêng từng kiện, tránh cộng nhầm giữa các đơn.”

### Q6 — Đối chiếu tồn với sổ lịch sử
`+code(m.queries.Q6)+`
**Kết quả:**4 dòng balanced=TRUE; số tồn kho1 là5 sách,1 ly; kho2 là6 sách,5 ly.
Không chạy file09 nhập thêm hàng của bộ demo khác trong kịch bản này.

> “Ledger là sổ các lần hàng thực tế tăng hoặc giảm. Vì dữ liệu đầu kỳ cũng được
> ghi nhập kho, tổng biến động phải bằng tồn hiện tại. Bốn dòng đều TRUE cho thấy
> các số liệu của lượt demo đang khớp.”

### Q7 — Giá trị hàng của đơn đã giao
`+code(m.queries.Q7)+`
**Kết quả:**1 đơn, giá trị90000. Chưa bao gồm phí vận chuyển/thuế/giảm giá và chưa
chứng minh đã thu tiền.

> “Em lọc DELIVERED trước khi tính giá trị hàng đã giao. Đơn thiếu tồn99 sách vẫn
> có giá trị hàng đặt nhưng chưa giao, nên không được cộng vào kết quả này.
> Tên chỉ tiêu là giá trị hàng đã giao, không khẳng định doanh thu đã thu tiền.”

## 11. Kết luận30 giây

> “Qua demo, database lưu các thực thể riêng và nối bằng khóa ngoại. Constraints
> chặn dữ liệu sai ở mức khóa và giá trị; function xử lý các bước nghiệp vụ liên
> bảng trong transaction. Kết quả cuối là đơn đã giao, hàng được trừ đúng và
> ledger khớp tồn. Bản review đã được test, còn tích hợp sàn bán, API vận chuyển
> và thuật toán AI không thuộc phần triển khai live hôm nay.”

Các function mới đang ở bản review local, không nên nói đã merge/push vào main.
Trigger vừa demo là phần bổ sung tạm và đã rollback, không nói core vốn có trigger.

## 12. Câu hỏi giảng viên có thể hỏi

| Câu hỏi | Câu trả lời ngắn |
| --- | --- |
| Vì sao PK inventory gồm2 cột? | Mã sản phẩm riêng không phân biệt kho, mã kho riêng không phân biệt sản phẩm; cặp hai mã mới xác định dòng tồn. |
| FK khác CHECK? | FK kiểm tra tham chiếu tới dòng cha; CHECK kiểm tra điều kiện giá trị trên dòng. |
| Vì sao tách bảng nối package_line? | Một kiện có nhiều dòng và một dòng có thể chia nhiều kiện; bảng nối lưu số lượng ở mỗi cặp. |
| Test lỗi có chứng minh3NF không? | Không. Cần khóa và phụ thuộc hàm để đánh giá chuẩn hóa; test lỗi kiểm chứng quy tắc toàn vẹn cụ thể. |
| Vì sao có tên người nhận trong đơn dù có CUSTOMER? | Đây là thông tin giao hàng của đơn, có thể khác hồ sơ/người đặt và cần giữ theo từng đơn. |
| Vì sao sau giao kiện đầu đơn còn PACKED? | MVP chưa có PARTIALLY_SHIPPED; giữ PACKED đến khi toàn bộ kiện bàn giao, rồi SHIPPED. |
| Có xử lý hai người cùng giữ hàng chưa? | Bản function đã test hai phiên: tồn5, mỗi đơn cần4; một phiên giữ được, phiên kia chờ khóa rồi thiếu hàng. |
| UPDATE trực tiếp có bỏ qua function không? | Có thể. Bản review chưa cấu hình mọi quyền ghi hoặc trigger chặn tất cả đường ngoài; chưa tuyên bố toàn DB đã chống bypass. |
| Có AI tối ưu hộp chưa? | Chưa. Demo hiện xác nhận dữ liệu, số lượng và khối lượng; chưa có thuật toán xếp3D/AI để trình bày là đã triển khai. |
| Vì sao SERIAL có thể nhảy số? | Sequence không đảm bảo liên tục và giá trị lấy ra không được hoàn lại theo transaction; dùng ID làm định danh, không dùng để đếm dòng. |

## 13. Khi demo gặp sự cố

| Hiện tượng | Việc làm |
| --- | --- |
| schema đã tồn tại | Không xóa vội. Chuyển đúng database live mới đã chuẩn bị; không chạy lại setup ở database đã diễn tập. |
| relation/function không tồn tại | Kiểm tra current_database/current_schema, chạy SET search_path TO dbi202_live trong đúng Query Tool. |
| transaction is aborted / 25P02 | Chạy riêng ROLLBACK, sau đó chạy bước cần thiết; không seed lại. |
| INSERT trùng mã khi nạp dữ liệu | Đang chạy lại seed hoặc nhầm database đã có dữ liệu. Dừng và kiểm tra. |
| Quên số kiện | File flow dùng MIN/MAX theo order1; không đoán ID. Query SELECT package_id,order_id FROM package ORDER BY package_id. |
| Không hiện hết kết quả nhiều SELECT | Chọn chạy lại riêng SELECT cần trình bày sau khi transaction đã commit. |
| Hết thời gian | Giữ Q1, Q2, E2, E3 và flow giữ–giao; phần còn lại chỉ vào bảng kết quả đã diễn tập. |

## Tài liệu PostgreSQL tham khảo

- [Constraints](https://www.postgresql.org/docs/18/ddl-constraints.html)
- [Transactions](https://www.postgresql.org/docs/18/tutorial-transactions.html)
- [Triggers](https://www.postgresql.org/docs/18/triggers.html)

Toàn bộ việc chuẩn bị chỉ tạo file local và chạy trên cluster tạm riêng. Không
pull, push, fetch, commit, merge hoặc sửa repository project. Cluster diễn tập
đã dừng và xóa sau khi xác nhận kết quả.
`;
fs.writeFileSync(path.join(root,'KICH_BAN_THUYET_TRINH.md'),s);
console.log('Wrote detailed presentation script');
