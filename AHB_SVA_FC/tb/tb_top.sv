module tb_top;

  ahb_if vif();

  //---------------------------------------
  // Clock generation
  //---------------------------------------
  initial begin
    vif.HCLK = 0;
    forever #5 vif.HCLK = ~vif.HCLK;
  end

  //---------------------------------------
  // DUT-less TB components
  //---------------------------------------
  ahb_assertions u_assert (.vif(vif));
  ahb_stimulus   u_stim   (.vif(vif));
	ahb_coverage   u_cov    (.vif(vif));

  //---------------------------------------
  // Reset + stimulus control
  //---------------------------------------
  initial begin
    $display("[TB] Simulation start");

    // Default values
    vif.HRESETn = 0;
    vif.HTRANS  = 2'b00;
    vif.HREADY  = 0;
    vif.HWRITE  = 0;
    vif.HRESP   = 2'b00;
    vif.HBURST  = 3'b000;
    vif.HADDR   = 32'h0;
    vif.HRDATA  = 32'h0;
    vif.HGRANT  = 0;
    vif.HBUSREQ = 0;
    vif.HLOCK   = 0;

    // Apply reset
    repeat (2) @(posedge vif.HCLK);
    vif.HRESETn = 1;

    //-----------------------------------
    // Stimulus sequence
    //-----------------------------------

    // 1. SEQ must follow NONSEQ/SEQ
    u_stim.illegal_seq();
    u_stim.legal_seq_after_nonseq();

    // 2. Handshake with HREADY
    u_stim.illegal_hready_change();
    u_stim.legal_hready_stall();

    // 3. Burst INCR
    u_stim.legal_incr_burst();
    u_stim.illegal_incr_burst();

    // 3b. Burst WRAP
    u_stim.legal_wrap_burst();

    // 4. HGRANT/HBUSREQ
    u_stim.illegal_hgrant();
    u_stim.legal_hgrant();

    // 5. HLOCK
    u_stim.legal_hlock_burst();

    // 6. HRESP valid
    u_stim.legal_error_resp();
    u_stim.illegal_hresp();

    // 7. HRDATA validity
    u_stim.illegal_hrdata_change();
    u_stim.legal_read_transfer();

    // 8. BUSY not stuck forever
    u_stim.illegal_busy_stuck();
    u_stim.legal_busy_exit();

    // 9. No data after IDLE
    u_stim.illegal_data_after_idle();

    // 10. HWRITE only when ready
    u_stim.illegal_write();
    u_stim.legal_write();

    // 11. HRESP stable when not ready
    u_stim.illegal_hresp_change();

    // 12. Illegal BUSY + stall too long
    u_stim.illegal_busy_stall();

//
    // Bổ sung để đạt 100% coverage
    u_stim.legal_okay_resp();

    u_stim.legal_incr4_burst();
    u_stim.legal_wrap8_burst();
    // thêm incr8, wrap16, incr16

    u_stim.busy_read();
    u_stim.busy_write();
    u_stim.idle_read();
    u_stim.idle_write();

    u_stim.illegal_error_when_notready();

    u_stim.locked_busy();
    u_stim.locked_idle();

    u_stim.grant_off_req_on();
    u_stim.grant_off_req_off();

  end

endmodule
