global start

section .text
bits 32
start:
	; initialize stack (growing downwards)
	mov esp, stack_top

	call check_multiboot
	call check_cpuid
	call check_long_mode

	call setup_page_tables
	call enable_paging

	; print `OK` to screen
	mov dword [0xb8000], 0x2f4b2f4f

	hlt

; Prints `ERR: ` and the given error code to screen and hangs.
; parameter: error code (in ascii) in al
error:
	; print "ERR: X" where X is the error code
	mov dword [0xb8000], 0x4f524f45
	mov dword [0xb8004], 0x4f3a4f52
	mov dword [0xb8008], 0x4f204f20
	mov byte  [0xb800a], al
	hlt

; check if the kernel was actually loaded by multiboot
check_multiboot:
	cmp eax, 0x36d76289     ; magic value that should be written by multiboot
	jne .no_multiboot
	ret
.no_multiboot:
	mov al, "M"
	jmp error

; check if CPUID is supported (copied from OSDev wiki)
check_cpuid:
	; Check if CPUID is supported by attempting to flip the ID bit (bit 21) in
	; the FLAGS register. If we can flip it, CPUID is available.

	; Copy FLAGS in to EAX via stack
	pushfd
	pop eax

	; Copy to ECX as well for comparing later on
	mov ecx, eax

	; Flip the ID bit
	xor eax, 1 << 21

	; Copy EAX to FLAGS via the stack
	push eax
	popfd

	; Copy FLAGS back to EAX (with the flipped bit if CPUID is supported)
	pushfd
	pop eax

	; Restore FLAGS from the old version stored in ECX (i.e. flipping the ID bit
	; back if it was ever flipped).
	push ecx
	popfd

	; Compare EAX and ECX. If they are equal then that means the bit wasn't
	; flipped, and CPUID isn't supported.
	cmp eax, ecx
	je .no_cpuid
	ret
.no_cpuid:
	mov al, "C"
	jmp error

; check if long mode is supported
check_long_mode:
	; test if extended processor info is available
	mov eax, 0x80000000   ; implicit argument for cpuid
	cpuid                 ; get highest supported argument
	cmp eax, 0x80000001   ; it needs to be at least 0x80000001
	jb .no_long_mode      ; if it's less, the CPU is too old for long mode

	; use extended info to test if long mode is available
	mov eax, 0x80000001   ; argument for extended processor info
	cpuid                 ; returns various feature bits in ecx and edx
	test edx, 1 << 29     ; test if the LM-bit is set in the D-register
	jz .no_long_mode      ; If it's not set, there is no long mode
	ret
.no_long_mode:
	mov al, "L"
	jmp error

setup_page_tables:
	mov eax, page_table_l3
	or eax, 0b11            ; present, writable
	mov [page_table_l4], eax
	
	mov eax, page_table_l2
	or eax, 0b11            ; present, writable
	mov [page_table_l3], eax

	mov ecx, 0              ; counter
.loop:
	mov eax, 0x200000       ; 2MiB
	mul ecx
	or eax, 0b10000011      ; present, writable, huge page
	mov [page_table_l2 + ecx * 8], eax

	inc ecx                 ; increment counter
	cmp ecx, 512            ; checks if the whole table is mapped
	jne .loop               ; if not, continue

	ret

enable_paging:
	; pass page table location to cpu
	mov eax, page_table_l4
	mov cr3, eax

	; enable PAE
	mov eax, cr4
	or eax, 1 << 5
	mov cr4, eax

	; enable long mode
	mov ecx, 0xC0000080
	rdmsr
	or eax, 1 << 8
	wrmsr

	; enable paging
	mov eax, cr0
	or eax, 1 << 31
	mov cr0, eax

	ret

section .bss
align 4096
page_table_l4:
	resb 4096
page_table_l3:
	resb 4096
page_table_l2:
	resb 4096
stack_bottom:
	resb 4096 * 4
stack_top:

section .rodata
gdt64:
	dq 0                    ; zero entry
.code_segment: equ $ - gdt64
	dq (1 << 43) | (1 << 44) | (1 << 47) | (1 << 53) ; code segment
.pointer:
	dw $ - gdt64 - 1        ; length
	dq gdt64                ; address
