PAKET KOREKSI OTOMATIS — UJIAN LINUX UBUNTU SERVER

ISI PAKET
1. koreksi.sh
   Script pemeriksaan otomatis. Jalankan pada setiap VM siswa:
   sudo bash koreksi.sh

   Default direktori yang diperiksa: /home/skatel-server
   Jika direktori berada di lokasi lain:
   sudo BASE_DIR=/lokasi/skatel-server bash koreksi.sh

   Script meminta nama dan kelas, melakukan pemeriksaan, lalu meminta skor manual
   untuk tantangan 2, 3, 6, 8, dan 9. Hasil ringkas disimpan ke hasil_koreksi.csv.

2. Rekap_Nilai_dan_Checklist_35_Siswa.xlsx
   - Sheet Rekap Nilai: input skor setiap tantangan untuk 35 siswa; total dan predikat otomatis.
   - Sheet Petunjuk: alur penggunaan.
   - Sheet Checklist Penguji: lembar pemeriksaan tiap siswa.

3. Checklist_Penguji.docx
   Checklist yang dapat dicetak.

CATATAN PENTING
- Script harus dijalankan sebagai root agar dapat membaca database user/grup dan permission.
- Script memeriksa hasil akhir, bukan merekam semua command yang diketik siswa.
- Tantangan 2 (2 poin), 3 (ls), 6 (cat), 8 (mv), dan 9 (2 poin penggunaan rmdir) perlu verifikasi manual.
- Tantangan 9: script memeriksa bahwa temporary sudah tidak ada. Untuk memastikan siswa
  menggunakan rmdir, guru perlu mengamati proses atau memeriksa bukti history.
- Lakukan snapshot VM yang seragam sebelum ujian.
- Untuk 35 VM, jalankan script satu kali di setiap VM, lalu kumpulkan hasil_koreksi.csv
  dari tiap VM. Masukkan nilai per tantangan ke workbook rekap untuk analisis lengkap.
