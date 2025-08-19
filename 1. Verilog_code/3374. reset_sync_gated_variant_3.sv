//SystemVerilog
module reset_sync_gated(
  input  wire clk,
  input  wire gate_en,
  input  wire rst_n,
  output wire synced_rst
);
  reg flp_stage1;
  reg flp_stage2;
  
  // Registered version of inputs to reduce input-to-register delay
  reg gate_en_reg;
  
  // Move reset detection logic after register to balance paths
  wire update_condition;
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      gate_en_reg <= 1'b0;
      flp_stage1  <= 1'b0;
      flp_stage2  <= 1'b0;
    end else begin
      // Register input immediately to reduce input delay
      gate_en_reg <= gate_en;
      
      // Move logic behind registers
      flp_stage1  <= 1'b1;
      flp_stage2  <= gate_en_reg ? flp_stage1 : flp_stage2;
    end
  end
  
  // Assign output through wire to maintain interface
  assign synced_rst = flp_stage2;
  
endmodule