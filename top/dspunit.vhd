--   ----------------------------------------------------------------------
--   DspUnit : Advanced So(P)C Sequential Signal Processor
--   Copyright (C) 2007-2009 by Adrien LELONG (www.lelongdunet.com)
--
--   This program is free software; you can redistribute it and/or modify
--   it under the terms of the GNU General Public License as published by
--   the Free Software Foundation; either version 2 of the License, or
--   (at your option) any later version.
--
--   This program is distributed in the hope that it will be useful,
--   but WITHOUT ANY WARRANTY; without even the implied warranty of
--   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--   GNU General Public License for more details.
--
--   You should have received a copy of the GNU General Public License
--   along with this program; if not, write to the
--   Free Software Foundation, Inc.,
--   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
--   ----------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.dspalu_pac.all;
use work.dspunit_pac.all;
-------------------------------------------------------------------------------

entity dspunit is
  port (
    --@inputs
    clk                      : in std_logic;
    clk_cpu                  : in std_logic;
    reset                      : in std_logic;
    --@outputs;
    -- memory 0
    data_in_m0               : in std_logic_vector((sig_width - 1) downto 0);
    data_out_m0              : out std_logic_vector((sig_width - 1) downto 0);
    addr_r_m0                : out std_logic_vector((cmdreg_width - 1) downto 0);
    addr_w_m0                : out std_logic_vector((cmdreg_width - 1) downto 0);
    wr_en_m0                 : out std_logic;
    c_en_m0                  : out std_logic;
    -- memory 1
    data_in_m1               : in std_logic_vector((sig_width - 1) downto 0);
    data_out_m1              : out std_logic_vector((sig_width - 1) downto 0);
    addr_m1                : out std_logic_vector((cmdreg_width - 1) downto 0);
    wr_en_m1                 : out std_logic;
    c_en_m1                  : out std_logic;
    -- memory 2
    data_in_m2               : in std_logic_vector((sig_width - 1) downto 0);
    data_out_m2              : out std_logic_vector((sig_width - 1) downto 0);
    addr_m2                : out std_logic_vector((cmdreg_width - 1) downto 0);
    wr_en_m2                 : out std_logic;
    c_en_m2                  : out std_logic;
    -- cmd registers
    addr_cmdreg               : in std_logic_vector((cmdreg_addr_width - 1) downto 0);
    data_in_cmdreg           : in std_logic_vector((cmdreg_data_width - 1) downto 0);
    wr_en_cmdreg                : in std_logic;
    data_out_cmdreg          : out std_logic_vector((cmdreg_data_width - 1) downto 0);
      debug                    : out std_logic_vector(15 downto 0);
    op_done                     : out std_logic
);
end dspunit;
--=----------------------------------------------------------------------------
architecture archi_dspunit of dspunit is
  -----------------------------------------------------------------------------
  -- @constants definition
  -----------------------------------------------------------------------------
  --=--------------------------------------------------------------------------
  --
  -- @component declarations
  --
  -----------------------------------------------------------------------------
  component dspalu_acc
    generic (
      sig_width               : integer ;
      acc_width		    : integer
	);
    port (
      a1                       : in std_logic_vector((sig_width - 1) downto 0);
      b1                       : in std_logic_vector((sig_width - 1) downto 0);
      a2                       : in std_logic_vector((sig_width - 1) downto 0);
      b2                       : in std_logic_vector((sig_width - 1) downto 0);
      clk                      : in std_logic;
      clr_acc                  : in std_logic;
      acc_mode1                : in t_acc_mode;
      acc_mode2                : in t_acc_mode;
      alu_select               : in t_alu_select;
      cmp_mode                 : in t_cmp_mode;
      cmp_pol                    : in std_logic;
      cmp_store                  : in std_logic;
      chain_acc                  : in std_logic;
      result1                  : out std_logic_vector((sig_width - 1) downto 0);
      result_acc1              : out std_logic_vector((acc_width - 1) downto 0);
      result2                  : out std_logic_vector((sig_width - 1) downto 0);
      result_acc2              : out std_logic_vector((acc_width - 1) downto 0);
      result_sum               : out std_logic_vector((2*sig_width - 1) downto 0);
    cmp_reg                    : out std_logic_vector((acc_width - 1) downto 0);
    cmp_greater                    : out std_logic;
    cmp_out                    : out std_logic
	);
  end component;
  component cpflip
    port (
      clk                      : in std_logic;
      op_en                    : in std_logic;
      data_in_m2               : in std_logic_vector((sig_width - 1) downto 0);
      length_reg               : in std_logic_vector((cmdreg_width -1) downto 0);
      dsp_bus                  : out t_dsp_bus
	);
  end component;
  component cpmem
    port (
      clk                      : in std_logic;
      op_en                    : in std_logic;
      data_in_m0               : in std_logic_vector((sig_width - 1) downto 0);
      length_reg               : in std_logic_vector((cmdreg_width -1) downto 0);
      dsp_bus                  : out t_dsp_bus
	);
  end component;
  component sigshift
    port (
  	 clk                      : in std_logic;
  	 op_en                    : in std_logic;
  	 data_in_m0               : in std_logic_vector((sig_width - 1) downto 0);
  	 length_reg               : in std_logic_vector((cmdreg_width -1) downto 0);
  	 shift_reg               : in std_logic_vector((cmdreg_width -1) downto 0);
	 opflag_select            : in std_logic_vector((opflag_width - 1) downto 0);
  	 dsp_bus                  : out t_dsp_bus
	);
  end component;
  --=--------------------------------------------------------------------------
  -- @signals definition
  -----------------------------------------------------------------------------
  signal s_dsp_cmdregs       : t_dsp_cmdregs;
  signal s_clr_acc           : std_logic;
  signal s_alu_result1       : std_logic_vector((sig_width - 1) downto 0);
  signal s_alu_result_acc1   : std_logic_vector((acc_width - 1) downto 0);
  signal s_alu_result2       : std_logic_vector((sig_width - 1) downto 0);
  signal s_alu_result_acc2   : std_logic_vector((acc_width - 1) downto 0);
  signal s_alu_result_sum    : std_logic_vector((2 * sig_width - 1) downto 0);
  signal s_gcount             : unsigned(15 downto 0);
  signal s_dsp_bus           : t_dsp_bus;
  signal s_opflag_select_inreg  : std_logic_vector((opflag_width - 1) downto 0);
  signal s_opflag_select     : std_logic_vector((opflag_width - 1) downto 0);
  signal s_opcode_select_inreg  : std_logic_vector((opcode_width - 1) downto 0);
  signal s_opcode_select     : std_logic_vector((opcode_width - 1) downto 0);
  signal s_offset_0          : unsigned((cmdreg_width - 1) downto 0);
  signal s_offset_1          : unsigned((cmdreg_width - 1) downto 0);
  signal s_offset_2          : unsigned((cmdreg_width - 1) downto 0);
  signal s_test              : std_logic_vector(15 downto 0);
  signal s_op_cpflip_en      : std_logic;
  signal s_dsp_bus_cpflip    : t_dsp_bus;
  signal s_op_cpmem_en       : std_logic;
  signal s_dsp_bus_cpmem    : t_dsp_bus;
  signal s_runop             : std_logic;
  signal s_runop_sync        : std_logic;
  signal s_op_done_sync      : std_logic;
  signal s_op_done_resync    : std_logic;
  signal s_alu_cmp_reg       : std_logic_vector((acc_width - 1) downto 0);
  signal s_alu_cmp_out       : std_logic;
  signal s_cmp_greater       : std_logic;
  signal s_dsp_bus_sigshift     : t_dsp_bus;
  signal s_op_sigshift_en    : std_logic;
  signal s_chain_acc         : std_logic;
begin  -- archs_dspunit
  -----------------------------------------------------------------------------
  --
  -- @instantiations
  --
  -----------------------------------------------------------------------------
  dspalu_acc_1 : dspalu_acc
    generic map (
	  sig_width 	=> sig_width,
	  acc_width 	=> acc_width)
    port map (
	  a1 	=> s_dsp_bus.mul_in_a1,
	  b1 	=> s_dsp_bus.mul_in_b1,
	  a2 	=> s_dsp_bus.mul_in_a2,
	  b2 	=> s_dsp_bus.mul_in_b2,
	  clk 	=> clk,
	  clr_acc 	=> s_clr_acc,
	  acc_mode1 	=> s_dsp_bus.acc_mode1,
	  acc_mode2 	=> s_dsp_bus.acc_mode2,
	  alu_select 	=> s_dsp_bus.alu_select,
	  cmp_mode      => s_dsp_bus.cmp_mode,
	  cmp_pol       => s_dsp_bus.cmp_pol,
	  cmp_store     => s_dsp_bus.cmp_store,
	  chain_acc     => s_chain_acc,
	  result1 	=> s_alu_result1,
	  result_acc1 	=> s_alu_result_acc1,
	  result2 	=> s_alu_result2,
	  result_acc2 	=> s_alu_result_acc2,
	  result_sum 	=> s_alu_result_sum,
	  cmp_reg       => s_alu_cmp_reg,
	cmp_greater => s_cmp_greater,
	cmp_out => s_alu_cmp_out);

  cpflip_1 : cpflip
    port map (
	  clk 	=> clk,
	  op_en 	=> s_op_cpflip_en,
	  data_in_m2 	=> data_in_m2,
	  length_reg 	=> s_dsp_cmdregs(DSPADDR_LENGTH0),
	  dsp_bus 	=> s_dsp_bus_cpflip);

  cpmem_1 : cpmem
    port map (
	  clk 	=> clk,
	  op_en 	=> s_op_cpmem_en,
	  data_in_m0 	=> data_in_m0,
	  length_reg 	=> s_dsp_cmdregs(DSPADDR_LENGTH0),
	  dsp_bus 	=> s_dsp_bus_cpmem);

  sigshift_1 : sigshift
    port map (
	  clk 	=> clk,
	  op_en 	=> s_op_sigshift_en,
	  data_in_m0 	=> data_in_m0,
	  length_reg 	=> s_dsp_cmdregs(DSPADDR_LENGTH0),
	  shift_reg 	=> s_dsp_cmdregs(DSPADDR_LENGTH1),
	  opflag_select => s_opflag_select,
	  dsp_bus 	=> s_dsp_bus_sigshift);

  --=---------------------------------------------------------------------------
  -------------------------------------------------------------------------------
  -- writing registers of the dspunit
  -------------------------------------------------------------------------------
  p_cmdreg : process (clk_cpu, reset)
  begin -- process p_cmdreg
    if reset = '0' then
      --for i in 0 to (2**cmdreg_addr_width - 1) loop
      for i in 0 to 15 loop
        s_dsp_cmdregs(i) <= (others => '0');
      end loop;
    elsif rising_edge(clk_cpu) then  -- rising clock edge
      if(wr_en_cmdreg = '1') then
        s_dsp_cmdregs(to_integer(unsigned(addr_cmdreg))) <= data_in_cmdreg;
      else
        if(s_op_done_resync = '1') then
          s_dsp_cmdregs(DSPADDR_SR)(DSP_SRBIT_OPDONE) <= '1';
--	if(s_dsp_cmdregs(DSPADDR_SR)(DSP_SRBIT_OPDONE) = 1) then
	  s_dsp_cmdregs(DSPADDR_SR)(DSP_SRBIT_RUN) <= '0';
	end if;
      end if;
      data_out_cmdreg   <= s_dsp_cmdregs(to_integer(unsigned(addr_cmdreg)));
      s_op_done_sync <= s_dsp_bus.op_done;
      s_op_done_resync <= s_op_done_sync;
    end if;
  end process p_cmdreg;
  debug <= s_dsp_cmdregs(DSPADDR_SR);
--  -------------------------------------------------------------------------------
--  -- Compute a circular convolution
--  -------------------------------------------------------------------------------
--  p_conv_circ : process (clk)
--  begin -- process p_conv_circ
--    elsif rising_edge(clk) then  -- rising clock edge
--      if(conv_circ_op_en = '0') then
--        -- perform reset to all signals associated with
--        s_dsp_bus_conv_circ <= s_dsp_bus_init;
--	s_state_conv_circ <= st_conv_circ_init;
--      else
--        -- Main state machin of the conv_circ operator
--        case s_state_conv_circ is
--	  when st_conv_circ_init =>
--	    s_dsp_bus_conv_circ.addr_r_m0 <= s_dsp_bus_conv_circ.addr_r_m0 + 1;
--	  when others =>
--	    null;
--	end case;
--      end if;
--    end if;
--  end process p_conv_circ;
  -------------------------------------------------------------------------------
  -- Global counter
  -------------------------------------------------------------------------------
  p_count : process (clk)
  begin -- process p_count
    if rising_edge(clk) then  -- rising clock edge
      if s_dsp_bus.gcounter_reset = '1' then
        s_gcount <= (others => '0');
      else
        s_gcount <= s_gcount + 1;
      end if;
    end if;
  end process p_count;
  -------------------------------------------------------------------------------
  -- Synchronization of command signals to the dspunit clock
  -------------------------------------------------------------------------------
  p_synccmd : process (clk)
  begin -- process p_synccmd
    if rising_edge(clk) then  -- rising clock edge
      s_runop_sync <= s_dsp_cmdregs(DSPADDR_SR)(DSP_SRBIT_RUN);
      s_runop <= s_runop_sync;
      s_opcode_select <= s_opcode_select_inreg;
      s_opflag_select <= s_opflag_select_inreg;
    end if;
  end process p_synccmd;
  --=---------------------------------------------------------------------------
  --
  -- @concurrent signal assignments
  --
  -----------------------------------------------------------------------------
  -------------------------------------------------------------------------------
  -- reading of config registers
  -------------------------------------------------------------------------------
  -------------------------------------------------------------------------------
  -- multiplexer of the dsp unit bus
  -------------------------------------------------------------------------------
  s_opcode_select_inreg <= s_dsp_cmdregs(DSPADDR_OPCODE)((opcode_width - 1) downto 0) when s_runop = '1' else (others => '0');
  s_opflag_select_inreg <= s_dsp_cmdregs(DSPADDR_OPCODE)((opflag_width + opcode_width - 1) downto (opcode_width));
  s_op_cpflip_en <= '1' when s_opcode_select = opcode_cpflip else '0';
  s_op_cpmem_en <= '1' when s_opcode_select = opcode_cpmem else '0';
  s_op_sigshift_en <= '1' when s_opcode_select = opcode_sigshift else '0';
  s_dsp_bus         <=
      s_dsp_bus_cpflip when s_opcode_select = opcode_cpflip else
      s_dsp_bus_cpmem when s_opcode_select = opcode_cpmem else
      s_dsp_bus_sigshift when s_opcode_select = opcode_sigshift else
      c_dsp_bus_init;


  -------------------------------------------------------------------------------
  -- bus to output ports
  -------------------------------------------------------------------------------
  -- memory 0
  data_out_m0              <= s_dsp_bus.data_out_m0;
  addr_r_m0                <= std_logic_vector(s_dsp_bus.addr_r_m0 + s_offset_0);
  addr_w_m0                <= std_logic_vector(s_dsp_bus.addr_w_m0 + s_offset_0);
  wr_en_m0                 <= s_dsp_bus.wr_en_m0;
  c_en_m0                  <= s_dsp_bus.c_en_m0;
  -- memory 1
  data_out_m1              <= s_dsp_bus.data_out_m1;
  addr_m1                <= std_logic_vector(s_dsp_bus.addr_m1 + s_offset_1);
  wr_en_m1                 <= s_dsp_bus.wr_en_m1;
  c_en_m1                  <= s_dsp_bus.c_en_m1;
  -- memory 2
  data_out_m2              <= s_dsp_bus.data_out_m2;
  addr_m2                <= std_logic_vector(s_dsp_bus.addr_m2 + s_offset_2);
  wr_en_m2                 <= s_dsp_bus.wr_en_m2;
  c_en_m2                  <= s_dsp_bus.c_en_m2;


  op_done                     <= s_dsp_bus.op_done;

  s_offset_0         <= unsigned(s_dsp_cmdregs(DSPADDR_STARTADDR0));
  s_offset_1         <= unsigned(s_dsp_cmdregs(DSPADDR_STARTADDR1));
  s_offset_2         <= unsigned(s_dsp_cmdregs(DSPADDR_STARTADDR2));
  s_clr_acc          <= not reset;
end archi_dspunit;
-------------------------------------------------------------------------------
