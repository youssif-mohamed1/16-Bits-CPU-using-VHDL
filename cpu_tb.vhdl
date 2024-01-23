library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu_tb is 
end cpu_tb;

architecture test of cpu_tb is 
    component cpu 
        port(
            reset:in std_logic:='0'; -- To reset program counter
            clk:in std_logic; -- clk input
            pc:out std_logic_vector(3 downto 0):="0000"; -- Program Counter
            result:out std_logic_vector(15 downto 0); -- result for the last instruction result
            flag_register:inout std_logic_vector(2 downto 0):="000"; -- MSB: for zero flag, bit 1: for Overflow, LSB: for carry  
            final_result:out std_logic_vector(4 downto 0) -- final result for the required program
        );
    end component;
        signal reset: std_logic:='0'; -- To reset program counter
        signal clk: std_logic:='0'; -- clk input
        signal pc: std_logic_vector(3 downto 0):="0000"; -- Program Counter
        signal result: std_logic_vector(15 downto 0); -- result for the last instruction result
        signal flag_register: std_logic_vector(2 downto 0):="000"; -- MSB: for zero flag, bit 1: for Overflow, LSB: for carry  
        signal final_result: std_logic_vector(4 downto 0); -- final result for the required program
begin
    cpu_port:cpu port map(reset,clk,pc,result,flag_register,final_result);
    process begin
        for i in 1 to 200 loop
            clk <= not clk;
            wait for 0.5 ns;
        end loop;
        wait;
    end process;
end test;