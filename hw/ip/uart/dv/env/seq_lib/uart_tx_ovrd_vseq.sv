// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// test TX override feature through uart.OVRD and check the pin
class uart_tx_ovrd_vseq extends uart_smoke_vseq;
  `uvm_object_utils(uart_tx_ovrd_vseq)

  `uvm_object_new

  // add orvd test on tx and make sure no side-effect on rx
  virtual task send_tx_byte(byte data);
    bit en_ovrd;
    bit txval;
    bit exp;

    // add 1 uart clk to make sure previous uart TX transfer is done completely
    #(cfg.m_uart_agent_cfg.vif.uart_clk_period);
    if (cfg.under_reset) return;

    // Disable monitor as monitor can't handle this.
    // Monitors will be restored by agent at end of reset, if one happens.
    cfg.m_uart_agent_cfg.en_tx_monitor = 0;
    repeat ($urandom_range(1, 5)) begin
      `DV_CHECK_STD_RANDOMIZE_FATAL(en_ovrd)
      `DV_CHECK_STD_RANDOMIZE_FATAL(txval)
      `DV_CHECK_MEMBER_RANDOMIZE_FATAL(dly_to_next_tx_trans)

      if (en_ovrd) exp = txval;
      else         exp = 1;
      csr_wr(.ptr(ral.ovrd), .value({txval, en_ovrd}));
      cfg.clk_rst_vif.wait_clks_or_rst(1);
      if (cfg.under_reset) return;
      `DV_CHECK_EQ(cfg.m_uart_agent_cfg.vif.uart_tx, exp)
      cfg.clk_rst_vif.wait_clks_or_rst(dly_to_next_tx_trans);
      if (cfg.under_reset) return;
    end
    // disable ovrd
    csr_wr(.ptr(ral.ovrd), .value(0));
    cfg.clk_rst_vif.wait_clks_or_rst(1);
    cfg.m_uart_agent_cfg.en_tx_monitor = 1;

    if (cfg.under_reset) return;
    super.send_tx_byte(data);
  endtask

endclass : uart_tx_ovrd_vseq
