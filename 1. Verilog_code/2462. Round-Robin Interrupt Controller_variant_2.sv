//SystemVerilog
module round_robin_intr_ctrl #(parameter WIDTH=4)(
  input wire clock, reset,
  input wire [WIDTH-1:0] req,
  output reg [WIDTH-1:0] grant,
  output reg active
);
  reg [WIDTH-1:0] pointer;
  reg [WIDTH-1:0] masked_req;
  reg [WIDTH-1:0] unmasked_req;
  reg use_masked;
  
  // 查找表辅助减法器实现
  reg [7:0] lut_diff [0:15][0:15]; // 8位查找表
  reg [7:0] a_val, b_val, diff_val;
  integer i, j;
  
  // 初始化查找表
  initial begin
    for (i = 0; i < 16; i = i + 1) begin
      for (j = 0; j < 16; j = j + 1) begin
        lut_diff[i][j] = i - j;
      end
    end
  end
  
  // 减法器辅助函数
  function [WIDTH-1:0] lut_subtract;
    input [WIDTH-1:0] a;
    input [WIDTH-1:0] b;
    reg [WIDTH-1:0] result;
    integer k;
    begin
      for (k = 0; k < WIDTH; k = k + 1) begin
        if (k == 0) begin
          result[k] = a[k] ^ b[k] ^ 1'b0;
        end else begin
          if (a[k-1] < b[k-1] || (a[k-1] == b[k-1] && result[k-1] == 1'b1)) begin
            result[k] = a[k] ^ b[k] ^ 1'b1;
          end else begin
            result[k] = a[k] ^ b[k] ^ 1'b0;
          end
        end
      end
      lut_subtract = result;
    end
  endfunction
  
  always @(*) begin
    // 使用查找表辅助减法器计算req - pointer
    masked_req = req & ~(lut_subtract(req, pointer) | pointer);
    
    // 第二阶段中断掩码 - 当第一阶段为空时使用的掩码
    unmasked_req = req & (lut_subtract(req, pointer) | pointer);
    
    // 决定使用哪个掩码结果
    use_masked = |masked_req;
  end
  
  always @(posedge clock) begin
    if (reset) begin
      pointer <= {{(WIDTH-1){1'b0}}, 1'b1};
      grant <= {WIDTH{1'b0}};
      active <= 1'b0;
    end
    else begin
      if (|req) begin
        // 根据掩码结果选择授权信号
        if (use_masked) begin
          grant <= masked_req;
        end
        else begin
          grant <= unmasked_req;
        end
        
        // 更新下一个优先级指针
        pointer <= {grant[WIDTH-2:0], grant[WIDTH-1]};
        active <= 1'b1;
      end
      else begin
        grant <= {WIDTH{1'b0}};
        active <= 1'b0;
      end
    end
  end
endmodule