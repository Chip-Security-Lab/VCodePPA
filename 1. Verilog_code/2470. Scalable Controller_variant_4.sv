//SystemVerilog
module scalable_intr_ctrl #(
  parameter SOURCES = 32,
  parameter ID_WIDTH = $clog2(SOURCES)
)(
  input wire clk, rst,
  input wire [SOURCES-1:0] requests,
  output reg [ID_WIDTH-1:0] grant_id,
  output reg grant_valid
);
  
  // Pre-calculate request presence for faster path
  reg requests_present;
  reg [ID_WIDTH-1:0] highest_priority_id;
  integer i;
  
  // Priority encoder logic separated from main sequential block
  always @(*) begin
    requests_present = 1'b0;
    highest_priority_id = {ID_WIDTH{1'b0}};
    
    for (i = SOURCES-1; i >= 0; i = i - 1) begin
      if (requests[i]) begin
        requests_present = 1'b1;
        highest_priority_id = i[ID_WIDTH-1:0];
      end
    end
  end
  
  // Sequential logic for registering outputs
  always @(posedge clk) begin
    if (rst) begin
      grant_id <= {ID_WIDTH{1'b0}};
      grant_valid <= 1'b0;
    end else begin
      grant_valid <= requests_present;
      grant_id <= highest_priority_id;
    end
  end
  
endmodule