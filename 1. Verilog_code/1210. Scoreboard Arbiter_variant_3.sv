//SystemVerilog
module scoreboard_arbiter(
  input wire clk, reset,
  input wire [3:0] requests,
  output reg [3:0] grants
);
  reg [7:0] scores [3:0];
  reg [1:0] highest_idx;
  
  integer i;
  
  always @(posedge clk) begin
    if (reset) begin
      for (i = 0; i < 4; i = i + 1) scores[i] <= 8'h80;
      grants <= 4'h0;
      highest_idx <= 2'b00;
    end else begin
      // Update scores based on activity - flattened if-else structure
      for (i = 0; i < 4; i = i + 1) begin
        if (requests[i] && scores[i] < 8'hFF) 
          scores[i] <= scores[i] + 1;
        else if (!requests[i] && scores[i] > 0) 
          scores[i] <= scores[i] - 1;
      end
      
      // Find highest scoring requester
      highest_idx <= 0;
      for (i = 1; i < 4; i = i + 1) begin
        if (requests[i] && scores[i] > scores[highest_idx]) 
          highest_idx <= i[1:0];
      end
      
      // Generate grant - flattened if-else structure
      grants <= 4'h0;
      if (|requests) begin
        grants[highest_idx] <= 1'b1;
        scores[highest_idx] <= scores[highest_idx] >> 1;
      end
    end
  end
endmodule