# code is mostly copied from 1D version and modified to simulate 2D

#This one has better defragmentation


# Add -Done
# Delete- Done somehow
# Get - Done
# Defragmentation - done

#Need overflow guard for sums to be able to handle larger limits ----> to add

.data



#structures , size changes for each unique descriptor ID to be added and number of lines
File_Sizes: .space 6144
File_IDs: .space 6144

# for defrag structures
Defrag_File_Sizes: .space 6144
Defrag_File_IDs: .space 6144

# Not yet sure if enough to handle lots of zero spaces, probably yes?

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
line_code_usage: .long 0
line_saved : .long 0

# for delete
Delete_number: .long 0 #useless
left_bound: .long 0
right_bound: .long 0


# for intervals

left_border_x: .long 0
left_border_y: .long 0
right_border_x: .long 0
right_border_y: .long 0
total_run_length: .long 0

right_border: .long 0
left_border: .long 0



# for concrete

folder_path: .space 1024
file_path: .space 1300
concrete_counter: .long 0

FD: .long -2
FDS: .long -2


#string formats

format_read_long: .asciz "%d"
format_print_string: .asciz "%s"

format_print_interval: .asciz "((%d, %d), (%d, %d))\n"

format_print_long: .asciz "%d\n"


format_print_multiple_intervals: .asciz "%d: ((%d, %d), (%d, %d))\n"


format_read_directory_path: .asciz "%*[\r\n]%1023[^\r\n]%*[\r\n]"
format_file_path: .asciz "%s/file%d.txt"

format_print_concrete: .asciz "File descriptor: %d, Size in KB: %d \n"
# constants, kinda, can be changed

LIMIT: .long 1024 # storage limit, can be changed up to 0x7fffffff, but no overflow guard, behaviour not fully tested yet
ARRAYS_SIZE: .long 1536 # 2x of structure arrays sizes + number of lines, not used yet in the program

DELETE_CODE: .long 257 # anything that isn't a descriptor ID
LINE_CODE: .long 256 # same as above

NUMBER_OF_LINES: .long 1024 # power of 2 please, anything else code it cause i'm not using div

MAX_PATH: .long 1024

PATH_BUFFER: .space 256

NUMBER_OF_DESCRIPTORS: .space 255 #shoukld be (power of 2 ) - 1 , for concrete

FSTAT_BUFFER: .space 256

.text








# Add procedure start

# void Add(long Descriptor, long Size_in_blocks)
#seems ok
Add_procedure:



    pushl %ebp
    movl %esp, %ebp
    movl $0, total_run_length
    movl $0, left_border_x
    movl $0, right_border_x
    movl $0, left_border_y
    movl $0, right_border_y

    xorl %ecx, %ecx

    Add_procedure_loop:
    
        cmpl %ecx, Current_size
        je Add_return_point

        movl (%esi,%ecx,4), %ebx
   
        cmpl $0, %ebx
        je Add_is_zero
        cmpl LINE_CODE, %ebx
        je Add_is_Line_Code

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

    Add_is_Line_Code:

        movl (%edi, %ecx, 4), %ebx
        cmpl %ebx, 12(%ebp)
        jle Add_less
        jmp Add_procedure_continue

     Add_equal:

        movl 8(%ebp), %eax
        movl %eax,(%esi,%ecx,4)

        jmp Add_calculate_interval

    Add_less: #or equal for Line Code

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
        movl NUMBER_OF_LINES, %ebx
        
        decl %ebx
        andl %ebx, %eax

        movl (%edi, %ecx,4), %ebx

        movl %eax, left_border_x
        addl %ebx, %eax
        movl %eax, right_border_x
        decl right_border_x

        movl total_run_length, %eax

        sarl $10, %eax

        movl %eax, left_border_y
        movl %eax, right_border_y
        
        

    Add_return_point:
# add print later
       pushl right_border_x
       pushl right_border_y
       pushl left_border_x
       pushl left_border_y
       pushl 8(%ebp)
       pushl $format_print_multiple_intervals
       call printf
       addl $24, %esp

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

    movl $0, total_run_length
    movl $0, left_border_x
    movl $0, right_border_x
    movl $0, left_border_y
    movl $0, right_border_y
    
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
        movl NUMBER_OF_LINES, %ebx
        
        decl %ebx
        andl %ebx, %eax

        movl (%edi, %ecx,4), %ebx

        movl %eax, left_border_x
        addl %ebx, %eax
        movl %eax, right_border_x
        decl right_border_x

        movl total_run_length, %eax

        sarl $10, %eax

        movl %eax, left_border_y
        movl %eax, right_border_y

    Single_interval_print:

       pushl right_border_x
       pushl right_border_y
       pushl left_border_x
       pushl left_border_y
       pushl $format_print_interval
       call printf
       addl $20, %esp

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
        cmpl LINE_CODE, %edx
        je Get_print_all_continue
         
        pushl %ecx

        movl total_run_length, %eax
        movl NUMBER_OF_LINES, %ebx
        
        decl %ebx
        andl %ebx, %eax

        movl (%edi, %ecx,4), %ebx

        movl %eax, left_border_x
        addl %ebx, %eax
        movl %eax, right_border_x
        decl right_border_x

        movl total_run_length, %eax

        sarl $10, %eax

        movl %eax, left_border_y
        movl %eax, right_border_y


       pushl right_border_x
       pushl right_border_y
       pushl left_border_x
       pushl left_border_y
       pushl %edx
       pushl $format_print_multiple_intervals
       call printf
       addl $24, %esp

       
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
        # even more messy in 2D
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
          
        movl right_bound, %eax
        cmpl LINE_CODE, %eax
        je Line_Code_to_right

        movl left_bound, %eax
        cmpl $0, %eax
        je Zero_to_left

        movl right_bound, %eax
        cmpl $0, %eax
        je Zero_to_right





# border so i dont lose you
        movl $0, (%esi,%ecx,4)
        jmp Delete_return_point
# border so i dont lose you



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

        jmp Delete_restructure_arrays

        Line_Code_to_right:
       #nothing new for 2D, same idea as above

        movl left_bound, %eax
        cmpl $0, %eax
        je Line_Code_to_right_and_zero_to_left

        movl DELETE_CODE, %ebx
        movl %ebx, 4(%esi,%ecx,4)

        movl 4(%edi,%ecx,4), %ebx
        addl %ebx, (%edi,%ecx,4)
        movl $0, 4(%edi, %ecx,4)
        movl LINE_CODE, %eax
        movl %eax, (%esi,%ecx,4)

        jmp Delete_restructure_arrays

        Line_Code_to_right_and_zero_to_left:
        
         movl DELETE_CODE, %ebx
         movl %ebx, (%esi,%ecx,4)
         movl %ebx, 4(%esi,%ecx,4)

         movl (%edi, %ecx,4), %ebx
         addl %ebx, -4(%edi, %ecx,4)
         movl 4(%edi, %ecx,4), %ebx
         addl %ebx, -4(%edi, %ecx,4)

         movl LINE_CODE, %eax
         movl %eax, -4(%esi,%ecx,4)


         movl $0, (%edi,%ecx,4)
         movl $0, 4(%edi,%ecx,4)

        jmp Delete_restructure_arrays

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
# redone 
Defragmentation_procedure:

    pushl %ebp
    movl %esp, %ebp

    leal Defrag_File_IDs, %ebx
    leal Defrag_File_Sizes, %edx
  
    movl $0, memory_saved
    movl LIMIT, %eax
    movl %eax, line_saved
    movl $0, line_code_usage
    movl $0, write_pointer
    xorl %ecx, %ecx

   Defrag_procedure_loop:
   cmpl  Current_size, %ecx
   je Defrag_copy
   
   movl (%esi,%ecx,4), %eax
   cmpl $0, %eax
   je Defrag_procedure_loop_continue
   cmpl LINE_CODE,%eax
   je Defrag_procedure_loop_continue

   movl (%edi, %ecx, 4), %eax
   cmpl line_saved, %eax
   jle Defrag_less_equal
   
   movl write_pointer, %edi
   
   movl LINE_CODE, %eax
   movl %eax, (%ebx,%edi,4)
   movl (%esi,%ecx,4),%eax
   movl %eax, 4(%ebx,%edi,4)

   leal File_Sizes, %edi

   movl write_pointer, %esi

   movl line_saved, %eax
   movl %eax, (%edx,%esi,4)
   movl (%edi,%ecx,4), %eax
   movl %eax, 4(%edx,%esi,4)

 
   leal File_IDs, %esi

   movl LIMIT, %eax
   movl %eax, line_saved
   
   movl (%edi,%ecx,4),%eax
   subl %eax, line_saved
   
   

   incl write_pointer
   incl write_pointer
   incl line_code_usage
   
   Defrag_procedure_loop_continue:
   incl %ecx
   jmp Defrag_procedure_loop


 Defrag_less_equal:
  
  movl write_pointer, %edi
  
  movl (%esi,%ecx,4),%eax
  movl %eax,(%ebx,%edi,4)
  
  leal File_Sizes, %edi

  movl write_pointer, %esi

  movl (%edi, %ecx,4),%eax
  movl %eax, (%edx,%esi,4)

  leal File_IDs, %esi

  incl write_pointer
  subl %eax, line_saved
  jmp Defrag_procedure_loop_continue

Defrag_copy:


xorl %ecx, %ecx

Defrag_copy_loop:

cmpl write_pointer, %ecx
jge Defrag_restore_line_code

movl (%ebx,%ecx,4), %eax
movl %eax, (%esi,%ecx,4)
movl (%edx,%ecx,4), %eax
movl %eax, (%edi,%ecx,4)


incl %ecx
jmp Defrag_copy_loop

Defrag_restore_line_code:

movl write_pointer, %ecx
movl LINE_CODE, %eax
movl %eax, (%esi,%ecx,4)
movl line_saved, %eax
movl %eax, (%edi,%ecx,4)

incl line_code_usage
incl write_pointer


xorl %ecx, %ecx
movl line_code_usage, %eax
movl NUMBER_OF_LINES, %ebx
subl %eax, %ebx

Defrag_restore_line_code_loop:
cmpl %ebx, %ecx
jge Defrag_zeroing

movl write_pointer, %edx

movl LINE_CODE, %eax
movl %eax, (%esi,%edx,4)

movl LIMIT, %eax

movl %eax, (%edi,%edx,4)

incl write_pointer

incl %ecx
jmp Defrag_restore_line_code_loop



movl write_pointer, %ecx

Defrag_zeroing:
cmpl Current_size, %ecx
jge Defragmentation_return_point

movl $0,(%edi,%ecx,4)
movl $0,(%esi,%ecx,4)



incl %ecx

jmp Defrag_zeroing








    Defragmentation_return_point:
    movl write_pointer, %ecx
    movl %ecx, Current_size

        popl %ebp

        ret

# Defragmentation procedure end




.global main

main:

#Preprocess

leal File_Sizes, %edi
leal  File_IDs, %esi
xorl %ecx, %ecx
movl NUMBER_OF_LINES, %eax
movl %eax, Current_size

Preprocess_loop:

    cmpl %ecx,Current_size
    je Preprocess_continue

    movl LINE_CODE, %eax
    movl LIMIT, %ebx

    movl %eax,(%esi,%ecx,4)
    movl %ebx,(%edi,%ecx,4)

    incl %ecx
    jmp Preprocess_loop




Preprocess_continue:
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

    cmpl $5, %ebx
    je Concrete

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


# CONCRETE START
# works if given correct input, else it s unstable
# FD % 255 + 1 is always the same descriptor if i close files
# TO ADD same desciptor handler -> lookup table -> very easy to implement, but too boring, maybe later i hope
Concrete:



#read folder path

    pushl $folder_path
    pushl $format_read_directory_path

    call scanf

    addl $8, %esp

    #read files

    movl $0, concrete_counter


Concrete_read_loop:



# create file path = folder_path + concrete_counter + .txt

    pushl concrete_counter
    pushl $folder_path
    pushl $format_file_path
    pushl $1300
    pushl $file_path

    call snprintf
    
    addl $20, %esp
    


    #open syscall
    movl $5, %eax
    movl $file_path, %ebx
    xorl %ecx,%ecx
    xorl %edx, %edx
    int $0x80

    cmpl $0, %eax
    jl  Concrete_close_directory

# convert descriptor
    movl %eax, FDS
    andl $255, %eax
    incl %eax
    movl %eax, Descriptor
    
#get size in bytes
# fstat syscall
movl $108, %eax
movl FDS, %ebx

movl $FSTAT_BUFFER, %ecx

int $0x80

# close file here




lea FSTAT_BUFFER, %eax
movl 20(%eax), %eax
sarl $10, %eax

#not sure it works on every system, i just started guessing offsets until it landed

    movl %eax, Size
    movl Size, %ebx
    sarl $3, %ebx
    movl %ebx, Size_in_blocks

    movl Size, %ebx
    andl $7, %ebx

    cmpl $0, %ebx
    je Concrete_loop_print
    incl Size_in_blocks

Concrete_loop_print:
pushl %eax
pushl Descriptor
pushl $format_print_concrete

call printf

addl $12, %esp

# add call


pushl Size_in_blocks
pushl Descriptor

call Add_procedure

addl $8, %esp


   
Concrete_read_loop_continue:

    incl concrete_counter
    jmp Concrete_read_loop


Concrete_close_directory:

pushl FD
call close

addl $4, %esp

    jmp main_continue

# CONCRETE END

et_exit:
     
    pushl $0
    call fflush
    popl %eax

    movl $1, %eax
    xorl %ebx, %ebx
    int $0x80

# Still in testing, hope I fixed most edge cases



