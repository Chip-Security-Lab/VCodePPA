//SystemVerilog
module fixed_priority_arbiter #(parameter REQ_WIDTH = 4) (
  input wire clk, rst_n,
  input wire [REQ_WIDTH-1:0] request,
  output reg [REQ_WIDTH-1:0] grant
);

  reg [REQ_WIDTH-1:0] grant_next;
  wire [REQ_WIDTH-1:0] request_mask;
  
  // Generate request mask
  assign request_mask[0] = request[0];
  generate
    genvar i;
    for (i = 1; i < REQ_WIDTH; i = i + 1) begin : mask_gen
      assign request_mask[i] = request[i] & ~(|request[i-1:0]);
    end
  endgenerate

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grant <= {REQ_WIDTH{1'b0}};
    end else begin
      grant <= request_mask;
    end
  end

endmodule