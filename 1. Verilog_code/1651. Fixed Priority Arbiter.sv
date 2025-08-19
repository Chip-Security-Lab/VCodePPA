module fixed_priority_arbiter #(parameter REQ_WIDTH = 4) (
  input wire clk, rst_n,
  input wire [REQ_WIDTH-1:0] request,
  output reg [REQ_WIDTH-1:0] grant
);
  integer i;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) grant <= {REQ_WIDTH{1'b0}};
    else begin
      grant <= {REQ_WIDTH{1'b0}};
      for (i = 0; i < REQ_WIDTH; i = i + 1) begin
        if (request[i] && (grant == {REQ_WIDTH{1'b0}})) 
          grant[i] <= 1'b1;
      end
    end
  end
endmodule