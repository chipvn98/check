interface ahb_if ();

  // Clock & Reset
  logic HCLK;
  logic HRESETn;

  // AHB signals
  logic [1:0] HTRANS;
  logic       HWRITE;
  logic       HREADY;
  logic [31:0] HADDR;
  logic [31:0] HWDATA;
  logic [31:0] HRDATA;
  logic [1:0]  HRESP;
  logic [2:0]  HBURST; 

  // Các tín hiệu bổ sung cho assertion
  logic       HGRANT;   // Grant từ arbiter
  logic       HBUSREQ;  // Bus request từ master
  logic       HLOCK;    // Lock burst

  // Clocking block
  clocking cb @(posedge HCLK);
    input HTRANS;
    input HWRITE;
    input HREADY;
    input HADDR;
    input HRDATA;
    input HRESP;
    input HBURST; 
    input HGRANT;
    input HBUSREQ;
    input HLOCK;
  endclocking

endinterface

