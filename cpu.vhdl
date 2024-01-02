library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu is 

    port(
        reset:in std_logic:='0'; -- To reset program counter
        clk:in std_logic; -- clk input
        pc:out std_logic_vector(3 downto 0):="0000"; -- Program Counter
        result:out std_logic_vector(15 downto 0); -- result for the last instruction result
        flag_register:inout std_logic_vector(2 downto 0):="000"; -- MSB: for zero flag, bit 1: for Overflow, LSB: for carry  
        final_result:out std_logic_vector(4 downto 0) -- final result for the required program
    );

end cpu;

architecture cpu_equations of cpu is -- architecture of the cpu

-- Arrays initialization
type arr1 is array (0 to 15) of std_logic_vector(15 downto 0);
type arr2 is array (0 to 15) of std_logic_vector(15 downto 0);
type rgs is array (0 to 7) of std_logic_vector(15 downto 0);

begin -- architecture begin

    process(reset, clk,flag_register) -- process

	variable pc_signal : std_logic_vector(3 downto 0):="0000"; -- variable for program counter
	variable inst : std_logic_vector(15 downto 0); -- variable for instruction after fetching
	variable op_code: std_logic_vector(3 downto 0):="0000"; -- op code 
	variable result_check:std_logic_vector(16 downto 0):="00000000000000000"; -- 17 bit variable for checking for carry 
    variable overflow:std_logic_vector(31 downto 0):="00000000000000000000000000000000"; -- 32 bit variable for overflow checking 
	variable res: std_logic_vector(15 downto 0):="0000000000000000"; -- variable for the current result
	variable a:std_logic_vector(15 downto 0):="0000000000000000"; -- variable for filling the immediate load
	variable b:std_logic_vector(15 downto 0):="0000000000000000"; -- variable 2 for filling the immediate load
	variable func:std_logic_vector(2 downto 0):="000"; -- variable for the function of the instruction for alu operations
	variable func2:std_logic_vector(2 downto 0):="000"; -- variable for the function of the instruction for the ram operantion
	variable address1:std_logic_vector(2 downto 0):="000"; -- variable for first register address
	variable address2:std_logic_vector(2 downto 0):="000"; -- variable for second register address
	variable address3:std_logic_vector(2 downto 0):="000"; -- variable for third register address
	variable address4:std_logic_vector(3 downto 0):="0000";-- variable for ram address

    -- ROM array
    constant rom : arr1 := (  
        "0111110000000000", -- load zero to final result register
        "0111000000011101", -- load number
        "0111001000000010", -- load 2 for division
        "0100000010000001", -- and with one
        "1110000000000110", -- check the result of and if zf = 1 jump for address 6  
        "0010110110000001", -- increment the final result register
        "0001000001000011", -- divide 2
        "1110000000000000", -- if number is equal to zero start again
        "1111000000000011", -- if number not equal to zero then loop again
        "0000000000000000",  
        "0000000000000000",
        "0000000000000000",
        "0000000000000000",     
        "0000000000000000", 
        "0000000000000000",   
        "0000000000000000"
    );

    -- Registers array
	variable reg : rgs:= (
        "0000000000000000",  
        "0000000000000000",
        "0000000000000000",  
        "0000000000000000",
        "0000000000000000",
        "0000000000000000",
        "0000000000000000", 
        "0000000000000000"
	);

    -- RAM array
	variable ram : arr2 := ( 
        "0000000000000000",  
        "0000000000000000",  
        "0000000000000000",  
        "0000000000000000", 
        "0000000000000000",  
        "0000000000000000",  
        "0000000000000000", 
        "0000000000000000",
        "0000000000000000",  
        "0000000000000000", 
        "0000000000000000",  
        "0000000000000000",  
        "0000000000000000",  
        "0000000000000000",
        "0000000000000000",
        "0000000000000000"
        );

        begin -- process begin

            -- if reset is zero then continue the clock
            if reset = '0' then 

                -- if rising edge then start the instruction fetching, decoding and execution
                if rising_edge(clk) then 

                    -- fetching the instruction from the rom
                    inst:=rom(to_integer(unsigned(pc_signal))); 
                    -- Register 1 address mapping
                    address1:=inst(11 downto 9); 
                    -- Register 2 address mapping
                    address2:=inst(8 downto 6); 
                    -- Register 3 address mapping
                    address3:=inst(5 downto 3);
                    -- RAM address mapping
                    address4:=inst(3 downto 0);

                    -- op_code mapping
                    op_code:=inst(15 downto 12); 
                    -- function mapping for the alu operations
                    func:=inst(2 downto 0); 

                    -- immediate 1 mapping
                    b:="0000000000"&inst(5 downto 0);
                    -- immediate 2 mapping
                    a:="0000000"&inst(8 downto 0); 

                    -- operations on the data stored in 2 registers then the result will be stored in another register
                    if op_code = "0001" then 

                        -- 1st instruction based on the instruction set
                        if func = "000" then 

                            -- Adding operation 
                            reg(to_integer(unsigned(address3))):=std_logic_vector(unsigned(reg(to_integer(unsigned(address1))))+unsigned(reg(to_integer(unsigned(address2)))));                            
                            result_check:=std_logic_vector(unsigned('0'&reg(to_integer(unsigned(address1))))+unsigned('0'&reg(to_integer(unsigned(address2)))));
                            -- carry
                            flag_register(0)<=result_check(16);
                            -- overflow
                            flag_register(1)<='0';

                        -- 2nd instruction based on the instruction set
                        elsif func = "001" then 

                            -- subtraction operation
                            reg(to_integer(unsigned(address3))):=std_logic_vector(unsigned(reg(to_integer(unsigned(address1))))-unsigned(reg(to_integer(unsigned(address2)))));
                            result_check:=std_logic_vector(unsigned('0'&reg(to_integer(unsigned(address1))))-unsigned('0'&reg(to_integer(unsigned(address2)))));
                            -- carry
                            flag_register(0)<=result_check(16);
                            --overflow
                            flag_register(1)<='0';

                        -- 3rd instruction based on the instruction set
                        elsif func = "010" then 

                            -- Multiplication operation
                            overflow:=std_logic_vector(unsigned(reg(to_integer(unsigned(address1)))(15 downto 0))*unsigned(reg(to_integer(unsigned(address2)))(15 downto 0)));                    
                            reg(to_integer(unsigned(address3)))(15 downto 0):=overflow(15 downto 0);
                            -- carry
                            flag_register(0)<='0';
                            --overflow Check
                            if overflow(31 downto 16)>"0000000000000000" then 
                                flag_register(1)<='1';
                            end if;

                        -- 4th instruction based on the instruction set
                        elsif func = "011" then

                            -- Division operation
                            reg(to_integer(unsigned(address3)))(15 downto 0):=std_logic_vector(unsigned(reg(to_integer(unsigned(address1)))(15 downto 0))/unsigned(reg(to_integer(unsigned(address2)))(15 downto 0)));
                            -- reset flag register
                            flag_register<="000";

                        -- 5th instruction based on the instruction set
                        elsif func = "100" then 

                            -- AND operation
                            reg(to_integer(unsigned(address3))):=reg(to_integer(unsigned(address1))) and reg(to_integer(unsigned(address2)));
                            -- reset flag register 
                            flag_register<="000";

                        -- 6th instruction based on the instruction set
                        elsif func = "101" then 

                            -- OR operation
                            reg(to_integer(unsigned(address3))):=reg(to_integer(unsigned(address1))) or reg(to_integer(unsigned(address2)));
                            -- reset flag register 
                            flag_register<="000";

                        -- 7th instruction based on the instruction set
                        elsif func = "110" then 

                            -- XOR operation
                            reg(to_integer(unsigned(address3))):=reg(to_integer(unsigned(address1))) xor reg(to_integer(unsigned(address2)));
                            -- reset flag register 
                            flag_register<="000";

                        -- 8th instruction based on the instruction set
                        elsif func = "111" then 

                            -- NOT operation
                            reg(to_integer(unsigned(address3))):=not reg(to_integer(unsigned(address1)));
                            -- reset flag register 
                            flag_register<="000";

                        end if; 

                        -- Assign the value of the result from the register to res variable
                        res:=reg(to_integer(unsigned(address3))); 
                         -- to show the current result variable on an output  
                        result<=res;

                    -- Addition operation on register and immediate                    
                    elsif op_code = "0010" then -- 9th instruction based on MIPS Architecture

                        reg(to_integer(unsigned(address2))):=std_logic_vector(unsigned(reg(to_integer(unsigned(address1))))+unsigned(b));
                        result_check:=std_logic_vector(unsigned('0'&reg(to_integer(unsigned(address1))))+unsigned('0'&b));
                        -- carry
                        flag_register(0)<=result_check(16); 
                        -- overflow
                        flag_register(1)<='0';
                        -- Assign the value of the result from the register to res variable
                        res:=reg(to_integer(unsigned(address2))); 
                        -- to show the current result variable on an output 
                        result<=res; 
                    
                    -- Subtraction operation on register and immediate
                    elsif op_code = "0011" then
                        
                        reg(to_integer(unsigned(address2))):=std_logic_vector(unsigned(reg(to_integer(unsigned(address1))))-unsigned(b));
                        result_check:=std_logic_vector(unsigned('0'&reg(to_integer(unsigned(address1))))-unsigned('0'&b));
                        -- carry
                        flag_register(0)<=result_check(16);
                        -- overflow
                        flag_register(1)<='0';
                        -- Assign the value of the result from the register to res variable
                        res:=reg(to_integer(unsigned(address2)));  
                        -- to show the current result variable on an output
                        result<=res; 

                    -- AND operation on register and immediate
                    elsif op_code = "0100" then 

                        reg(to_integer(unsigned(address2))):=reg(to_integer(unsigned(address1))) and b;
                        -- reset flag register
                        flag_register<="000";
                        -- Assign the value of the result from the register to res variable 
                        res:=reg(to_integer(unsigned(address2)));  
                        -- to show the current result variable on an output
                        result<=res; 

                    -- OR operation on register and immediate
                    elsif op_code = "0101" then 

                        reg(to_integer(unsigned(address2))):=reg(to_integer(unsigned(address1))) or b;
                        -- reset flag register 
                        flag_register<="000"; 
                        -- Assign the value of the result from the register to res variable
                        res:=reg(to_integer(unsigned(address2)));  
                        -- to show the current result variable on an output
                        result<=res; 

                    -- XOR operation on register and immediate
                    elsif op_code = "0110" then

                        reg(to_integer(unsigned(address2))):=reg(to_integer(unsigned(address1))) xor b;
                        -- reset flag register
                        flag_register<="000"; 
                        -- Assign the value of the result from the register to res variable
                        res:=reg(to_integer(unsigned(address2)));  
                        -- to show the current result variable on an output
                        result<=res;

                    -- load immediate to register    
                    elsif op_code = "0111" then

                        reg(to_integer(unsigned(address1))):=a;
                        -- reset flag register
                        flag_register<="000";
                        -- Assign the value of the result from the register to res variable 
                        res:=reg(to_integer(unsigned(address1)));
                        -- to show the current result variable on an output
                        result<=res; 

                    -- load data from RAM to Register
                    elsif op_code = "1000" then
 
                        reg(to_integer(unsigned(address1))):=ram(to_integer(unsigned(address4)));
                        -- reset flag register
                        flag_register<="000"; 
                        -- Assign the value of the result from the register to res variable 
                        res:=reg(to_integer(unsigned(address1)));
                        -- to show the current result variable on an output
                        result<=res; 

                    -- load data from Register to RAM 
                    elsif op_code = "1001" then

                        ram(to_integer(unsigned(address4))):=reg(to_integer(unsigned(address1)));
                        -- reset flag register
                        flag_register<="000"; 
                        -- Assign the value of the result from the register to res variable 
                        res:=ram(to_integer(unsigned(address4)));
                        -- to show the current result variable on an output
                        result<=res; 

                    -- Branching operations    
                    elsif op_code = "1010" then

                        -- if the data in the first Register is equal the data in the Second register then branch to the required address
                        if unsigned(reg(to_integer(unsigned(address1))))=unsigned(reg(to_integer(unsigned(address2)))) then
                            -- branching the pc signal to the required address - 1 
                            pc_signal:=std_logic_vector(unsigned(address4)-1);
                            -- Assign the value of the address to res variable 
                            res:="000000000000"&address4;
                            -- to show the current result variable on an output
                            result<=res; 

                        end if;

                    elsif op_code = "1011" then

                        -- if the data in the first Register is greater the data in the Second register then branch to the required address
                        if unsigned(reg(to_integer(unsigned(address1))))>unsigned(reg(to_integer(unsigned(address2)))) then
                            -- branching the pc signal to the required address - 1
                            pc_signal:=std_logic_vector(unsigned(address4)-1);
                            -- Assign the value of the address to res variable
                            res:="000000000000"&address4;
                            -- to show the current address on an output
                            result<=res; 
                        end if;

                    elsif op_code = "1100" then

                        -- if the data in the first Register is less the data in the Second register then branch to the required address
                        if unsigned(reg(to_integer(unsigned(address1))))<unsigned(reg(to_integer(unsigned(address2)))) then
                            -- branching the pc signal to the required address - 1
                            pc_signal:=std_logic_vector(unsigned(address4)-1);
                            -- Assign the value of the address to res variable
                            res:="000000000000"&address4;
                            -- to show the current address on an output
                            result<=res;
                            end if;

                    elsif op_code = "1101" then

                        -- if the carry is equal to one then flag to the required address
                        if flag_register(0) = '1' then
                            -- branching the pc signal to the required address - 1 
                            pc_signal:=std_logic_vector(unsigned(address4)-1);
                            -- to show the current address on an output
                            result<="000000000000"&address4; 
                        end if;

                    elsif op_code = "1110" then 

                        -- if the overflow is equal to one then flag to the required address
                        if flag_register(2) = '1' then
                            -- branching the pc signal to the required address - 1  
                            pc_signal:=std_logic_vector(unsigned(address4)-1);
                            -- to show the current address on an output
                            result<="000000000000"&address4; 
                        end if;

                    -- Branch unconditionaly
                    elsif op_code = "1111" then
                        -- branching the pc signal to the required address - 1
                        pc_signal:=std_logic_vector(unsigned(address4)-1);
                        -- to show the current address on an output
                        result<="000000000000"&address4;  
                    end if;

                    -- checking if the last operation result is equal to zero
                    if res = "0000000000000000" then
                        -- flag register MSB will equal to '1'
                        flag_register(2)<='1';
                    else
                        -- flag register MSP will equal to '0'
                        flag_register(2)<='0';
                    end if;

                    -- incrementing the program counter after the instruction execution ends
                    pc_signal:=std_logic_vector(unsigned(pc_signal)+1);
                    -- assigning the pc_signal variable to the output pc
                    pc<=pc_signal;
                    -- final result for the required program
                    final_result<=reg(6)(4 downto 0);

            end if;

            -- if reset is active
            else
                -- reset pc_signal variable
                pc_signal:="0000";
                -- assigning the pc_signal variable to the output pc
                pc<=pc_signal;
                -- result output result
                result<="0000000000000000";
        end if;

    end process; -- end process

end cpu_equations; -- end architecture