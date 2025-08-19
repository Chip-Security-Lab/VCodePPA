//SystemVerilog
module nested_intr_ctrl(
  input clk, rst_n,
  input [7:0] intr_req,
  input [7:0] intr_mask,
  input [15:0] intr_priority, // 2 bits per interrupt
  input ack,
  output reg [2:0] intr_id,
  output reg intr_valid
);
  reg [1:0] current_level;
  reg [7:0] pending;
  reg [7:0] masked_pending;
  
  // Priority encoding combinational logic
  function [2:0] find_highest_priority;
    input [7:0] masked_pending;
    input [15:0] intr_priority;
    input [1:0] current_level;
    reg [2:0] highest_id;
    reg [1:0] highest_priority;
    integer i;
    begin
      highest_id = 3'd0;
      highest_priority = 2'b11; // Lowest priority
      
      for (i = 0; i < 8; i = i + 1) begin
        if (masked_pending[i] && (intr_priority[i*2+:2] < highest_priority)) begin
          highest_id = i[2:0];
          highest_priority = intr_priority[i*2+:2];
        end
      end
      
      find_highest_priority = highest_id;
    end
  endfunction
  
  // Main control logic - single coherent always block
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pending <= 8'h0;
      current_level <= 2'b11; // Lowest priority
      intr_id <= 3'b0;
      intr_valid <= 1'b0;
      masked_pending <= 8'h0;
    end else begin
      // Update pending interrupts
      if (ack)
        pending[intr_id] <= 1'b0;
      else
        pending <= pending | (intr_req & intr_mask);
      
      // Calculate masked pending based on current priority level
      masked_pending <= 8'h0;
      for (integer i = 0; i < 8; i = i + 1) begin
        masked_pending[i] <= pending[i] && (intr_priority[i*2+:2] < current_level);
      end
      
      // Default values
      intr_valid <= 1'b0;
      current_level <= 2'b11; // Lowest priority
      
      // Find the highest priority pending interrupt
      if (|masked_pending) begin
        intr_id <= find_highest_priority(masked_pending, intr_priority, current_level);
        current_level <= intr_priority[intr_id*2+:2];
        intr_valid <= 1'b1;
      end
    end
  end
endmodule