# ฟอนต์ Cordia New

## การติดตั้งฟอนต์ Cordia New

1. ดาวน์โหลดไฟล์ฟอนต์ Cordia New:
   - `CordiaNew.ttf` (ฟอนต์ปกติ)
   - `CordiaNew-Bold.ttf` (ฟอนต์หนา)

2. วางไฟล์ฟอนต์ในโฟลเดอร์นี้:
   ```
   assets/fonts/CordiaNew.ttf
   assets/fonts/CordiaNew-Bold.ttf
   ```

3. รันคำสั่ง:
   ```bash
   flutter clean
   flutter pub get
   ```

## หมายเหตุ
- ฟอนต์ Cordia New จะถูกใช้เป็นฟอนต์หลักใน PDF
- หากไม่พบไฟล์ฟอนต์ ระบบจะใช้ฟอนต์สำรอง (Kanit, Noto Sans Thai, Sarabun, Open Sans)
- ไฟล์ฟอนต์ต้องเป็นรูปแบบ .ttf หรือ .otf

## ฟอนต์สำรอง
1. Kanit (คล้าย Cordia New)
2. Noto Sans Thai
3. Sarabun
4. Open Sans
