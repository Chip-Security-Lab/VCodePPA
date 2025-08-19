//SystemVerilog
module look_ahead_arbiter #(parameter REQS=4) (
  input wire clk, rst_n,
  input wire [REQS-1:0] req,
  input wire [REQS-1:0] predicted_req,
  output reg [REQS-1:0] grant
);
  reg [REQS-1:0] next_req;
  reg [1:0] current_priority;
  
  // Pipeline registers for critical path splitting
  reg [REQS-1:0] req_pipe;
  reg [1:0] current_priority_pipe;
  reg [REQS-1:0] grant_pipe;
  reg [REQS-1:0] next_req_pipe;
  reg [1:0] next_priority;
  
  // First pipeline stage - capture inputs and calculate next_priority
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      req_pipe <= 0;
      current_priority_pipe <= 0;
      next_req_pipe <= 0;
      next_priority <= 0;
    end else begin
      req_pipe <= req;
      current_priority_pipe <= current_priority;
      next_req_pipe <= predicted_req;
      
      // Optimized next_priority calculation using priority encoder logic
      casez (predicted_req)
        4'b???1: next_priority <= 2'd0;
        4'b??10: next_priority <= 2'd1;
        4'b?100: next_priority <= 2'd2;
        4'b1000: next_priority <= 2'd3;
        default: next_priority <= current_priority;
      endcase
    end
  end
  
  // Second pipeline stage - grant generation with optimized comparison logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grant <= 0;
      current_priority <= 0;
      next_req <= 0;
      grant_pipe <= 0;
    end else begin
      next_req <= next_req_pipe;
      current_priority <= next_priority;
      
      grant_pipe <= 0;
      
      // Optimized grant generation logic using priority selection
      if (req_pipe[current_priority_pipe]) begin
        grant_pipe[current_priority_pipe] <= 1'b1;
      end else if (|req_pipe) begin
        // Use priority encoder with masking based on priority
        casez ({req_pipe, current_priority_pipe})
          // When current_priority is 0
          {4'b???1, 2'd0}: grant_pipe <= 4'b0010; // Grant to requester 1 if available
          {4'b??10, 2'd0}: grant_pipe <= 4'b0100; // Grant to requester 2 if available
          {4'b?100, 2'd0}: grant_pipe <= 4'b1000; // Grant to requester 3 if available
          
          // When current_priority is 1
          {4'b???1, 2'd1}: grant_pipe <= 4'b0001; // Grant to requester 0 if available
          {4'b??10, 2'd1}: grant_pipe <= 4'b0100; // Grant to requester 2 if available
          {4'b?100, 2'd1}: grant_pipe <= 4'b1000; // Grant to requester 3 if available
          
          // When current_priority is 2
          {4'b???1, 2'd2}: grant_pipe <= 4'b0001; // Grant to requester 0 if available
          {4'b??10, 2'd2}: grant_pipe <= 4'b0010; // Grant to requester 1 if available
          {4'b?100, 2'd2}: grant_pipe <= 4'b1000; // Grant to requester 3 if available
          
          // When current_priority is 3
          {4'b???1, 2'd3}: grant_pipe <= 4'b0001; // Grant to requester 0 if available
          {4'b??10, 2'd3}: grant_pipe <= 4'b0010; // Grant to requester 1 if available
          {4'b?100, 2'd3}: grant_pipe <= 4'b0100; // Grant to requester 2 if available
          
          default: grant_pipe <= 4'b0000;
        endcase
      end
      
      grant <= grant_pipe;
    end
  end
endmodule