// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
interface uart_if #(realtime UartDefaultClkPeriod = 104166.667ns) ();
  wire uart_tx;
  logic uart_rx;

  // generate local clk
  realtime uart_clk_period = UartDefaultClkPeriod;
  bit   uart_tx_clk = 1'b1;
  int   uart_tx_clk_pulses = 0;
  bit   uart_rx_clk = 1'b1;
  int   uart_rx_clk_pulses = 0;

  // UART TX from the DUT when signaled over muxed IOs can experience glitches in the same
  // time-step (a simulation artifact). Delaying by 1ps eliminates them.
  wire uart_tx_int;
  assign #1ps uart_tx_int = uart_tx;

  // Sample TX data mid-bit as defined by the TX 'clock' generated in the monitor
  clocking mon_tx_cb @(negedge uart_tx_clk);
    input  #10ns uart_tx_int;
  endclocking
  modport mon_tx_mp(clocking mon_tx_cb);

  // Drive RX data in time with the RX 'clock' generated in the monitor
  clocking drv_rx_cb @(posedge uart_rx_clk);
    output uart_rx;
  endclocking
  modport drv_rx_mp(clocking drv_rx_cb);

  // Sample RX data mid-bit as defined by the RX 'clock' generated in the monitor
  clocking mon_rx_cb @(negedge uart_rx_clk);
    input  #10ns uart_rx;
  endclocking
  modport mon_rx_mp(clocking mon_rx_cb);

  function automatic void reset_uart_rx();
    uart_rx = 1;
  endfunction

  task automatic wait_for_tx_idle();
    wait(uart_tx_clk_pulses == 0);
  endtask

  task automatic wait_for_rx_idle();
    wait(uart_rx_clk_pulses == 0);
  endtask

  task automatic wait_for_idle();
    fork
      wait_for_tx_idle();
      wait_for_rx_idle();
    join
  endtask

  task automatic drive_uart_rx_glitch(int max_glitch_ps, int stable_ps_after_glitch);
    uart_rx = ~uart_rx;
    randcase
      1: #(max_glitch_ps * 1ps);
      1: #($urandom_range(1, max_glitch_ps) * 1ps);
    endcase
    uart_rx = ~uart_rx;
    #(stable_ps_after_glitch * 1ps);
  endtask

endinterface
