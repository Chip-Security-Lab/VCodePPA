//SystemVerilog
module fcfs_arbiter #(parameter PORTS = 4) (
  input wire clk, rst_n,
  input wire [PORTS-1:0] req,
  input wire [PORTS-1:0] done,
  output reg [PORTS-1:0] grant
);

  reg [PORTS-1:0] queue [0:PORTS-1];
  reg [$clog2(PORTS)-1:0] head, tail;
  reg [PORTS-1:0] next_grant;
  reg [PORTS-1:0] req_mask;
  reg queue_empty;
  
  // Optimize queue management
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      head <= 0;
      tail <= 0;
      grant <= 0;
      next_grant <= 0;
      req_mask <= 0;
      queue_empty <= 1;
    end else begin
      // Handle request enqueuing
      if (|req && !queue_empty) begin
        for (int i = 0; i < PORTS; i++) begin
          if (req[i] && !req_mask[i]) begin
            queue[tail] <= i;
            tail <= (tail + 1) % PORTS;
            req_mask[i] <= 1'b1;
          end
        end
        queue_empty <= 0;
      end
      
      // Handle grant and dequeue
      if (|done) begin
        grant <= 0;
        next_grant <= 0;
        req_mask[queue[head]] <= 0;
        head <= (head + 1) % PORTS;
        queue_empty <= (head == tail);
      end else if (!queue_empty && grant == 0) begin
        grant <= (1 << queue[head]);
        next_grant <= (1 << queue[head]);
      end else begin
        grant <= next_grant;
      end
    end
  end

endmodule