-- Vincenzo Bucaria
-- University of Messina, Italy
-- Bitstream loader for Argen FPGA Overlay


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
library std;
use std.textio.all;


entity bitstream_controller is
    port
    (
        reset: in std_logic;
        clk: in std_logic;
        load_btn: in std_logic; 
        application_started:out std_logic;
        ready: out std_logic; -- '1' if the loader is ready for bitstream loading
        overlay_IP_SLAVE_ACK_O: in std_logic;
        overlay_IP_SLAVE_CYC_I: out std_logic;
        overlay_IP_SLAVE_STB_I: out std_logic;
        overlay_IP_SLAVE_WE_I: out std_logic;
		overlay_IP_SLAVE_SEL_I: out std_logic_vector(3 downto 0);
		overlay_IP_SLAVE_ADR_I: out std_logic_vector(7 downto 0);
		overlay_IP_SLAVE_DAT_I:out std_logic_vector(31 downto 0)
    );

end entity bitstream_controller;


architecture behavioral of bitstream_controller is

signal rom_address:std_logic_vector(7 downto 0);
signal rom_word:std_logic_vector(31 downto 0);


type fsm_state is
      (idle, writing, waiting, ending);
      
signal state:fsm_state;      

component bitstream_rom is
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
end component;

    begin
        
the_rom: component bitstream_rom
    port map
    (
    clka=>clk,
    addra=>rom_address,
    douta=>rom_word
    );
    
process(clk, reset)
    begin
        
        if(reset = '1') then
            report "reset is now 1";
             state <= idle;
             ready <= '0';
             application_started <= '0';
             report "i'm here";
             overlay_IP_SLAVE_SEL_I <= "0000";
             overlay_IP_SLAVE_ADR_I <= "00000000";
             overlay_IP_SLAVE_CYC_I <= '0';
             overlay_IP_SLAVE_STB_I <= '0';
             overlay_IP_SLAVE_WE_I  <= '0';
             overlay_IP_SLAVE_DAT_I <= x"00000000";
            rom_address <= (others=>'0');
            report "still here";
        else
            if(clk'event and clk='1') then
                case state is
                    when idle =>
                        
                        ready <= '1';
                        
                            
                        if(load_btn = '1') then
                            application_started <= '0';
                            state <= writing;
                            ready <= '0';
                        end if;
                 
                    when writing =>
                       
                        overlay_IP_SLAVE_CYC_I <= '1';
                        overlay_IP_SLAVE_STB_I <= '1';
                        overlay_IP_SLAVE_WE_I  <= '1';
                        overlay_IP_SLAVE_SEL_I <= "1111";
                        overlay_IP_SLAVE_ADR_I <= "00001100";
                        overlay_IP_SLAVE_DAT_I <= rom_word;
                        state <= waiting;
                    
                    when waiting =>
                    
                        if (overlay_IP_SLAVE_ACK_O = '1') then
                            
                            overlay_IP_SLAVE_CYC_I <= '0';
			                overlay_IP_SLAVE_STB_I <= '0';
			                if(unsigned(rom_address) > to_unsigned(147, 8)) then
			                   if(unsigned(rom_address) > to_unsigned(148, 8)) then
                                   state <= idle;
                                   application_started <= '1';
                                   rom_address <= (others=>'0');
			                   else
			                     state <= ending;
			                   end if;
			                else
                               rom_address <= std_logic_vector(unsigned(rom_address)+1);
                               state <= writing;
                            end if;
                        end if;
                        
                        when ending =>
                        
                        overlay_IP_SLAVE_CYC_I <= '1';
                        overlay_IP_SLAVE_STB_I <= '1';
                        overlay_IP_SLAVE_WE_I  <= '1';
                        overlay_IP_SLAVE_SEL_I <= "1111";
                        overlay_IP_SLAVE_ADR_I <= "00001011";
                        overlay_IP_SLAVE_DAT_I <= x"00ffffff";
                        rom_address <= std_logic_vector(unsigned(rom_address)+1);
                        state <= waiting;
                        
                        when others =>
                    end case;
                  end if;
                  end if;
                    
      end process;
end architecture;                
                    
            
            
