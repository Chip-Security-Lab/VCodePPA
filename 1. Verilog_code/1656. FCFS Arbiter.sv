module fcfs_arbiter #(parameter PORTS = 4) (
  input wire clk, rst_n,
  input wire [PORTS-1:0] req,
  input wire [PORTS-1:0] done,
  output reg [PORTS-1:0] grant
);
  reg [PORTS-1:0] queue [0:PORTS-1];
  reg [2:0] head, tail;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      head <= 0; tail <= 0; grant <= 0;
      // Initialize queue logic would go here
    end else begin
      // Queue management and FCFS logic would go here
      if (|done) grant <= 0;
      if (head != tail && grant == 0)
        grant <= (1 << queue[head]);
    end
  end
endmodule