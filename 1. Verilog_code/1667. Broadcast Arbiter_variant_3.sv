//SystemVerilog
module broadcast_arbiter(
  input wire clk, rst_n,
  input wire [3:0] req,
  input wire broadcast,
  output reg [3:0] grant
);
  reg [3:0] priority_queue;
  reg [3:0] next_priority_queue;
  reg [3:0] next_grant;
  
  always_comb begin
    next_priority_queue = rst_n ? (broadcast ? priority_queue : {priority_queue[2:0], priority_queue[3]}) : 4'b0001;
    next_grant = rst_n ? (broadcast ? req : (req & priority_queue)) : 4'b0000;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      priority_queue <= 4'b0001;
      grant <= 4'b0000;
    end else begin
      priority_queue <= next_priority_queue;
      grant <= next_grant;
    end
  end
endmodule