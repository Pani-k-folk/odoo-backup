# Odoo Database Backup Tool

เครื่องมือสำรองฐานข้อมูล Odoo ผ่าน SSH แบบอัตโนมัติ รองรับทั้ง Password และ SSH Key authentication

## คุณสมบัติ

- สำรองฐานข้อมูล PostgreSQL จาก Docker container
- บีบอัดไฟล์ด้วย gzip อัตโนมัติ
- ดาวน์โหลดไฟล์ backup มายังเครื่อง local
- รองรับหลาย projects ในไฟล์ config เดียว
- รองรับทั้ง Password และ SSH Key authentication
- ใช้งานง่ายผ่าน command line

## การติดตั้ง

### วิธีที่ 1: One-liner (แนะนำ)

```bash
curl -sSL https://raw.githubusercontent.com/user/odoo_backup/main/install.sh | bash
```

### วิธีที่ 2: Manual Installation

```bash
git clone https://github.com/user/odoo_backup.git
cd odoo_backup
./install.sh
```

### วิธีที่ 3: Clone และใช้งานโดยตรง

```bash
git clone https://github.com/user/odoo_backup.git
cd odoo_backup
./backup_db.sh --add
```

## Prerequisites

### จำเป็น
- `git` - สำหรับ clone repository
  - Ubuntu/Debian: `sudo apt-get install git`
  - CentOS/RHEL: `sudo yum install git`
  - macOS: `brew install git`

### Optional
- `sshpass` - **จำเป็นเมื่อใช้ password authentication**
  - ถ้าใช้ SSH key authentication **ไม่ต้องติดตั้ง**
  - ถ้าไม่ติดตั้งและเลือก password auth จะ error ตอนรัน backup
  - ติดตั้ง:
    - Ubuntu/Debian: `sudo apt-get install sshpass`
    - CentOS/RHEL: `sudo yum install sshpass`
    - macOS: `brew install hudochenkov/sshpass/sshpass`

## การใช้งาน

### เพิ่ม Project ใหม่

```bash
odoo-backup --add
```

ระบบจะถามข้อมูลดังนี้:
- Project Name (keyword สำหรับเรียกใช้งาน)
- SSH User
- SSH Host
- SSH Port (default: 22)
- Authentication Method (1: password, 2: key)
- SSH Key Path (ถ้าเลือก key)
- Docker Container Name
- Database Name
- Local Backup Path

### แสดง Projects ทั้งหมด

```bash
odoo-backup -l
# หรือ
odoo-backup --list
```

### รัน Backup

```bash
odoo-backup <project_name>
```

ตัวอย่าง:
```bash
odoo-backup myproject
```

### ตัวอย่างการใช้งาน

```bash
# เพิ่ม project
odoo-backup --add

# แสดง projects ทั้งหมด
odoo-backup -l

# รัน backup
odoo-backup production

# รัน backup อีก project
odoo-backup staging
```

## Configuration

ไฟล์ config จะอยู่ที่เดียวกับ script (`config.conf`)

### รูปแบบ Config

```ini
[project_name]
SSH_USER=odoo
SSH_HOST=192.168.1.100
SSH_PORT=22
SSH_AUTH_METHOD=password
SSH_KEY_PATH=
DOCKER_DB=odoo_db_1
DB_NAME=production
LOCAL_PATH=/home/user/backups
```

### Fields

| Field | คำอธิบาย | ตัวอย่าง |
|-------|----------|---------|
| `SSH_USER` | SSH username | `odoo`, `ubuntu` |
| `SSH_HOST` | SSH host/IP | `192.168.1.100` |
| `SSH_PORT` | SSH port | `22` |
| `SSH_AUTH_METHOD` | วิธี authentication | `password` หรือ `key` |
| `SSH_KEY_PATH` | Path ของ SSH key (ใช้เมื่อ method=key) | `/home/user/.ssh/id_rsa` |
| `DOCKER_DB` | ชื่อ Docker container | `odoo_db_1` |
| `DB_NAME` | ชื่อฐานข้อมูล | `production` |
| `LOCAL_PATH` | Path สำหรับเก็บไฟล์ backup | `/home/user/backups` |

### ตัวอย่าง Config

#### Password Authentication

```ini
[production]
SSH_USER=ubuntu
SSH_HOST=203.154.123.45
SSH_PORT=22
SSH_AUTH_METHOD=password
SSH_KEY_PATH=
DOCKER_DB=odoo_db_1
DB_NAME=production
LOCAL_PATH=/home/user/backups/production
```

**หมายเหตุ:** ต้องติดตั้ง `sshpass` ก่อนใช้งาน

#### SSH Key Authentication

```ini
[staging]
SSH_USER=odoo
SSH_HOST=192.168.1.100
SSH_PORT=22
SSH_AUTH_METHOD=key
SSH_KEY_PATH=/home/user/.ssh/odoo_staging_key
DOCKER_DB=odoo_staging_db
DB_NAME=staging
LOCAL_PATH=/home/user/backups/staging
```

**หมายเหตุ:** ไม่ต้องใช้ `sshpass`

## การถอนการติดตั้ง

### วิธีที่ 1: ใช้ uninstall script

```bash
~/.local/share/odoo-backup/uninstall.sh
```

### วิธีที่ 2: ลบเอง

```bash
# ลบ symlink
rm ~/.local/bin/odoo-backup

# ลบ installation directory
rm -rf ~/.local/share/odoo-backup
```

**หมายเหตุ:** ไฟล์ config และ backup files จะไม่ถูกลบ

## โครงสร้างไฟล์

```
odoo_backup/
├── backup_db.sh          # Main script
├── config.conf           # Configuration file (สร้างเองหลังเพิ่ม project)
├── config.conf.example   # ตัวอย่าง config
├── install.sh            # Installation script
├── uninstall.sh          # Uninstallation script
└── README.md             # Documentation
```

## Troubleshooting

### sshpass not found

**Error:**
```
Error: sshpass is not installed!
Install with: sudo apt-get install sshpass
```

**วิธีแก้:**
1. ติดตั้ง sshpass: `sudo apt-get install sshpass`
2. หรือเปลี่ยนไปใช้ SSH key authentication (ไม่ต้องใช้ sshpass)

### Permission denied

**Error:**
```
Permission denied (publickey)
```

**วิธีแก้:**
1. ตรวจสอบว่า SSH key ถูกต้อง
2. ตรวจสอบ permissions ของ key file: `chmod 600 ~/.ssh/your_key`
3. ตรวจสอบว่า public key ถูกเพิ่มใน `~/.ssh/authorized_keys` ของ server

### Config file not found

**Error:**
```
Config file not found: /path/to/config.conf
```

**วิธีแก้:**
- รัน `odoo-backup --add` เพื่อสร้าง project ใหม่
- หรือสร้าง config.conf เองตามรูปแบบด้านบน

## License

MIT License

## Contributing

Welcome contributions! Please feel free to submit a Pull Request.

## Support

หากพบปัญหาหรือมีคำถาม กรุณาเปิด issue ที่ [GitHub Issues](https://github.com/user/odoo_backup/issues)
