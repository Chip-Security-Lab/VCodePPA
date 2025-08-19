module pipelined_arbiter #(parameter WIDTH=4) (
  input clk, rst,
  input [WIDTH-1:0] req_in,
  output reg [WIDTH-1:0] grant_out
);
  reg [WIDTH-1:0] req_stage1, req_stage2;
  reg [WIDTH-1:0] grant_stage1, grant_stage2;
  
  always @(posedge clk) begin
    if (rst) begin
      req_stage1 <= 0; req_stage2 <= 0;
      grant_stage1 <= 0; grant_stage2 <= 0;
      grant_out <= 0;
    end else begin
      // Pipeline Stage 1
      req_stage1 <= req_in;
      if (|req_stage1) begin
        grant_stage1 <= 0;
        if (req_stage1[0]) grant_stage1[0] <= 1'b1;
        else if (req_stage1[1]) grant_stage1[1] <= 1'b1;
        else if (req_stage1[2]) grant_stage1[2] <= 1'b1;
        else if (req_stage1[3]) grant_stage1[3] <= 1'b1;
      end else grant_stage1 <= 0;
      
      // Pipeline Stage 2
      req_stage2 <= req_stage1;
      grant_stage2 <= grant_stage1;
      
      // Output Stage
      grant_out <= grant_stage2;
    end
  end
endmodule