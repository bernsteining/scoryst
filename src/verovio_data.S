# Embed the Verovio resource zip as raw binary data.
# Replaces the 11MB C hex array with a 1.8MB binary include.
# verovio_data_zip_end is referenced from verovio_init.cpp.

    .section .rodata,"",@

    .globl verovio_data_zip
    .globl verovio_data_zip_end
    .balign 4
verovio_data_zip:
    .incbin "verovio_data.zip"
    .size verovio_data_zip, .-verovio_data_zip
verovio_data_zip_end:
    .byte 0
    .size verovio_data_zip_end, 1
