;
; Memory map
;
;  0 - Start of code
;  n - end of code
;  0x10000 General purpose memory (heap)
;  0xf7fff
;  0xf8000 strand 0 stack
;  0xf9000 strand 1 stack
;  0xfa000 strand 2 stack
;  0xfb000 strand 3 stack
;  0xfc000 Frame buffer start (frame buffer is 64x64 pixels, RGBA)
;  0x100000 Frame buffer end, top of memory
;
; All registers are caller save
;


;;
;; Entry point.  Initialize machine
;;

_start				.enterscope
					.regalias geometryPointer u7
					.regalias vertexCount u8
					.regalias triangleCount u9
					.regalias tvertPtr u10
					.regalias color u11
					
					sp = mem_l[stackPtr]
					
					goto drawTriangles



;;
;; Draw triangles
;;
drawTriangles		.enterscope
					triangleCount = mem_l[numTriangles]
					geometryPointer = &pyramid
triLoop0			vertexCount = 3
					tvertPtr = &tvertBuffer 
					color = mem_l[geometryPointer]
					mem_l[outputColor] = color
					geometryPointer = geometryPointer + 4

vertexLoop			f0 = mem_l[geometryPointer]			; x
					f1 = mem_l[geometryPointer + 4]		; y
					f2 = mem_l[geometryPointer + 8]		; z
					geometryPointer = geometryPointer + 12
					
					;; Save registers
					sp = sp - 16
					mem_l[sp] = geometryPointer
					mem_l[sp + 4] = triangleCount
					mem_l[sp + 8] = vertexCount
					mem_l[sp + 12] = tvertPtr

					call @transformVertex

					;; Restore registers
					geometryPointer = mem_l[sp]
					triangleCount = mem_l[sp + 4]
					vertexCount = mem_l[sp + 8]
					tvertPtr = mem_l[sp + 12]
					sp = sp + 16

					;; Save the return values
					mem_l[tvertPtr] = u0		; Save X
					mem_l[tvertPtr + 4] = u1	; Save Y
					tvertPtr = tvertPtr + 8
					
					vertexCount = vertexCount - 1
					if vertexCount goto vertexLoop

					;; Save registers
					sp = sp - 8
					mem_l[sp] = geometryPointer
					mem_l[sp + 4] = triangleCount


					;; We have transformed 3 vertices, now we can render
					;; the triangle.  Set up parameters
					tvertPtr = &tvertBuffer 
					s0 = mem_l[tvertPtr]		; x1
					s1 = mem_l[tvertPtr + 4]	; y1
					s2 = mem_l[tvertPtr + 8]	; x2
					s3 = mem_l[tvertPtr + 12]	; y2
					s4 = mem_l[tvertPtr + 16]	; x3
					s5 = mem_l[tvertPtr + 20]	; y3
					s6 = mem_l[cmdBuffer]

					call @rasterizeTriangle
					
					;; No return values, the pixel data is now in the command
					;; buffer.  Draw to framebuffer.
					
					s0 = mem_l[cmdBuffer]
					s1 = mem_l[outputColor]	
					call @fillPixels

					;; Restore registers
					geometryPointer = mem_l[sp]
					triangleCount = mem_l[sp + 4]
					sp = sp + 8

					triangleCount = triangleCount - 1
					if triangleCount goto triLoop0

					cr31 = s0		; Halt

stackPtr			.word 0xf7ffc		
cmdBuffer			.word 0x10000
outputColor			.word 0
tvertBuffer			.word 0, 0, 0, 0, 0, 0		; Transformed vertices

numTriangles		.word 4
pyramid				.word 0x0000ff00		; green
					.float 0.0, 0.0, -0.5
					.float 0.5, 0.5, 0.5
					.float 0.5, -0.5, 0.5
					
					.word 0x000000ff		; red
					.float 0.0, 0.0, -0.5
					.float 0.5, -0.5, 0.5
					.float -0.5, -0.5, 0.5
					
					.word 0x00ff0000		; blue
					.float 0.0, 0.0, -0.5
					.float -0.5, -0.5, 0.5
					.float -0.5, 0.5, 0.5
					
					.word 0x00ff00ff		; yellow
					.float 0.0, 0.0, -0.5
					.float -0.5, 0.5, 0.5
					.float 0.5, 0.5, 0.5
					.exitscope



					
					
					