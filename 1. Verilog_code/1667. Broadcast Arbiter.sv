module broadcast_arbiter(
  input wire clk, rst_n,
  input wire [3:0] req,
  input wire broadcast,
  output reg [3:0] grant
);
  reg [3:0] priority_queue;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      priority_queue <= 4'b0001;
      grant <= 4'b0000;
    end else begin
      if (broadcast) grant <= req; // Grant all requests
      else begin
        grant <= req & priority_queue; // Grant highest priority
        // Rotate priority for next cycle
        priority_queue <= {priority_queue[2:0], priority_queue[3]};
      end
    end
  end
endmodule