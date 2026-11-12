#!/usr/bin/env bash
# KOREKSI OTOMATIS - UJIAN LINUX UBUNTU SERVER VERSI 2
# Penilaian berdasarkan kondisi akhir sistem; tidak memeriksa riwayat perintah.
set -u

if [[ $EUID -ne 0 ]]; then
  echo "Jalankan dengan sudo: sudo bash koreksi.sh"
  exit 1
fi

SISWA="${SUDO_USER:-}"
if [[ -z "$SISWA" || "$SISWA" == "root" ]]; then
  read -rp "Username Linux siswa (contoh: valerian): " SISWA
fi
USER_HOME="$(getent passwd "$SISWA" | cut -d: -f6)"
if [[ -z "$USER_HOME" || ! -d "$USER_HOME" ]]; then
  echo "Home directory untuk user '$SISWA' tidak ditemukan."
  exit 1
fi

BASE_DIR="${BASE_DIR:-$USER_HOME/pusat-data-sekolah}"
read -rp "Nama siswa: " NAMA
read -rp "Kelas: " KELAS

score=0
pass_count=0
fail_count=0

check_file() { [[ -f "$1" ]]; }
check_dir() { [[ -d "$1" ]]; }
check_absent() { [[ ! -e "$1" ]]; }
check_mode() {
  [[ -e "$1" ]] || return 1
  [[ "$(stat -c '%a' "$1" 2>/dev/null)" == "$2" ]]
}
check_group_member() {
  local members
  members="$(getent group "$1" | awk -F: '{print $4}')"
  [[ ",$members," == *",$2,"* ]]
}
record() {
  local label="$1" points="$2" max="$3" ok="$4"
  if [[ "$ok" == "1" ]]; then
    score=$((score + points)); pass_count=$((pass_count + 1)); status="LULUS"
  else
    fail_count=$((fail_count + 1)); status="BELUM LULUS"
  fi
  printf "%-48s %s (%s/%s)\n" "$label" "$status" "$([[ "$ok" == "1" ]] && echo "$points" || echo 0)" "$max"
}

echo
echo "========== KOREKSI UJIAN LINUX VERSI 2 =========="
echo "Nama: $NAMA | Kelas: $KELAS | Akun: $SISWA"
echo "Folder ujian: $BASE_DIR"
echo "------------------------------------------------"

# 1. Struktur direktori (10)
ok=1
for d in "$BASE_DIR" "$BASE_DIR/website" "$BASE_DIR/website/portal" \
         "$BASE_DIR/database" "$BASE_DIR/backup" "$BASE_DIR/dokumen" "$BASE_DIR/arsip"; do
  check_dir "$d" || ok=0
done
record "1. Struktur direktori utama" 10 10 "$ok"

# 2. File akhir hasil pembuatan (10) + file tujuan mv (2)
ok=1
for f in "$BASE_DIR/website/portal/index.html" \
         "$BASE_DIR/website/portal/info.txt" \
         "$BASE_DIR/database/data-siswa.sql" \
         "$BASE_DIR/dokumen/panduan.txt"; do
  check_file "$f" || ok=0
done
record "2. File utama tersedia" 10 10 "$ok"
ok=0; check_file "$BASE_DIR/arsip/backup-2026.log" && ok=1
record "2b. File backup hasil pemindahan tersedia" 2 2 "$ok"

# 3. Salinan identik (8)
ok=0
if check_file "$BASE_DIR/backup/panduan-cadangan.txt" && \
   cmp -s "$BASE_DIR/dokumen/panduan.txt" "$BASE_DIR/backup/panduan-cadangan.txt"; then ok=1; fi
record "3. Salinan panduan identik dengan sumber" 8 8 "$ok"

# 4. Hasil pemindahan: tujuan ada, sumber tidak ada (8)
ok=1
check_file "$BASE_DIR/arsip/backup-2026.log" || ok=0
check_absent "$BASE_DIR/backup/backup-harian.log" || ok=0
record "4. File backup berpindah ke direktori arsip" 8 8 "$ok"

# 5. File tertentu dihapus (5)
ok=0; check_absent "$BASE_DIR/website/portal/temp.html" && ok=1
record "5. File sementara portal sudah dihapus" 5 5 "$ok"

# 6. Direktori sementara sudah tidak ada (8)
ok=0; check_absent "$BASE_DIR/sementara" && ok=1
record "6. Direktori sementara sudah dihapus" 8 8 "$ok"

# 7. Direktori draft beserta isinya sudah tidak ada (8)
ok=0; check_absent "$BASE_DIR/website/draft" && ok=1
record "7. Direktori draft beserta isi dihapus" 8 8 "$ok"

# 8. Grup tersedia (8)
ok=1
getent group skatel_web >/dev/null || ok=0
getent group skatel_db >/dev/null || ok=0
record "8. Grup skatel_web dan skatel_db tersedia" 8 8 "$ok"

# 9. User dan Home directory tersedia (12)
ok=1
id skatelweb >/dev/null 2>&1 || ok=0
id skateldb >/dev/null 2>&1 || ok=0
[[ -d /home/skatelweb ]] || ok=0
[[ -d /home/skateldb ]] || ok=0
record "9. User dan Home directory tersedia" 12 12 "$ok"

# 10. Keanggotaan grup tambahan (8)
ok=1
check_group_member skatel_web skatelweb || ok=0
check_group_member skatel_db skateldb || ok=0
record "10. Keanggotaan user pada grup yang benar" 8 8 "$ok"

# 11. Permission (13), dihitung proporsional per target
perm_points=0
check_mode "$BASE_DIR/website" 755 && perm_points=$((perm_points+2))
check_mode "$BASE_DIR/website/portal" 755 && perm_points=$((perm_points+1))
check_mode "$BASE_DIR/database" 770 && perm_points=$((perm_points+2))
check_mode "$BASE_DIR/backup" 750 && perm_points=$((perm_points+2))
check_mode "$BASE_DIR/dokumen" 700 && perm_points=$((perm_points+2))
check_mode "$BASE_DIR/arsip" 750 && perm_points=$((perm_points+1))
check_mode "$BASE_DIR/website/portal/index.html" 644 && perm_points=$((perm_points+1))
check_mode "$BASE_DIR/database/data-siswa.sql" 640 && perm_points=$((perm_points+1))
check_mode "$BASE_DIR/dokumen/panduan.txt" 600 && perm_points=$((perm_points+1))
score=$((score + perm_points))
if [[ "$perm_points" -eq 13 ]]; then pass_count=$((pass_count+1)); status="LULUS"
else fail_count=$((fail_count+1)); status="BELUM LULUS"; fi
printf "%-48s %s (%s/13)\n" "11. Hak akses direktori dan file" "$status" "$perm_points"

echo "------------------------------------------------"
if (( score >= 90 )); then predikat="A"
elif (( score >= 80 )); then predikat="B"
elif (( score >= 70 )); then predikat="C"
elif (( score >= 60 )); then predikat="D"
else predikat="E"; fi
echo "NILAI AKHIR: $score / 100"
echo "Predikat: $predikat"
echo "Pemeriksaan lulus: $pass_count | Belum lulus: $fail_count"

csv_escape() { local s="${1//\"/\"\"}"; printf '"%s"' "$s"; }
OUT="$USER_HOME/hasil_koreksi_linux_v2.csv"
{
  echo '"Nama","Kelas","Username Linux","Folder Ujian","Nilai","Predikat"'
  printf '%s,%s,%s,%s,%s,%s\n' \
    "$(csv_escape "$NAMA")" "$(csv_escape "$KELAS")" \
    "$(csv_escape "$SISWA")" "$(csv_escape "$BASE_DIR")" \
    "$(csv_escape "$score")" "$(csv_escape "$predikat")"
} > "$OUT"
chown "$SISWA":"$(id -gn "$SISWA")" "$OUT" 2>/dev/null || true
chmod 644 "$OUT"
echo "Hasil CSV tersimpan di: $OUT"
echo "Serahkan file CSV tersebut kepada guru."
