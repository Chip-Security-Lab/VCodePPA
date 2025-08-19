//SystemVerilog
module broadcast_arbiter(
  input wire clk, rst_n,
  input wire [3:0] req,
  input wire broadcast,
  output reg [3:0] grant
);
  reg [3:0] priority_queue_stage1;
  reg [3:0] priority_queue_stage2;
  reg [3:0] priority_queue_stage3;
  reg [3:0] req_stage1;
  reg [3:0] req_stage2;
  reg broadcast_stage1;
  reg broadcast_stage2;
  reg [3:0] grant_stage1;
  reg [3:0] grant_stage2;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      priority_queue_stage1 <= 4'b0001;
      priority_queue_stage2 <= 4'b0001;
      priority_queue_stage3 <= 4'b0001;
      req_stage1 <= 4'b0000;
      req_stage2 <= 4'b0000;
      broadcast_stage1 <= 1'b0;
      broadcast_stage2 <= 1'b0;
      grant_stage1 <= 4'b0000;
      grant_stage2 <= 4'b0000;
      grant <= 4'b0000;
    end else begin
      // Stage 1: Input sampling and priority rotation
      req_stage1 <= req;
      broadcast_stage1 <= broadcast;
      priority_queue_stage1 <= {priority_queue_stage3[2:0], priority_queue_stage3[3]};
      
      // Stage 2: Priority queue update and request processing
      req_stage2 <= req_stage1;
      broadcast_stage2 <= broadcast_stage1;
      priority_queue_stage2 <= priority_queue_stage1;
      
      // Stage 3: Grant calculation
      priority_queue_stage3 <= priority_queue_stage2;
      if (broadcast_stage2) begin
        grant_stage1 <= req_stage2;
      end else begin
        grant_stage1 <= req_stage2 & priority_queue_stage2;
      end
      
      // Stage 4: Grant output
      grant_stage2 <= grant_stage1;
      grant <= grant_stage2;
    end
  end
endmodule