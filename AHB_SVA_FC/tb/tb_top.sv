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

    // 1–12: Stimulus đã có
    u_stim.illegal_seq(); @(posedge vif.HCLK);
    u_stim.legal_seq_after_nonseq(); @(posedge vif.HCLK);
    u_stim.illegal_hready_change(); @(posedge vif.HCLK);
    u_stim.legal_hready_stall(); @(posedge vif.HCLK);
    u_stim.legal_incr_burst(); @(posedge vif.HCLK);
    u_stim.illegal_incr_burst(); @(posedge vif.HCLK);
    u_stim.legal_wrap_burst(); @(posedge vif.HCLK);
    u_stim.illegal_hgrant(); @(posedge vif.HCLK);
    u_stim.legal_hgrant(); @(posedge vif.HCLK);
    u_stim.legal_hlock_burst(); @(posedge vif.HCLK);
    u_stim.legal_error_resp(); @(posedge vif.HCLK);
    u_stim.illegal_hresp(); @(posedge vif.HCLK);
    u_stim.illegal_hrdata_change(); @(posedge vif.HCLK);
    u_stim.legal_read_transfer(); @(posedge vif.HCLK);
    u_stim.illegal_busy_stuck(); @(posedge vif.HCLK);
    u_stim.legal_busy_exit(); @(posedge vif.HCLK);
    u_stim.illegal_data_after_idle(); @(posedge vif.HCLK);
    u_stim.illegal_write(); @(posedge vif.HCLK);
    u_stim.legal_write(); @(posedge vif.HCLK);
    u_stim.illegal_hresp_change(); @(posedge vif.HCLK);
    u_stim.illegal_busy_stall(); @(posedge vif.HCLK);

    //-----------------------------------
    // Bổ sung để đạt 100% coverage
    //-----------------------------------

    // coverpoint_0# — HTRANS = IDLE
    vif.HTRANS <= 2'b00;
    vif.HREADY <= 0;
    @(posedge vif.HCLK);

    // coverpoint_13# — HBUSREQ = 0
    vif.HBUSREQ <= 0;
    @(posedge vif.HCLK);

    // coverpoint_15# — HGRANT = 0
    vif.HGRANT <= 0;
    @(posedge vif.HCLK);

    // HRESP = OKAY
    u_stim.legal_okay_resp(); @(posedge vif.HCLK);

    // Các burst còn thiếu
    u_stim.legal_incr4_burst(); @(posedge vif.HCLK);
    u_stim.legal_wrap8_burst(); @(posedge vif.HCLK);

    // incr8
    vif.HBURST <= 3'b101; vif.HRESP <= 2'b00;
    u_stim.nonseq(0, 32'h7000); @(posedge vif.HCLK);
    u_stim.seq(32'h7004); @(posedge vif.HCLK);

    // wrap16
    vif.HBURST <= 3'b110; vif.HRESP <= 2'b01;
    u_stim.nonseq(0, 32'h8000); @(posedge vif.HCLK);
    u_stim.seq(32'h8004); @(posedge vif.HCLK);

    // incr16
    vif.HBURST <= 3'b111; vif.HRESP <= 2'b00;
    u_stim.nonseq(0, 32'h9000); @(posedge vif.HCLK);
    u_stim.seq(32'h9004); @(posedge vif.HCLK);

    // BUSY/IDLE × HWRITE
    u_stim.busy_read(); @(posedge vif.HCLK);
    u_stim.busy_write(); @(posedge vif.HCLK);
    u_stim.idle_read(); @(posedge vif.HCLK);
    u_stim.idle_write(); @(posedge vif.HCLK);

    // HREADY × HRESP (cross_2#)
    vif.HREADY <= 1; vif.HRESP <= 2'b00; @(posedge vif.HCLK); // ready + OKAY
    vif.HREADY <= 1; vif.HRESP <= 2'b01; @(posedge vif.HCLK); // ready + ERROR
    vif.HREADY <= 0; vif.HRESP <= 2'b00; @(posedge vif.HCLK); // notready + OKAY
    vif.HREADY <= 0; vif.HRESP <= 2'b01; @(posedge vif.HCLK); // notready + ERROR

    // HLOCK × HTRANS
    u_stim.locked_busy(); @(posedge vif.HCLK);
    u_stim.locked_idle(); @(posedge vif.HCLK);
    vif.HLOCK <= 0; vif.HTRANS <= 2'b01; @(posedge vif.HCLK);
    vif.HLOCK <= 0; vif.HTRANS <= 2'b00; @(posedge vif.HCLK);

    // HGRANT × HBUSREQ (grant_off cases)
    u_stim.grant_off_req_on(); @(posedge vif.HCLK);
    u_stim.grant_off_req_off(); @(posedge vif.HCLK);

    // HBURST × HRESP (cross_1#)
    for (int i = 0; i < 8; i++) begin
      vif.HBURST <= i[2:0];
      vif.HREADY <= 1;
      vif.HRESP  <= 2'b00;
      u_stim.nonseq(0, 32'hB000 + i * 8); @(posedge vif.HCLK);
      vif.HRESP  <= 2'b01;
      u_stim.nonseq(0, 32'hB004 + i * 8); @(posedge vif.HCLK);
    end

    //-----------------------------------
    // End of test
    //-----------------------------------
    #50;
    $display("[TB] Simulation end");
    //$stop;
  end

endmodule
