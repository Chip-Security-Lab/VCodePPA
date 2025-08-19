//SystemVerilog
module nested_intr_ctrl(
  input wire clk, rst_n,
  input wire [7:0] intr_req,
  input wire [7:0] intr_mask,
  input wire [15:0] intr_priority, // 2 bits per interrupt
  input wire ack,
  output reg [2:0] intr_id,
  output reg intr_valid
);
  reg [1:0] current_level;
  reg [7:0] pending;
  
  // Optimized priority resolution signals
  reg [1:0] highest_priority;
  reg [2:0] highest_id;
  reg has_interrupt;
  
  // Interrupt priority extraction for easier processing
  wire [1:0] intr_prio [0:7];
  
  assign intr_prio[0] = intr_priority[1:0];
  assign intr_prio[1] = intr_priority[3:2];
  assign intr_prio[2] = intr_priority[5:4];
  assign intr_prio[3] = intr_priority[7:6];
  assign intr_prio[4] = intr_priority[9:8];
  assign intr_prio[5] = intr_priority[11:10];
  assign intr_prio[6] = intr_priority[13:12];
  assign intr_prio[7] = intr_priority[15:14];
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pending <= 8'h0;
      current_level <= 2'b11; 
      intr_id <= 3'b0;
      intr_valid <= 1'b0;
    end else begin
      // Update pending interrupts
      pending <= pending | (intr_req & intr_mask);
      
      // Clear acknowledged interrupt
      if (ack) begin
        pending[intr_id] <= 1'b0;
      end
      
      // Priority resolution using optimized parallel comparison
      highest_priority = 2'b11;  // Default to lowest priority
      highest_id = 3'd0;
      has_interrupt = 1'b0;
      
      for (int i = 0; i < 8; i++) begin
        if (pending[i] && intr_prio[i] < highest_priority) begin
          highest_priority = intr_prio[i];
          highest_id = i;
          has_interrupt = 1'b1;
        end
      end
      
      // Update outputs based on priority resolution
      intr_valid <= has_interrupt;
      if (has_interrupt) begin
        intr_id <= highest_id;
        current_level <= highest_priority;
      end
    end
  end
endmodule