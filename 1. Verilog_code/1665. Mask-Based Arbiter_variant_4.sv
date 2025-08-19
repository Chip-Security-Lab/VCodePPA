//SystemVerilog
module mask_arbiter(
  input i_clk, i_rstn,
  input [7:0] i_req,
  input [7:0] i_mask,
  output reg [7:0] o_grant
);

  // Pre-compute masked requests
  wire [7:0] masked_req = i_req & i_mask;
  
  // Split priority encoding into balanced groups
  wire [3:0] upper_req = masked_req[7:4];
  wire [3:0] lower_req = masked_req[3:0];
  
  // Parallel priority encoding for upper and lower nibbles
  wire [3:0] upper_grant = (upper_req[3]) ? 4'b1000 :
                          (upper_req[2]) ? 4'b0100 :
                          (upper_req[1]) ? 4'b0010 :
                          (upper_req[0]) ? 4'b0001 : 4'b0000;
                          
  wire [3:0] lower_grant = (lower_req[3]) ? 4'b1000 :
                          (lower_req[2]) ? 4'b0100 :
                          (lower_req[1]) ? 4'b0010 :
                          (lower_req[0]) ? 4'b0001 : 4'b0000;
  
  // Combine results with priority selection
  wire [7:0] grant_comb = (|upper_req) ? {upper_grant, 4'b0000} : {4'b0000, lower_grant};

  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) 
      o_grant <= 8'h0;
    else 
      o_grant <= grant_comb;
  end

endmodule