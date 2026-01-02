module ahb_stimulus (ahb_if vif);

  //---------------------------------------
  // Basic helpers
  //---------------------------------------
  task idle();
    vif.HTRANS <= 2'b00; // IDLE
    vif.HREADY <= 0;
    vif.HWRITE <= 0;
  endtask

  task nonseq(input logic write, input logic [31:0] addr);
    vif.HTRANS <= 2'b10; // NONSEQ
    vif.HREADY <= 1;
    vif.HWRITE <= write;
    vif.HADDR  <= addr;
  endtask

  task seq(input logic [31:0] addr);
    vif.HTRANS <= 2'b11; // SEQ
    vif.HREADY <= 1;
    vif.HADDR  <= addr;
  endtask

  //---------------------------------------
  // 1. SEQ must follow NONSEQ/SEQ
  //---------------------------------------
  task illegal_seq();
    @(posedge vif.HCLK);
    vif.HTRANS <= 2'b11; // SEQ ngay sau IDLE -> lỗi
    vif.HREADY <= 1;
  endtask

  task legal_seq_after_nonseq();
    nonseq(0, 32'h2000);
    @(posedge vif.HCLK);
    seq(32'h2004); // SEQ sau NONSEQ -> hợp lệ
  endtask

  //---------------------------------------
  // 2. Handshake: hold when HREADY=0
  //---------------------------------------
  task illegal_hready_change();
    @(posedge vif.HCLK);
    vif.HREADY <= 0;
    vif.HTRANS <= 2'b10;
    @(posedge vif.HCLK);
    vif.HTRANS <= 2'b11; // thay đổi khi HREADY=0 -> lỗi
  endtask

  task legal_hready_stall();
    @(posedge vif.HCLK);
    vif.HREADY <= 0;
    vif.HTRANS <= 2'b10;
    @(posedge vif.HCLK);
    vif.HTRANS <= 2'b10; // giữ nguyên khi stall -> hợp lệ
  endtask

  //---------------------------------------
  // 3. Burst address increment (INCR)
  //---------------------------------------
  task legal_incr_burst();
    vif.HBURST <= 3'b001; // INCR
    nonseq(0, 32'h0000_0000);
    repeat (3) begin
      @(posedge vif.HCLK);
      seq(vif.HADDR + 4);
    end
  endtask

  task illegal_incr_burst();
    vif.HBURST <= 3'b001; // INCR
    nonseq(0, 32'h0000_0000);
    @(posedge vif.HCLK);
    seq(32'h0000_0008); // nhảy sai địa chỉ -> lỗi
  endtask

  //---------------------------------------
  // 3b. Burst address wrap (WRAP)
  //---------------------------------------
  task legal_wrap_burst();
    vif.HBURST <= 3'b010; // WRAP4
    nonseq(0, 32'h0000_0000);
    @(posedge vif.HCLK);
    seq(32'h0000_0004);
    @(posedge vif.HCLK);
    seq(32'h0000_0008);
    @(posedge vif.HCLK);
    seq(32'h0000_000C);
    @(posedge vif.HCLK);
    seq(32'h0000_0000); // wrap lại -> hợp lệ
  endtask

  //---------------------------------------
  // 4. HGRANT/HBUSREQ
  //---------------------------------------
  task illegal_hgrant();
    @(posedge vif.HCLK);
    vif.HGRANT  <= 1;
    vif.HBUSREQ <= 0; // grant mà không request -> lỗi
  endtask

  task legal_hgrant();
    @(posedge vif.HCLK);
    vif.HGRANT  <= 1;
    vif.HBUSREQ <= 1; // grant khi có request -> hợp lệ
  endtask

  //---------------------------------------
  // 5. HLOCK behavior
  //---------------------------------------
  task legal_hlock_burst();
    @(posedge vif.HCLK);
    vif.HLOCK   <= 1;
    nonseq(0, 32'h3000);
    repeat (4) begin
      @(posedge vif.HCLK);
      seq(vif.HADDR + 4);
    end
    @(posedge vif.HCLK);
    vif.HLOCK   <= 0; // kết thúc burst -> hợp lệ
  endtask

  //---------------------------------------
  // 6. HRESP valid when ready
  //---------------------------------------
  task legal_error_resp();
    @(posedge vif.HCLK);
    vif.HREADY <= 1;
    vif.HRESP  <= 2'b01; // ERROR hợp lệ
  endtask

  task illegal_hresp();
    @(posedge vif.HCLK);
    vif.HREADY <= 1;
    vif.HRESP  <= 2'b10; // giá trị không hợp lệ -> lỗi
  endtask

  //---------------------------------------
  // 7. HRDATA only valid on read + ready
  //---------------------------------------
  task illegal_hrdata_change();
    @(posedge vif.HCLK);
    vif.HWRITE <= 1;
    vif.HREADY <= 0;
    vif.HRDATA <= 32'hAAAA_BBBB; // thay đổi khi không hợp lệ -> lỗi
  endtask

  task legal_read_transfer();
    @(posedge vif.HCLK);
    vif.HWRITE <= 0;
    vif.HREADY <= 1;
    vif.HTRANS <= 2'b10;
    vif.HRDATA <= 32'h1234_5678; // dữ liệu hợp lệ
  endtask

  //---------------------------------------
  // 8. BUSY not stuck forever
  //---------------------------------------
  task illegal_busy_stuck();
    repeat (7) begin
      @(posedge vif.HCLK);
      vif.HTRANS <= 2'b01; // BUSY
      vif.HREADY <= 0;
    end
  endtask

  task legal_busy_exit();
    @(posedge vif.HCLK);
    vif.HTRANS <= 2'b01; // BUSY
    vif.HREADY <= 0;
    @(posedge vif.HCLK);
    nonseq(0, 32'h4000); // thoát BUSY -> hợp lệ
  endtask

  //---------------------------------------
  // 9. No data phase after IDLE
  //---------------------------------------
  task illegal_data_after_idle();
    @(posedge vif.HCLK);
    vif.HTRANS <= 2'b00; // IDLE
    vif.HREADY <= 1;     // dữ liệu hợp lệ sau IDLE -> lỗi
  endtask

  //---------------------------------------
  // 10. HWRITE only when ready
  //---------------------------------------
  task illegal_write();
    @(posedge vif.HCLK);
    vif.HWRITE <= 1;
    vif.HREADY <= 0; // ghi khi chưa ready -> lỗi
  endtask

  task legal_write();
    @(posedge vif.HCLK);
    vif.HWRITE <= 1;
    vif.HREADY <= 1; // ghi khi ready -> hợp lệ
    vif.HTRANS <= 2'b10;
  endtask

  //---------------------------------------
  // 11. HRESP stable when not ready
  //---------------------------------------
  task illegal_hresp_change();
    @(posedge vif.HCLK);
    vif.HREADY <= 0;
    vif.HRESP  <= 2'b00;
    @(posedge vif.HCLK);
    vif.HRESP  <= 2'b01; // thay đổi khi stall -> lỗi
  endtask

  //---------------------------------------
  // 12. Illegal BUSY + stall too long
  //---------------------------------------
  task illegal_busy_stall();
    repeat (7) begin
      @(posedge vif.HCLK);
      vif.HTRANS <= 2'b01; // BUSY
      vif.HREADY <= 0;
    end
  endtask

endmodule
