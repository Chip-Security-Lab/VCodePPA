//SystemVerilog
module reset_sync_init_val #(parameter INIT_VAL=1'b0)(
  input  wire clk,
  input  wire rst_n,
  output wire rst_sync
);
  reg flop2;
  wire flop1_wire;
  
  // Forward retiming: Move the flop1 register logic forward
  assign flop1_wire = ~INIT_VAL;
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      flop2 <= INIT_VAL;
    end else begin
      flop2 <= flop1_wire;
    end
  end
  
  assign rst_sync = flop2;
endmodule