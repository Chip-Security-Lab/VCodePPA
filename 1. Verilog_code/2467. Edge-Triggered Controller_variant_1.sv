//SystemVerilog
module edge_triggered_intr_ctrl(
  input clk, rst_n,
  input [7:0] intr_in,
  output reg [2:0] intr_num,
  output reg intr_pending
);
  reg [7:0] intr_prev;
  wire [7:0] intr_edge;
  reg [7:0] intr_flag;
  
  // Buffered signals for high fanout paths
  reg [7:0] intr_flag_buf1, intr_flag_buf2;
  
  // Edge detection logic
  assign intr_edge = intr_in & ~intr_prev;
  
  // Priority encoder logic with optimized structure
  function [2:0] priority_encode;
    input [7:0] flag_bits;
    begin
      casez(flag_bits)
        8'b????_???1: priority_encode = 3'd0;
        8'b????_??10: priority_encode = 3'd1;
        8'b????_?100: priority_encode = 3'd2;
        8'b????_1000: priority_encode = 3'd3;
        8'b???1_0000: priority_encode = 3'd4;
        8'b??10_0000: priority_encode = 3'd5;
        8'b?100_0000: priority_encode = 3'd6;
        8'b1000_0000: priority_encode = 3'd7;
        default:      priority_encode = 3'd0;
      endcase
    end
  endfunction
  
  // Buffer register for intr_flag high fanout signal
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_flag_buf1 <= 8'h0;
      intr_flag_buf2 <= 8'h0;
    end else begin
      intr_flag_buf1 <= intr_flag;
      intr_flag_buf2 <= intr_flag;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_prev <= 8'h0;
      intr_flag <= 8'h0;
      intr_num <= 3'h0;
      intr_pending <= 1'b0;
    end else begin
      intr_prev <= intr_in;
      
      // Update interrupt flags with edge detection
      intr_flag <= (intr_flag | intr_edge);
      
      // Use buffered flag signal for pending detection
      intr_pending <= |intr_flag_buf1;
      
      // Only update interrupt number when there are pending interrupts
      // Use second buffer for priority encoder to split load
      if (|intr_flag_buf2) begin
        intr_num <= priority_encode(intr_flag_buf2);
      end
    end
  end
endmodule