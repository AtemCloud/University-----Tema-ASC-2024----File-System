.data

#structures , size changes for each unique descriptor ID to be added
File_Sizes: .space 2048
File_IDs: .space 2048

#variables

Instruction_number: .space 4
Operation_choice: .space 4
Size: .space 4 #max size limit is 0x7fffffff
Descriptor: .space 4
Files_to_add: .space 4
Size_in_blocks: .space 4

Current_size: .long 0



# for defrag
read_pointer: .long 0 #useless
write_pointer: .long 0
memory_saved: .long 0


# for delete
Delete_number: .long 0 #useless
left_bound: .long 0
right_bound: .long 0


# for intervals

left_border: .long 0
right_border: .long 0
total_run_length: .long 0

#string formats

format_read_long: .asciz "%d"
format_print_long: .asciz "%d\n"

format_print_interval: .asciz "(%d, %d)\n"

format_print_multiple_intervals: .asciz "%d: (%d, %d)\n"

# constants, kinda, can be changed

LIMIT: .long 1024 # storage limit, can be changed up to 0x7fffffff, but no overflow guard, behaviour not fully tested yet
ARRAYS_SIZE: .long 512 # 2x of structure arrays sizes, not used yet in the program

DELETE_CODE: .long 257 # anything that isn't a descriptor ID

.text








# Add procedure start

# void Add(long Descriptor, long Size_in_blocks)
#seems ok
Add_procedure:

    pushl %ebp
    movl %esp, %ebp
    movl $0, total_run_length
    movl $0, left_border
    movl $0, right_border

    xorl %ecx, %ecx

    Add_procedure_loop:
    
        cmpl %ecx, Current_size
        je Add_return_point

        movl (%esi,%ecx,4), %ebx
   
        cmpl $0, %ebx
        je Add_is_zero
      

    Add_procedure_continue:
        movl (%edi, %ecx, 4), %eax
        addl %eax, total_run_length

        incl %ecx
        jmp Add_procedure_loop



    Add_is_zero:

        movl (%edi, %ecx, 4), %ebx
        cmpl %ebx,12(%ebp)
        je Add_equal
        jl Add_less
        jmp Add_procedure_continue



     Add_equal:

        movl 8(%ebp), %eax
        movl %eax,(%esi,%ecx,4)

        jmp Add_calculate_interval

    Add_less:

        incl Current_size
        movl Current_size, %edx

        Add_less_loop:

            cmpl %ecx, %edx
            jle Add_less_continue

            movl -4(%edi, %edx,4), %ebx
            movl %ebx, (%edi, %edx,4)

            movl -4(%esi, %edx,4), %ebx
            movl %ebx, (%esi, %edx,4)



            decl %edx
            jmp Add_less_loop

        Add_less_continue:

            movl 12(%ebp), %eax
            movl %eax ,(%edi,%ecx,4)
            subl %eax, 4(%edi,%ecx,4)
            movl 8(%ebp),%eax
            movl %eax,(%esi, %ecx, 4)

    Add_calculate_interval:
        movl total_run_length, %eax
        movl %eax, left_border
        movl (%edi,%ecx,4), %ebx
        addl %ebx, %eax
        decl %eax
        movl %eax, right_border

    Add_return_point:
# add print later
       pushl right_border
       pushl left_border
       pushl 8(%ebp)
       pushl $format_print_multiple_intervals
       call printf
       addl $16, %esp

        popl %ebp
        ret

# Add procedure end

# Get procedure start


# void Get(long Descriptor = 0)
# if 0 print all
# seems ok 
Get_procedure:



    pushl %ebp
    movl %esp, %ebp

    movl 8(%ebp), %ebx
    xorl %ecx, %ecx
    movl $0, left_border
    movl $0, right_border
    movl $0, total_run_length

    cmpl $0, %ebx
    je Get_print_all

    Get_no_zero_loop:

        cmpl %ecx, Current_size
        je Single_interval_print

        movl (%esi,%ecx,4), %eax
        cmpl %ebx,%eax
        je Get_Descriptor_found

        movl (%edi,%ecx,4), %eax

        addl %eax, total_run_length


    Get_no_zero_loop_continue:

        incl %ecx
        jmp Get_no_zero_loop


    Get_Descriptor_found:

        movl total_run_length, %eax
        movl %eax, left_border
        movl (%edi,%ecx,4), %ebx
        addl %ebx, %eax
        decl %eax
        movl %eax, right_border

    Single_interval_print:

        pushl right_border
        pushl left_border

        pushl $format_print_interval

        call printf

        addl $12, %esp

        jmp Get_return_point


    Get_print_all:
     
        cmpl %ecx, Current_size
        je Get_return_point
        
        movl (%edi,%ecx,4), %ebx
        movl (%esi, %ecx,4), %edx

        cmpl $0, %edx
        jne Multiple_interval_print


    Get_print_all_continue:

       
        addl %ebx, total_run_length
        incl %ecx
        jmp Get_print_all

    Multiple_interval_print:
        pushl %ecx
        movl total_run_length, %eax
        movl %eax, left_border
        movl (%edi,%ecx,4), %ebx
        addl %ebx, %eax
        decl %eax
        movl %eax, right_border

         pushl right_border
         pushl left_border
         pushl %edx
         pushl $format_print_multiple_intervals

         call printf

         addl $16, %esp
         popl %ecx

         jmp Get_print_all_continue





    Get_return_point:
        popl %ebp

        ret




# Get procedure end



# Delete procedure start
Delete_procedure:
    pushl %ebp
    movl %esp, %ebp
    

    xorl %ecx, %ecx

    Delete_procedure_loop:

        cmpl %ecx, Current_size
        je Delete_return_point

        movl (%esi,%ecx,4), %ebx
        cmpl %ebx, 8(%ebp)
        je Descriptor_found



        incl %ecx
        jmp Delete_procedure_loop



    Descriptor_found:
        #HELL
        #not sure it fully works yet, tests seemed to give correct results

        cmpl $0, %ecx
        jne left_exists
        movl $-1, left_bound

        left_continue:

        cmpl Current_size, %ecx
        jne right_exists
        movl $-1, right_bound
        jmp check_continue

        left_exists:
        movl -4(%esi,%ecx,4), %eax
        movl %eax, left_bound
        jmp left_continue

        right_exists:
        movl 4(%esi,%ecx,4), %eax
        movl %eax, right_bound
       
       check_continue:

        movl left_bound, %eax
        cmpl $0, %eax
        je Zero_to_left

        movl right_bound, %eax
        cmpl $0, %eax
        je Zero_to_right

        movl $0, (%esi,%ecx,4)
        jmp Delete_return_point


        Zero_to_left:

        movl right_bound, %eax
        cmpl $0, %eax
        je Zero_to_left_and_right

         movl DELETE_CODE, %ebx
         movl %ebx, (%esi,%ecx,4)

         movl (%edi, %ecx,4), %ebx
         addl %ebx, -4(%edi, %ecx,4)
         movl $0,(%edi,%ecx,4)
         movl $1, Delete_number
        jmp Delete_restructure_arrays
        
        Zero_to_right:

        movl left_bound, %eax
        cmpl $0, %eax
        je Zero_to_left_and_right

         movl DELETE_CODE, %ebx
         movl %ebx, 4(%esi,%ecx,4)

         movl 4(%edi, %ecx,4), %ebx
         addl %ebx, (%edi, %ecx,4)
         movl $0, 4(%edi,%ecx,4)
         movl $0, (%esi,%ecx,4)   
         movl $1, Delete_number

         jmp Delete_restructure_arrays
        
        Zero_to_left_and_right:

         movl DELETE_CODE, %ebx
         movl %ebx, (%esi,%ecx,4)
         movl %ebx, 4(%esi,%ecx,4)
          
         movl (%edi, %ecx,4), %ebx
         addl %ebx, -4(%edi, %ecx,4)
         movl 4(%edi, %ecx,4), %ebx
         addl %ebx, -4(%edi, %ecx,4)

         movl $0, (%edi,%ecx,4)
         movl $0, 4(%edi,%ecx,4)
          
        movl $2, Delete_number

        Delete_restructure_arrays:
        # two pointer 
        
        movl $0, write_pointer
        xorl %ecx, %ecx

        restructure_loop:
        cmpl Current_size, %ecx
        je Delete_zero_out

        movl (%esi,%ecx,4), %ebx
        cmpl DELETE_CODE, %ebx
        jne Non_delete_code

        restructure_loop_continue:
        incl %ecx
        jmp restructure_loop

        Non_delete_code:

        movl write_pointer, %edx
        movl %ebx, (%esi,%edx,4)
        movl (%edi, %ecx, 4 ), %eax
        movl %eax, (%edi,%edx,4)
        incl write_pointer
        jmp restructure_loop_continue

        Delete_zero_out:
        
        movl write_pointer, %ecx

        zeroing:
        cmpl Current_size ,%ecx 
        jge Change_size

        movl $0, (%esi,%ecx,4)
        movl $0, (%edi,%ecx,4)


        incl %ecx
        jmp zeroing
        
     Change_size:

        movl write_pointer, %ecx
        movl %ecx, Current_size


    Delete_return_point:

       
        popl %ebp
        ret


# Delete procedure end



# Defragmentation procedure start
# worked fine
Defragmentation_procedure:
# two pointers approach
    pushl %ebp
    movl %esp, %ebp

    movl $0, memory_saved

    movl $0, read_pointer
    movl $0, write_pointer
    xorl %ecx, %ecx

    Two_pointer_loop:

        cmpl Current_size, %ecx
        je Defragmentation_loop_end

        movl (%esi,%ecx,4), %ebx
        cmpl $0, %ebx
        jne Defrag_non_zero

        movl (%edi,%ecx,4), %ebx
        addl %ebx, memory_saved

    Two_pointer_loop_continue: 

        incl read_pointer
        incl %ecx
        jmp Two_pointer_loop

    Defrag_non_zero:

        movl write_pointer, %edx
        movl %ebx, (%esi,%edx,4)
        movl (%edi, %ecx, 4 ), %eax
        movl %eax, (%edi,%edx,4)
        incl write_pointer
        jmp Two_pointer_loop_continue



    Defragmentation_loop_end:
    #restore last element


        movl write_pointer, %edx
        movl memory_saved, %eax
        movl $0, (%esi,%edx,4)

        movl %eax, (%edi,%edx,4)

        #zero out the rest

        movl write_pointer, %ecx
        incl %ecx

        zeroing_remainders:
        cmpl Current_size, %ecx
        jge Defragmentation_return_point

        movl $0, (%esi,%ecx,4)
        movl $0, (%edi,%ecx,4)


        incl %ecx
        jmp zeroing_remainders


    Defragmentation_return_point:
        movl write_pointer, %eax
        incl %eax
        movl %eax, Current_size

        popl %ebp

        ret

# Defragmentation procedure end




.global main

main:

#Preprocess

leal File_Sizes, %edi
leal  File_IDs, %esi
xorl %ecx, %ecx
movl %ecx, (%esi,%ecx,4)
movl LIMIT, %eax
movl %eax, (%edi, %ecx,4)
movl $1, Current_size






#Read Instruction_number

pushl $Instruction_number
pushl $format_read_long
call scanf
addl $8, %esp




movl $0, %ecx


#MAIN-START

Main_loop:


    cmpl %ecx, Instruction_number
    je et_exit
    pushl %ecx

    #Read choice
    pushl $Operation_choice
    pushl $format_read_long
    call scanf
    addl $8, %esp


    movl Operation_choice, %ebx

    cmpl $1, %ebx
    je Add_file

    cmpl $2, %ebx
    je Get_file

    cmpl $3, %ebx
    je Delete_file

    cmpl $4, %ebx
    je Defragmentation

main_continue:

    popl %ecx
    incl %ecx

    jmp Main_loop

# MAIN-END


# ADD - START

#Read Files to add

Add_file:

    pushl $Files_to_add
    pushl $format_read_long
    call scanf

    addl $8, %esp

    movl $0, %ecx

Add_loop:


    cmp %ecx, Files_to_add
    je main_continue
    pushl %ecx

    #read
    pushl $Descriptor
    pushl $format_read_long
    call scanf
    pushl $Size
    pushl $format_read_long
    call scanf
    addl $16, %esp


    # Conversion in blocks and ceil simulation
    movl Size, %ebx
    sarl $3, %ebx
    movl %ebx, Size_in_blocks

    movl Size, %ebx
    andl $7, %ebx

    cmpl $0, %ebx
    je Add_loop_continue
    incl Size_in_blocks


Add_loop_continue:

    pushl Size_in_blocks
    pushl Descriptor

    call Add_procedure


    addl $8, %esp

    popl %ecx
    incl %ecx
    jmp Add_loop

    # ADD - END

    # GET - START
    Get_file:

    pushl $Descriptor
    pushl $format_read_long

    call scanf

    addl $8 ,%esp

    pushl Descriptor
    call Get_procedure
    addl $4, %esp

    jmp main_continue
# GET - END


# DELETE - START
Delete_file:

    pushl $Descriptor
    pushl $format_read_long
    call scanf
    addl $8, %esp

    pushl Descriptor
    call Delete_procedure
    addl $4, %esp

    pushl $0
    call Get_procedure
    addl $4, %esp

    jmp main_continue

# DELETE - END

# DEFRAGMENATION START
Defragmentation:


    call Defragmentation_procedure

    pushl $0
    call Get_procedure
    addl $4, %esp


    jmp main_continue


# DEFRAGMENTATION END


et_exit:
     
    pushl $0
    call fflush
    popl %eax

    movl $1, %eax
    xorl %ebx, %ebx
    int $0x80

# Still in testing, hope I fixed most edge cases



