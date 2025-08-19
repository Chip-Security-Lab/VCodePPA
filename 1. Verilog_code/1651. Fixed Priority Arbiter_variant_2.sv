//SystemVerilog
module fixed_priority_arbiter #(parameter REQ_WIDTH = 4) (
  input wire clk, rst_n,
  input wire [REQ_WIDTH-1:0] request,
  output reg [REQ_WIDTH-1:0] grant
);

  wire [REQ_WIDTH-1:0] grant_next;
  wire [REQ_WIDTH-1:0] mask;
  
  // Generate mask for priority encoding
  genvar i;
  generate
    for (i = 0; i < REQ_WIDTH; i = i + 1) begin : gen_mask
      if (i == 0)
        assign mask[i] = 1'b1;
      else
        assign mask[i] = ~(|request[i-1:0]);
    end
  endgenerate
  
  // Priority encoding using mask
  assign grant_next = request & mask;
  
  // Register output
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      grant <= {REQ_WIDTH{1'b0}};
    else
      grant <= grant_next;
  end

endmodule