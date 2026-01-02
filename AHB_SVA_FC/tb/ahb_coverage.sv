module ahb_coverage (ahb_if vif);

  // Khai báo biến covergroup
  covergroup cg_ahb @(posedge vif.HCLK);

    coverpoint vif.HTRANS {
      bins idle    = {2'b00};
      bins busy    = {2'b01};
      bins nonseq  = {2'b10};
      bins seq     = {2'b11};
    }

    coverpoint vif.HWRITE {
      bins read  = {0};
      bins write = {1};
    }

    coverpoint vif.HRESP {
      bins okay  = {2'b00};
      bins error = {2'b01};
    }

    coverpoint vif.HBURST {
      bins single = {3'b000};
      bins incr   = {3'b001};
      bins wrap4  = {3'b010};
      bins incr4  = {3'b011};
      bins wrap8  = {3'b100};
      bins incr8  = {3'b101};
      bins wrap16 = {3'b110};
      bins incr16 = {3'b111};
    }

    coverpoint vif.HREADY {
      bins ready    = {1};
      bins notready = {0};
    }

    coverpoint vif.HLOCK {
      bins unlocked = {0};
      bins locked   = {1};
    }

    coverpoint vif.HBUSREQ {
      bins req_off = {0};
      bins req_on  = {1};
    }

    coverpoint vif.HGRANT {
      bins grant_off = {0};
      bins grant_on  = {1};
    }

    cross vif.HTRANS, vif.HWRITE;
    cross vif.HBURST, vif.HRESP;
    cross vif.HREADY, vif.HRESP;
    cross vif.HLOCK, vif.HTRANS;
    cross vif.HGRANT, vif.HBUSREQ;

  endgroup

  // Khai báo biến không gán kiểu
  cg_ahb cg;

  initial begin
    cg = new(); // Gọi new đúng cú pháp QuestaSim 10.2c
  end

endmodule
