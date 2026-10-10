# คู่มือสร้าง Google Sheet และ Apps Script สำหรับใช้งานเอง

เอกสารนี้อธิบายการเตรียมชีตข้อมูลเหรียญและการตั้งค่า URL สำหรับ `REF_SHEET_URL` ใน TFOSvX รวมถึง Apps Script ต้นแบบสำหรับนำไปปรับใช้

> **ข้อควรระวังด้านความเป็นส่วนตัว:** `update.sh` ดาวน์โหลด Google Sheet ผ่าน XLSX export โดยไม่เข้าสู่ระบบ Google ชีตที่ใช้เป็น `REF_SHEET_URL` จึงต้องเปิดให้ผู้มีลิงก์ดูได้ อย่าเปิดชีตที่มีข้อมูลส่วนตัว เช่น `COST`, `QUANTITY`, `PROFIT` หรือ `NET` ให้สาธารณะ ให้แยกชีต REF สำหรับเผยแพร่ ซึ่งมีเฉพาะข้อมูลตลาดและคอลัมน์ที่จำเป็นต่อรายงาน

## สิ่งที่ต้องเตรียม

- บัญชี Google สำหรับสร้าง Spreadsheet และ Apps Script
- ชื่อแท็บข้อมูล `All-Bitkub-BATCH`
- รายการหัวคอลัมน์ตามสคีมาด้านล่าง
- สำเนา [Apps Script ต้นแบบ](./examples/All-Bitkub-BATCH-starter.gs)
- URL ของชีต REF ที่เปิดสิทธิ์ Viewer ด้วยลิงก์

## ขั้นตอนสร้างชีต

1. สร้าง Google Spreadsheet สำหรับงานของคุณ ตั้งชื่อไฟล์ได้ตามต้องการ เช่น `🐋 All-Bitkub`
2. เปลี่ยนชื่อแท็บแรกเป็น `All-Bitkub-BATCH` ให้ตรงตามตัวพิมพ์และเครื่องหมาย
3. ในชีตส่วนตัว ให้คงสิทธิ์การแชร์แบบ Restricted ตามปกติ แล้วเปิด **Extensions → Apps Script**
4. นำโค้ดจาก `examples/All-Bitkub-BATCH-starter.gs` ไปวางในโปรเจกต์ Apps Script แล้วบันทึก
5. เลือกฟังก์ชัน `setupAllBitkubBatchSheet` จากตัวเลือกฟังก์ชัน แล้วกด **Run** และอนุญาตสิทธิ์เมื่อ Google แสดงคำขอ
   - ฟังก์ชันนี้สร้างหัวตารางเมื่อชีตยังว่างเท่านั้น
   - หากชีตมีข้อมูลอยู่แล้ว ฟังก์ชันจะไม่เขียนทับ แต่จะแจ้งข้อผิดพลาดให้ตรวจสอบแท็บและหัวตาราง
6. เพิ่มแถวข้อมูลเหรียญ โดยกรอกสัญลักษณ์ใน `AKA` ให้ตรงกับสินทรัพย์ที่ต้องการอัปเดต
7. นำโค้ดต้นแบบไปปรับส่วนดึงข้อมูลและคำนวณสัญญาณให้ตรงกับกลยุทธ์ของคุณ จากนั้นทดสอบในสำเนาชีก่อนใช้งานจริง

## สคีมาคอลัมน์

ใช้ชื่อคอลัมน์ตามลำดับต่อไปนี้ เพื่อให้ตรงกับข้อมูลที่ TFOSvX คาดหวัง หัวคอลัมน์ที่ซ้ำ เช่น `ENTRY_ZONE(4H)` และ `ENTRY_TRIGGER(1H)` มีซ้ำสองตำแหน่งโดยตั้งใจ:

```text
FLAG	TIER	IMAGE	TV	IMAGEurl	CDN	PNG	AKA	TREND(W)	RSI(W)	MACD_HIST(W)	MACD_HIST_PREV(W)	MACD_HIST_DELTA(W)	MACD(W)	MACD_SIGNAL(W)	EMA9(W)	EMA21(W)	EMA_GAP(W)	SIGNAL_RSI(W)	SIGNAL_MACD(W)	SIGNAL_EMA9X21(W)	SIGNAL_VOLUME(W)	PRICE_STRUCTURE(W)	RELATIVE_STRENGTH(W)	ACTION(W)	RSI(D)	MACD_HIST(D)	MACD_HIST_PREV(D)	MACD(D)	MACD_SIGNAL(D)	EMA9(D)	EMA21(D)	EMA_GAP(D)	SIGNAL_RSI(D)	SIGNAL_MACD(D)	SIGNAL_EMA9X21(D)	SIGNAL_VOLUME(D)	PRICE_STRUCTURE(D)	RELATIVE_STRENGTH(D)	ACTION(D)	TREND(4H)	RSI(4H)	MACD_HIST(4H)	MACD_HIST_PREV(4H)	MACD_HIST_DELTA(4H)	MACD(4H)	MACD_SIGNAL(4H)	EMA9(4H)	EMA21(4H)	EMA_GAP(4H)	SIGNAL_RSI(4H)	SIGNAL_MACD(4H)	SIGNAL_EMA9X21(4H)	SIGNAL_VOLUME(4H)	PRICE_STRUCTURE(4H)	RELATIVE_STRENGTH(4H)	ENTRY_ZONE(4H)	ACTION(4H)	TREND(1H)	RSI(1H)	MACD_HIST(1H)	MACD_HIST_PREV(1H)	MACD_HIST_DELTA(1H)	MACD(1H)	MACD_SIGNAL(1H)	EMA9(1H)	EMA21(1H)	EMA_GAP(1H)	SIGNAL_RSI(1H)	SIGNAL_MACD(1H)	SIGNAL_EMA9X21(1H)	SIGNAL_VOLUME(1H)	PRICE_STRUCTURE(1H)	RELATIVE_STRENGTH(1H)	ENTRY_TRIGGER(1H)	ACTION(1H)	BIAS(W)	SETUP(D)	ENTRY_ZONE(4H)	ENTRY_TRIGGER(1H)	ACTION	COST	QUANTITY	PRICE	PROFIT	NET	URL	LAST_CANDLE	UPDATED	Source
```

อย่าลบหรือสลับตำแหน่งคอลัมน์โดยไม่ตรวจสอบโค้ดที่อ่านชีต เพราะบางสคริปต์อ้างอิงหัวคอลัมน์ที่ซ้ำตามลำดับการปรากฏ

## สร้างชีต REF สำหรับ `update.sh`

1. สร้าง Spreadsheet แยกอีกไฟล์สำหรับเผยแพร่ โดยสร้างแท็บชื่อ `All-Bitkub-BATCH`
2. คัดลอกเฉพาะแถวหัวตารางและข้อมูลตลาดที่จำเป็นจากชีตส่วนตัว โดยอย่างน้อยควรมี `AKA`, `TIER`, `TREND(W)`, `TREND(D)`, `TREND(4H)`, `TREND(1H)`, `RSI(W)`, `RSI(D)`, `RSI(1H)`, `MACD_HIST(W)`, `MACD_HIST_DELTA(W)`, `EMA9(W)`, `EMA21(W)`, `PRICE_STRUCTURE(W)`, `ENTRY_ZONE(4H)`, `ENTRY_TRIGGER(1H)` และ `ACTION(1H)` เพื่อให้รายงานจัดกลุ่มได้ครบ
3. **ไม่คัดลอกข้อมูลส่วนตัวหรือข้อมูลพอร์ต** โดยเฉพาะ `COST`, `QUANTITY`, `PROFIT` และ `NET` รวมถึงสูตร/ลิงก์ที่เปิดเผยข้อมูลดังกล่าว หากคอลัมน์เหล่านี้ไม่จำเป็นต่อรายงาน ให้ตัดออกจากชีต REF ได้
4. แชร์เฉพาะชีต REF โดยตั้งค่า **General access → Anyone with the link → Viewer**
5. ทดสอบเปิด URL ในหน้าต่างส่วนตัว/ไม่ลงชื่อเข้าใช้ แล้วตรวจว่าเปิดและดาวน์โหลดข้อมูลได้
6. ใช้ URL ของ Spreadsheet นี้เป็น `REF_SHEET_URL` ใน `.env` ของเครื่องที่รัน TFOSvX:

```bash
REF_SHEET_URL=https://docs.google.com/spreadsheets/d/YOUR_PUBLIC_REF_SHEET_ID/edit
```

ห้ามใส่ URL ของชีตส่วนตัวลงในที่สาธารณะหรือ commit ค่าใน `.env` ขึ้น Git

## การตั้งค่า Telegram (ถ้าคุณเพิ่มระบบแจ้งเตือนเอง)

Apps Script ต้นแบบที่แนบมาไม่ส่ง Telegram และไม่มี token หรือ chat ID ฝังอยู่ หากนำโค้ดแจ้งเตือนของคุณมาเพิ่ม:

1. สร้างบอตของตนเองผ่าน Telegram `@BotFather` และเก็บ bot token เป็นความลับ
2. หา chat ID ของห้อง/ผู้ใช้ที่ต้องการรับข้อความ โดยเริ่มแชตกับบอตหรือเพิ่มบอตเข้ากลุ่ม แล้วตรวจข้อมูลอัปเดตของบอต
3. เก็บค่าใน Apps Script **Project Settings → Script Properties** เช่น `TELEGRAM_BOT_TOKEN` และ `TELEGRAM_CHAT_ID` แทนการเขียนลงในไฟล์ `.gs`
4. จำกัดผู้ที่แก้ไขโปรเจกต์ Apps Script และทดสอบส่งข้อความกับแชตส่วนตัวก่อน

อย่าแชร์ token, chat ID ที่เป็นข้อมูลส่วนตัว, `.env` หรือสำเนาชีตที่มีข้อมูลพอร์ต

## ขอบเขตของไฟล์ต้นแบบ

ไฟล์ต้นแบบมีฟังก์ชันสร้างแท็บ/หัวคอลัมน์และตัวช่วยเขียนค่าฟิลด์วิเคราะห์ให้กับเหรียญที่มีอยู่แล้ว โดยตัวช่วยเขียนข้อมูลคาดหวังแท็บส่วนตัวที่มีหัวคอลัมน์ครบทั้ง 90 ช่องตามสคีมาด้านบน อย่าใช้ตัวช่วยนี้กับชีต REF ที่ตัดคอลัมน์ออกแล้ว

ต้นแบบตั้งใจ **ไม่** รวมสูตรคำนวณ MTFS, การดึงประวัติราคา, การตั้ง trigger อัตโนมัติ หรือ Telegram alert เพราะแต่ละผู้ใช้งานอาจมี logic และความถี่อัปเดตต่างกัน จึงต้องเติมส่วนดังกล่าวและทดสอบเองก่อนใช้งานจริง

ตัวช่วยเขียนข้อมูลไม่อนุญาตให้อัปเดต `AKA`, `COST`, `QUANTITY`, `PROFIT` หรือ `NET` และไม่เพิ่มแถวเหรียญใหม่โดยอัตโนมัติ หากพบชื่อหัวคอลัมน์ซ้ำ ให้ระบุตำแหน่งด้วยรูปแบบ `ชื่อหัวคอลัมน์#ลำดับ` เช่น `ENTRY_ZONE(4H)#2`

ตัวอย่างการเรียกจากฟังก์ชันอัปเดตที่คุณเขียนเพิ่มเติม:

```javascript
writeAllBitkubAnalysisUpdates([{
  symbol: "L3",
  values: {
    "RSI(1H)": 54.2,
    "ENTRY_ZONE(4H)#2": "ตัวอย่างข้อมูล"
  }
}]);
```

## วิธีตรวจสอบก่อนใช้งานจริง

- ทดลองกับสำเนาชีตและข้อมูลจำลองก่อน
- ตรวจว่าชื่อแท็บเป็น `All-Bitkub-BATCH` และหัวคอลัมน์สะกดตรงกับสคีมา
- ยืนยันว่าข้อมูลส่วนตัวไม่อยู่ในชีต REF ที่แชร์ด้วยลิงก์
- ตรวจประวัติการทำงานใน Apps Script **Executions** เมื่อมีข้อผิดพลาด
- หลังตั้งค่า `REF_SHEET_URL` ให้รัน `./update.sh` แล้วตรวจผลลัพธ์ก่อนใช้งานต่อ
