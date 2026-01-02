module ahb_assertions (ahb_if vif);

  // AHB encodings
  localparam IDLE    = 2'b00;
  localparam BUSY    = 2'b01;
  localparam NONSEQ  = 2'b10;
  localparam SEQ     = 2'b11;

  localparam OKAY  = 2'b00;
  localparam ERROR = 2'b01;

  //---------------------------------------
  // 1. SEQ must follow NONSEQ/SEQ
  //---------------------------------------
  a_seq_after_nonseq: assert property (
    @(posedge vif.HCLK) disable iff (!vif.HRESETn)
    (vif.HTRANS == SEQ)
    |-> $past(vif.HTRANS inside {NONSEQ, SEQ})
  );

  c_seq_after_nonseq: cover property (
    @(posedge vif.HCLK) disable iff (!vif.HRESETn)
    (vif.HTRANS == NONSEQ) ##1 (vif.HTRANS == SEQ)
  );

  //---------------------------------------
  // 2. Handshake: hold when HREADY=0
  //---------------------------------------
  a_hold_when_not_ready: assert property (
    @(posedge vif.HCLK) disable iff (!vif.HRESETn)
    (!vif.HREADY)
    |-> $stable({vif.HTRANS, vif.HADDR, vif.HWRITE, vif.HBURST})
  );

  c_hready_stall: cover property (
    @(posedge vif.HCLK)
    (!vif.HREADY)
  );

  //---------------------------------------
  // 3. Burst address increment (INCR)
  //---------------------------------------
  a_incr_addr: assert property (
    @(posedge vif.HCLK) disable iff (!vif.HRESETn)
    (vif.HTRANS == SEQ &&
     vif.HBURST == 3'b001 && // INCR
     vif.HREADY)
    |-> (vif.HADDR == $past(vif.HADDR) + 4)
  );

  c_incr_burst: cover property (
    @(posedge vif.HCLK) disable iff (!vif.HRESETn)
    (vif.HTRANS == NONSEQ && vif.HBURST == 3'b001)
    ##1 (vif.HTRANS == SEQ)
    ##1 (vif.HTRANS == SEQ)
  );

  //---------------------------------------
  // 3b. Burst address wrap (WRAP4/WRAP8/WRAP16)
  //---------------------------------------
  a_wrap_addr: assert property (
    @(posedge vif.HCLK) disable iff (!vif.HRESETn)
    (vif.HTRANS == SEQ &&
     vif.HBURST inside {3'b010, 3'b011, 3'b100} && // WRAP4/8/16
     vif.HREADY)
    |-> ((vif.HADDR[3:0] == ($past(vif.HADDR[3:0]) + 4) % (4 << vif.HBURST[1:0])))
  );

  c_wrap_burst: cover property (
    @(posedge vif.HCLK) disable iff (!vif.HRESETn)
    (vif.HTRANS == NONSEQ && vif.HBURST inside {3'b010,3'b011,3'b100})
    ##1 (vif.HTRANS == SEQ)
  );

  //---------------------------------------
  // 4. HGRANT/HBUSREQ relationship
  //---------------------------------------
  a_hgrant_busreq: assert property (
    @(posedge vif.HCLK) disable iff (!vif.HRESETn)
    (vif.HGRANT) |-> (vif.HBUSREQ)
  );

  c_hgrant_seen: cover property (
    @(posedge vif.HCLK)
    (vif.HGRANT)
  );

  //---------------------------------------
  // 5. HLOCK behavior
  //---------------------------------------
	a_hlock_hold: assert property (
  @(posedge vif.HCLK) disable iff (!vif.HRESETn)
  (vif.HLOCK && vif.HTRANS == NONSEQ)
  |-> (vif.HLOCK && vif.HTRANS == SEQ)[*1:6] ##1 (vif.HTRANS == IDLE)
);

  c_hlock_seen: cover property (
    @(posedge vif.HCLK)
    (vif.HLOCK)
  );

  //---------------------------------------
  // 6. HRESP valid when ready
  //---------------------------------------
  a_hresp_valid: assert property (
    @(posedge vif.HCLK)
    (vif.HREADY)
    |-> (vif.HRESP inside {OKAY, ERROR})
  );

  c_error_resp: cover property (
    @(posedge vif.HCLK)
    (vif.HREADY && vif.HRESP == ERROR)
  );

  //---------------------------------------
  // 7. HRDATA only valid on read + ready
  //---------------------------------------
  a_hrdata_valid: assert property (
    @(posedge vif.HCLK)
    (!vif.HREADY || vif.HWRITE)
    |-> $stable(vif.HRDATA)
  );

  c_read_transfer: cover property (
    @(posedge vif.HCLK)
    (vif.HREADY && !vif.HWRITE &&
     vif.HTRANS inside {NONSEQ, SEQ})
  );

  //---------------------------------------
  // 8. BUSY not stuck forever
  //---------------------------------------
  a_busy_not_forever: assert property (
    @(posedge vif.HCLK) disable iff (!vif.HRESETn)
    (vif.HTRANS == BUSY)
    |-> ##[1:6] (vif.HTRANS != BUSY)
  );

  c_busy_seen: cover property (
    @(posedge vif.HCLK)
    (vif.HTRANS == BUSY)
  );

  //---------------------------------------
  // 9. No data phase after IDLE
  //---------------------------------------
  a_no_data_after_idle: assert property (
    @(posedge vif.HCLK)
    (vif.HTRANS == IDLE)
    |-> !vif.HREADY
  );

  c_idle_seen: cover property (
    @(posedge vif.HCLK)
    (vif.HTRANS == IDLE)
  );

  //---------------------------------------
  // 10. HWRITE only when ready
  //---------------------------------------
  a_hwrite_when_ready: assert property (
    @(posedge vif.HCLK)
    vif.HWRITE |-> vif.HREADY
  );

  c_write_transfer: cover property (
    @(posedge vif.HCLK)
    (vif.HREADY && vif.HWRITE &&
     vif.HTRANS inside {NONSEQ, SEQ})
  );

  //---------------------------------------
  // 11. HRESP stable when not ready
  //---------------------------------------
  a_hresp_hold: assert property (
    @(posedge vif.HCLK)
    (!vif.HREADY)
    |-> $stable(vif.HRESP)
  );

  c_hresp_stall: cover property (
    @(posedge vif.HCLK)
    (!vif.HREADY)
  );

  //---------------------------------------
  // 12. Illegal BUSY + stall too long
  //---------------------------------------
  a_illegal_busy_stall: assert property (
    @(posedge vif.HCLK) disable iff (!vif.HRESETn)
    (vif.HTRANS == BUSY && !vif.HREADY)
    |-> ##[1:6] !(vif.HTRANS == BUSY && !vif.HREADY)
  );

  c_busy_stall: cover property (
    @(posedge vif.HCLK)
    (vif.HTRANS == BUSY && !vif.HREADY)
  );

endmodule

