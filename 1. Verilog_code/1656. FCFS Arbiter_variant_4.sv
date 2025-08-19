//SystemVerilog
module fcfs_arbiter #(parameter PORTS = 4) (
  input wire clk, rst_n,
  input wire [PORTS-1:0] req,
  input wire [PORTS-1:0] done,
  output reg [PORTS-1:0] grant
);

  reg [PORTS-1:0] queue [0:PORTS-1];
  reg [2:0] head, tail;
  wire queue_empty = (head == tail);
  wire [2:0] next_tail = {tail[2], tail[1:0] + 1'b1};
  wire queue_full = (next_tail == head);
  wire [PORTS-1:0] req_valid = req & ~(|grant);
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      head <= 0;
      tail <= 0;
      grant <= 0;
      for (int i = 0; i < PORTS; i = i + 1)
        queue[i] <= 0;
    end else begin
      if (|done) begin
        grant <= 0;
        if (!queue_empty) begin
          head <= {head[2], head[1:0] + 1'b1};
        end
      end
      
      for (int i = 0; i < PORTS; i = i + 1) begin
        if (req_valid[i] && !queue_full) begin
          queue[tail] <= i;
          tail <= next_tail;
        end
      end
      
      if (!queue_empty && grant == 0) begin
        grant <= (1 << queue[head]);
      end
    end
  end
endmodule