//SystemVerilog
module reset_sync_enable (
  input  wire clk,
  input  wire en,
  input  wire rst_n,
  output wire sync_reset
);
  
  wire en_registered;
  wire reset_stage1;
  
  // Instantiate enable register submodule
  enable_register u_enable_register (
    .clk      (clk),
    .rst_n    (rst_n),
    .en       (en),
    .en_reg   (en_registered)
  );
  
  // Instantiate first stage reset synchronizer
  reset_sync_stage1 u_reset_sync_stage1 (
    .clk        (clk),
    .rst_n      (rst_n),
    .en_reg     (en_registered),
    .stage1_out (reset_stage1)
  );
  
  // Instantiate final stage reset synchronizer
  reset_sync_stage2 u_reset_sync_stage2 (
    .clk        (clk),
    .rst_n      (rst_n),
    .en_reg     (en_registered),
    .stage1_in  (reset_stage1),
    .sync_reset (sync_reset)
  );
  
endmodule

// Enable signal registration module
// Reduces fanout and improves timing
module enable_register (
  input  wire clk,
  input  wire rst_n,
  input  wire en,
  output reg  en_reg
);
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      en_reg <= 1'b0;
    end else begin
      en_reg <= en;
    end
  end
  
endmodule

// First stage reset synchronizer
// Provides initial synchronization stage
module reset_sync_stage1 (
  input  wire clk,
  input  wire rst_n,
  input  wire en_reg,
  output reg  stage1_out
);
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      stage1_out <= 1'b0;
    end else if(en_reg) begin
      stage1_out <= 1'b1;
    end
  end
  
endmodule

// Final stage reset synchronizer
// Provides final output stage with metastability protection
module reset_sync_stage2 (
  input  wire clk,
  input  wire rst_n, 
  input  wire en_reg,
  input  wire stage1_in,
  output reg  sync_reset
);
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      sync_reset <= 1'b0;
    end else if(en_reg) begin
      sync_reset <= stage1_in;
    end
  end
  
endmodule