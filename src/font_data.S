# Embedded binary font data
    .section .rodata,"",@

    .globl font_bravura
    .globl font_bravura_end
    .balign 4
font_bravura:
    .incbin "fonts/Bravura.bin"
    .size font_bravura, .-font_bravura
font_bravura_end:
    .byte 0
    .size font_bravura_end, 1

    .globl font_gootville
    .globl font_gootville_end
    .balign 4
font_gootville:
    .incbin "fonts/Gootville.bin"
    .size font_gootville, .-font_gootville
font_gootville_end:
    .byte 0
    .size font_gootville_end, 1

    .globl font_leipzig
    .globl font_leipzig_end
    .balign 4
font_leipzig:
    .incbin "fonts/Leipzig.bin"
    .size font_leipzig, .-font_leipzig
font_leipzig_end:
    .byte 0
    .size font_leipzig_end, 1

    .globl font_leland
    .globl font_leland_end
    .balign 4
font_leland:
    .incbin "fonts/Leland.bin"
    .size font_leland, .-font_leland
font_leland_end:
    .byte 0
    .size font_leland_end, 1

    .globl font_petaluma
    .globl font_petaluma_end
    .balign 4
font_petaluma:
    .incbin "fonts/Petaluma.bin"
    .size font_petaluma, .-font_petaluma
font_petaluma_end:
    .byte 0
    .size font_petaluma_end, 1

    .globl font_text_times
    .globl font_text_times_end
    .balign 4
font_text_times:
    .incbin "fonts/text-Times.bin"
    .size font_text_times, .-font_text_times
font_text_times_end:
    .byte 0
    .size font_text_times_end, 1

    .globl font_text_times_bold
    .globl font_text_times_bold_end
    .balign 4
font_text_times_bold:
    .incbin "fonts/text-Times-bold.bin"
    .size font_text_times_bold, .-font_text_times_bold
font_text_times_bold_end:
    .byte 0
    .size font_text_times_bold_end, 1

    .globl font_text_times_bold_italic
    .globl font_text_times_bold_italic_end
    .balign 4
font_text_times_bold_italic:
    .incbin "fonts/text-Times-bold-italic.bin"
    .size font_text_times_bold_italic, .-font_text_times_bold_italic
font_text_times_bold_italic_end:
    .byte 0
    .size font_text_times_bold_italic_end, 1

    .globl font_text_times_italic
    .globl font_text_times_italic_end
    .balign 4
font_text_times_italic:
    .incbin "fonts/text-Times-italic.bin"
    .size font_text_times_italic, .-font_text_times_italic
font_text_times_italic_end:
    .byte 0
    .size font_text_times_italic_end, 1

