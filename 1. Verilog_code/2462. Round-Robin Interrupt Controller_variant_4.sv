//SystemVerilog
module round_robin_intr_ctrl #(parameter WIDTH=4)(
  input wire clock, reset,
  input wire [WIDTH-1:0] req,
  output reg [WIDTH-1:0] grant,
  output reg active
);
  reg [WIDTH-1:0] pointer;
  wire [2*WIDTH-1:0] double_req;
  wire [2*WIDTH-1:0] shifted_mask;
  wire [2*WIDTH-1:0] double_grant;
  wire any_req;
  
  // 预计算请求存在信号，减少后续组合路径
  assign any_req = |req;
  
  // 复制请求向量以简化轮循逻辑
  assign double_req = {req, req};
  
  // 使用移位掩码生成优先级掩码，避免减法操作的延迟
  assign shifted_mask = {{(WIDTH){1'b1}}, {(WIDTH){1'b0}}} << pointer;
  
  // 将组合逻辑分解为更平衡的多个步骤
  assign double_grant = double_req & ~shifted_mask;
  
  always @(posedge clock) begin
    case ({reset, any_req})
      2'b10, 2'b11: begin
        // 重置初始指针和状态 (优先级最高)
        pointer <= {{(WIDTH-1){1'b0}}, 1'b1};
        grant <= {WIDTH{1'b0}};
        active <= 1'b0;
      end
      
      2'b01: begin
        // 有请求且非复位状态
        // 合并双倍宽度的授权信号到标准输出宽度
        grant <= double_grant[WIDTH-1:0] | double_grant[2*WIDTH-1:WIDTH];
        // 轮循指针更新，使用简单的循环移位操作
        pointer <= {grant[WIDTH-2:0], grant[WIDTH-1]};
        active <= 1'b1;
      end
      
      2'b00: begin
        // 无请求且非复位状态
        active <= 1'b0;
        // 保持其他信号不变
        grant <= grant;
        pointer <= pointer;
      end
      
      default: begin
        // 默认情况下保持信号不变
        grant <= grant;
        pointer <= pointer;
        active <= active;
      end
    endcase
  end
endmodule