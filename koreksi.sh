#!/usr/bin/env bash
# koreksi.sh — Pemeriksaan otomatis asesmen Linux Ubuntu
# Jalankan sebagai root: sudo bash koreksi.sh
# Pemeriksaan dilakukan pada /home/skatel-server secara default.

set -u
BASE_DIR="${BASE_DIR:-/home/skatel-server}"
CSV_FILE="${CSV_FILE:-hasil_koreksi.csv}"

if [[ $EUID -ne 0 ]]; then
  echo "Jalankan dengan hak root: sudo bash koreksi.sh"
  exit 1
fi

if [[ ! -d "$BASE_DIR" ]]; then
  echo "Direktori target tidak ditemukan: $BASE_DIR"
  echo "Jika lokasi berbeda, jalankan: sudo BASE_DIR=/lokasi/skatel-server bash koreksi.sh"
  exit 1
fi

read -r -p "Nama siswa: " STUDENT
read -r -p "Kelas: " CLASS
[[ -n "$STUDENT" ]] || STUDENT="Tidak diisi"
[[ -n "$CLASS" ]] || CLASS="Tidak diisi"

score=0
declare -a rows
add_result() {
  local no="$1" title="$2" max="$3" got="$4" note="$5"
  score=$((score + got))
  rows+=("$no|$title|$max|$got|$note")
  printf "%-2s %-34s %2s/%-2s %s\n" "$no" "$title" "$got" "$max" "$note"
}
has_dir() { [[ -d "$BASE_DIR/$1" ]]; }
has_file() { [[ -f "$BASE_DIR/$1" ]]; }

echo
echo "=============================================="
echo "   HASIL KOREKSI OTOMATIS — LINUX UBUNTU"
echo "=============================================="
echo "Siswa : $STUDENT"
echo "Kelas : $CLASS"
echo "Target: $BASE_DIR"
echo "----------------------------------------------"

# Tantangan 1 (5): folder utama
got=0; [[ -d "$BASE_DIR" ]] && got=5
add_result 1 "Direktori utama" 5 "$got" "Keberadaan folder dapat diperiksa; posisi cd tidak dapat dibuktikan."

# Tantangan 2 (7): struktur direktori, 1 poin per direktori + 1 bonus kelengkapan
got=0
for p in website website/landing-page database backup configuration; do
  has_dir "$p" && got=$((got+1))
done
add_result 2 "Struktur direktori (persisten)" 7 "$got" "Maks. 5 otomatis; 2 poin manual untuk company-profile dan temporary yang kemudian dihapus."

# Tantangan 3 (5): penggunaan ls adalah perilaku saat ujian, tidak tersimpan pada hasil akhir
add_result 3 "Menampilkan isi dengan ls" 5 0 "MANUAL: verifikasi observasi/history; tidak dapat dibuktikan dari filesystem."

# Tantangan 4 (7): enam file, satu poin tiap file + satu poin bonus bila semuanya ada
got=0
for p in website/landing-page/index.html website/landing-page/style.css website/company-profile/index.html database/database.conf backup/backup.log configuration/server.conf; do
  has_file "$p" && got=$((got+1))
done
[[ "$got" -eq 6 ]] && got=7
add_result 4 "Pembuatan file" 7 "$got" "6 file wajib diperiksa."

# Tantangan 5 (8): isi konfigurasi; setiap baris tepat 2 poin
got=0
CFG="$BASE_DIR/configuration/server.conf"
if [[ -f "$CFG" ]]; then
  grep -Fxq 'SERVER_NAME=SKATEL-HOSTING' "$CFG" && got=$((got+2))
  grep -Fxq 'SERVER_IP=192.168.10.10' "$CFG" && got=$((got+2))
  grep -Fxq 'SERVER_OS=Ubuntu Server' "$CFG" && got=$((got+2))
  grep -Fxq 'SERVER_STATUS=ACTIVE' "$CFG" && got=$((got+2))
fi
add_result 5 "Isi file server.conf" 8 "$got" "4 baris konfigurasi, masing-masing 2 poin."

# Tantangan 6 (5): cat tidak dapat dibuktikan hanya dari hasil akhir
add_result 6 "Membaca file dengan cat" 5 0 "MANUAL: minta siswa mendemonstrasikan atau tunjukkan bukti."

# Tantangan 7 (7): salinan dan sumber harus ada serta identik
got=0
SRC="$BASE_DIR/configuration/server.conf"
DST="$BASE_DIR/backup/server-backup.conf"
if [[ -f "$SRC" ]]; then got=$((got+2)); fi
if [[ -f "$DST" ]]; then got=$((got+2)); fi
if [[ -f "$SRC" && -f "$DST" ]] && cmp -s "$SRC" "$DST"; then got=$((got+3)); fi
add_result 7 "Salinan file backup" 7 "$got" "Memeriksa sumber, salinan, dan kesamaan isi."

# Tantangan 8 (7): target dipindahkan lalu dihapus pada tantangan 9; tidak dapat dinilai dari keadaan akhir
add_result 8 "Memindahkan dan rename file" 7 0 "MANUAL: bukti history/screenshot diperlukan karena file dihapus pada tahap berikutnya."

# Tantangan 9 (5): folder temporary harus tidak ada; jenis perintah penghapusan perlu bukti manual
got=0
[[ ! -e "$BASE_DIR/temporary" ]] && got=3
add_result 9 "Menghapus direktori temporary" 5 "$got" "Maks. 3 otomatis; 2 poin manual untuk memastikan penggunaan rmdir."

# Tantangan 10 (5): style.css tidak ada, index.html tetap ada
got=0
[[ ! -e "$BASE_DIR/website/landing-page/style.css" ]] && got=$((got+3))
has_file "website/landing-page/index.html" && got=$((got+2))
add_result 10 "Menghapus file style.css" 5 "$got" "File target hilang dan index.html tetap ada."

# Tantangan 11 (8): company-profile hilang, landing-page tetap ada
got=0
[[ ! -e "$BASE_DIR/website/company-profile" ]] && got=$((got+5))
has_dir "website/landing-page" && got=$((got+3))
add_result 11 "Menghapus company-profile" 8 "$got" "Memastikan target terhapus dan direktori lain tetap ada."

# Tantangan 12 (6): kedua grup tersedia
got=0
getent group webadmin >/dev/null && got=$((got+3))
getent group dbadmin >/dev/null && got=$((got+3))
add_result 12 "Membuat grup" 6 "$got" "Memeriksa database grup sistem."

# Tantangan 13 (8): dua user, home directory dan shell login yang tidak nologin/false
got=0
for u in andi budi; do
  if id "$u" >/dev/null 2>&1; then
    got=$((got+2))
    home="$(getent passwd "$u" | cut -d: -f6)"
    shell="$(getent passwd "$u" | cut -d: -f7)"
    [[ -n "$home" && -d "$home" ]] && got=$((got+1))
    [[ "$shell" != */nologin && "$shell" != */false && -n "$shell" ]] && got=$((got+1))
  fi
done
add_result 13 "Membuat akun pengguna" 8 "$got" "Memeriksa akun, home directory, dan shell login."

# Tantangan 14 (7): keanggotaan grup tambahan
got=0
id -nG andi 2>/dev/null | tr ' ' '\n' | grep -Fxq webadmin && got=$((got+4))
id -nG budi 2>/dev/null | tr ' ' '\n' | grep -Fxq dbadmin && got=$((got+3))
add_result 14 "Keanggotaan grup" 7 "$got" "Memeriksa grup sekunder user andi dan budi."

# Tantangan 15 (10): permission empat direktori dan file
got=0
check_mode() {
  local path="$1" expected="$2" points="$3"
  if [[ -e "$BASE_DIR/$path" ]]; then
    actual="$(stat -c '%a' "$BASE_DIR/$path" 2>/dev/null || true)"
    [[ "$actual" == "$expected" ]] && got=$((got+points))
  fi
}
check_mode website 755 2
check_mode database 770 2
check_mode backup 750 2
check_mode configuration 700 2
check_mode configuration/server.conf 600 2
add_result 15 "Permission chmod" 10 "$got" "5 objek diperiksa, masing-masing 2 poin."

AUTO_SCORE="$score"
echo "----------------------------------------------"
echo "Skor otomatis: $AUTO_SCORE / 100"
echo
echo "CATATAN: Tantangan 2, 3, 6, 8, dan 9 memerlukan verifikasi manual sebagian/penuh."
echo "Skor otomatis mengukur keadaan akhir, bukan membuktikan setiap syntax yang diketik."
echo

# Nilai manual maksimum 21 poin: T2=2, T3=5, T6=5, T8=7, T9=2.
read -r -p "Masukkan nilai manual tantangan 2 (0-2): " M2
read -r -p "Masukkan nilai manual tantangan 3 (0-5): " M3
read -r -p "Masukkan nilai manual tantangan 6 (0-5): " M6
read -r -p "Masukkan nilai manual tantangan 8 (0-7): " M8
read -r -p "Masukkan nilai manual tantangan 9 (0-2): " M9
for v in M2 M3 M6 M8 M9; do
  val="${!v}"
  [[ "$val" =~ ^[0-9]+$ ]] || val=0
  case "$v" in
    M2|M9) (( val > 2 )) && val=2 ;;
    M3|M6) (( val > 5 )) && val=5 ;;
    M8) (( val > 7 )) && val=7 ;;
  esac
  printf -v "$v" '%s' "$val"
done
MANUAL=$((M2+M3+M6+M8+M9))
# Skor akhir dibatasi 100; skor manual menggantikan skor otomatis untuk item manual (bukan ditambahkan).
# Kurangi maksimum manual item dari skor otomatis agar total tidak melebihi 100.
# T3/T6/T8 otomatis bernilai 0 sehingga nilai manual ditambahkan.
TOTAL=$((AUTO_SCORE+MANUAL))
(( TOTAL > 100 )) && TOTAL=100

echo
echo "Skor akhir: $TOTAL / 100 (otomatis $AUTO_SCORE + manual $MANUAL)"
echo

# CSV satu baris per siswa; aman untuk impor spreadsheet sederhana.
if [[ ! -f "$CSV_FILE" ]]; then
  echo 'Nama,Kelas,Skor Otomatis,Manual T2,Manual T3,Manual T6,Manual T8,Manual T9,Skor Akhir' > "$CSV_FILE"
fi
csv_name="${STUDENT//\"/\"\"}"
csv_class="${CLASS//\"/\"\"}"
printf '"%s","%s",%s,%s,%s,%s,%s,%s,%s\n' "$csv_name" "$csv_class" "$AUTO_SCORE" "$M2" "$M3" "$M6" "$M8" "$M9" "$TOTAL" >> "$CSV_FILE"
echo "Rekap ditambahkan ke: $CSV_FILE"
echo "Rincian pemeriksaan ada pada tampilan terminal di atas."
