//SystemVerilog
module broadcast_arbiter(
  input wire clk,
  input wire rst_n,
  input wire [3:0] req,
  input wire broadcast,
  output reg [3:0] grant
);

  // Internal registers
  reg [3:0] priority_queue;
  reg [3:0] grant_next;
  reg [3:0] priority_queue_next;

  // Priority rotation logic
  always @(*) begin
    priority_queue_next = {priority_queue[2:0], priority_queue[3]};
  end

  // Grant generation logic
  always @(*) begin
    if (broadcast) begin
      grant_next = req;
    end else begin
      grant_next = req & priority_queue;
    end
  end

  // Sequential logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      priority_queue <= 4'b0001;
      grant <= 4'b0000;
    end else begin
      priority_queue <= priority_queue_next;
      grant <= grant_next;
    end
  end

endmodule