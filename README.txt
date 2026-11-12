PAKET UJIAN LINUX UBUNTU SERVER - VERSI 2

ISI:
- Soal_Studi_Kasus_Linux_Versi_2.docx
- koreksi.sh
- Kunci_Guru_dan_Rincian_Skor.docx

CARA MENJALANKAN:
1. Simpan koreksi.sh di Home directory siswa.
2. Folder kerja harus berada di /home/USERNAME/pusat-data-sekolah.
3. Jalankan:
   chmod +x ~/koreksi.sh
   sudo bash ~/koreksi.sh
4. Jika diminta, masukkan username Linux siswa.
5. Isi nama dan kelas.
6. Hasil tersimpan di /home/USERNAME/hasil_koreksi_linux_v2.csv.

CATATAN:
- Seluruh nilai diperiksa otomatis berdasarkan kondisi akhir sistem.
- Tidak ada input nilai manual.
- Script perlu sudo untuk memeriksa akun, grup, dan permission.
- Script mengasumsikan Home directory siswa berada di /home/USERNAME.
- Sebaiknya uji pada VM percobaan sebelum dibagikan.
- Jangan menjalankan script tidak tepercaya dengan sudo.
