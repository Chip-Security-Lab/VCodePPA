//SystemVerilog
module booth_multiplier(
  input clk, rst,
  input [3:0] request,
  output reg [3:0] grant
);

  reg [3:0] multiplicand;
  reg [3:0] multiplier;
  reg [3:0] booth_result;
  reg [3:0] booth_stage1;
  reg [3:0] request_stage1;
  reg [3:0] request_stage2;

  // Combined Stage 1 & 2: Request capture and Booth multiplication
  always @(posedge clk) begin
    if (rst) begin
      request_stage1 <= 4'b0000;
      multiplicand <= 4'b0000;
      multiplier <= 4'b0000;
      booth_stage1 <= 4'b0000;
    end else begin
      request_stage1 <= request;
      multiplicand <= request;
      multiplier <= 4'b0001;
      booth_stage1 <= booth_multiply(request, 4'b0001);
    end
  end

  // Stage 3: Grant output
  always @(posedge clk) begin
    if (rst) begin
      grant <= 4'b0000;
    end else begin
      grant <= booth_stage1;
    end
  end

  function [3:0] booth_multiply;
    input [3:0] a;
    input [3:0] b;
    reg [7:0] acc;
    reg [3:0] q;
    reg q_1;
    integer i;
    begin
      acc = 8'b0;
      q = b;
      q_1 = 1'b0;
      
      for (i = 0; i < 4; i = i + 1) begin
        case ({q[0], q_1})
          2'b01: acc = acc + {4'b0, a};
          2'b10: acc = acc - {4'b0, a};
          default: acc = acc;
        endcase
        
        q_1 = q[0];
        q = q >> 1;
        q[3] = acc[0];
        acc = acc >> 1;
      end
      
      booth_multiply = acc[3:0];
    end
  endfunction

endmodule