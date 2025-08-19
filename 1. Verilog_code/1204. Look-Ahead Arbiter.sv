module look_ahead_arbiter #(parameter REQS=4) (
  input wire clk, rst_n,
  input wire [REQS-1:0] req,
  input wire [REQS-1:0] predicted_req,
  output reg [REQS-1:0] grant
);
  reg [REQS-1:0] next_req;
  reg [1:0] current_priority;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grant <= 0;
      current_priority <= 0;
      next_req <= 0;
    end else begin
      next_req <= predicted_req;
      grant <= 0;
      
      if (req[current_priority]) grant[current_priority] <= 1'b1;
      else if (|req) begin
        if (req[0] && current_priority != 0) grant[0] <= 1'b1;
        else if (req[1] && current_priority != 1) grant[1] <= 1'b1;
        else if (req[2] && current_priority != 2) grant[2] <= 1'b1;
        else if (req[3] && current_priority != 3) grant[3] <= 1'b1;
      end
      
      // Look ahead for next priority
      if (|next_req) begin
        if (next_req[0]) current_priority <= 0;
        else if (next_req[1]) current_priority <= 1;
        else if (next_req[2]) current_priority <= 2;
        else current_priority <= 3;
      end
    end
  end
endmodule