module param_priority_arbiter #(
  parameter REQ_CNT = 8,
  parameter PRIO_WIDTH = 3
)(
  input clk, reset,
  input [REQ_CNT-1:0] requests,
  input [PRIO_WIDTH-1:0] priorities [REQ_CNT-1:0],
  output reg [REQ_CNT-1:0] grants
);
  integer i;
  reg [PRIO_WIDTH-1:0] highest_prio;
  reg [3:0] selected;
  
  always @(*) begin
    highest_prio = 0;
    selected = 0;
    for (i = 0; i < REQ_CNT; i = i + 1) begin
      if (requests[i] && priorities[i] > highest_prio) begin
        highest_prio = priorities[i];
        selected = i;
      end
    end
  end
  
  always @(posedge clk) begin
    if (reset) grants <= 0;
    else begin
      grants <= 0;
      if (|requests) grants[selected] <= 1'b1;
    end
  end
endmodule