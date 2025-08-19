//SystemVerilog
module fixed_priority_arbiter #(parameter REQ_WIDTH = 4) (
  input wire clk, rst_n,
  input wire [REQ_WIDTH-1:0] request,
  output reg [REQ_WIDTH-1:0] grant
);

  // Conditional inversion signals
  wire [REQ_WIDTH-1:0] inverted_req;
  wire [REQ_WIDTH-1:0] select;
  wire [REQ_WIDTH-1:0] result;
  
  // Generate inverted request signals
  assign inverted_req = ~request;
  
  // Generate select signals based on priority
  assign select[0] = 1'b1;
  assign select[1] = ~request[0];
  assign select[2] = ~(request[0] | request[1]);
  assign select[3] = ~(request[0] | request[1] | request[2]);
  
  // Conditional inversion logic
  assign result[0] = request[0];
  assign result[1] = select[1] ? request[1] : inverted_req[1];
  assign result[2] = select[2] ? request[2] : inverted_req[2];
  assign result[3] = select[3] ? request[3] : inverted_req[3];

  // Grant generation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      grant <= {REQ_WIDTH{1'b0}};
    else
      grant <= result;
  end

endmodule