module scalable_intr_ctrl #(
  parameter SOURCES = 32,
  parameter ID_WIDTH = $clog2(SOURCES)
)(
  input wire clk, rst,
  input wire [SOURCES-1:0] requests,
  output reg [ID_WIDTH-1:0] grant_id,
  output reg grant_valid
);
  integer i;
  always @(posedge clk) begin
    if (rst) begin
      grant_id <= {ID_WIDTH{1'b0}};
      grant_valid <= 1'b0;
    end else begin
      grant_valid <= |requests;
      grant_id <= {ID_WIDTH{1'b0}};
      for (i = 0; i < SOURCES; i = i + 1)
        if (requests[i]) grant_id <= i[ID_WIDTH-1:0];
    end
  end
endmodule