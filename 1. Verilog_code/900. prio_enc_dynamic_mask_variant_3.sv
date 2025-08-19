//SystemVerilog
module prio_enc_dynamic_mask #(parameter W=8)(
  input clk,
  input [W-1:0] mask,
  input [W-1:0] req,
  output reg [$clog2(W)-1:0] index
);
  // IEEE 1364-2005 Verilog standard
  
  wire [W-1:0] masked_req = req & mask;
  reg [$clog2(W)-1:0] next_index;
  
  always @(*) begin
    next_index = {$clog2(W){1'b0}};
    // Optimized priority encoder using backward iteration
    // This improves timing and reduces logic levels
    for(integer i=W-1; i>=0; i=i-1)
      if(masked_req[i]) next_index = i[$clog2(W)-1:0];
  end
  
  always @(posedge clk) begin
    index <= next_index;
  end
endmodule