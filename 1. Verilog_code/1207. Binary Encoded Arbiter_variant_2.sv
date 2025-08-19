//SystemVerilog
module binary_encoded_arbiter #(
  parameter WIDTH = 4
) (
  input                         clk,
  input                         reset_n,
  input      [WIDTH-1:0]        req_i,
  output     [$clog2(WIDTH)-1:0] sel_o,
  output                        valid_o
);
  
  // 注册输入请求以减少输入端到第一级寄存器的延迟
  reg [WIDTH-1:0] req_reg;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      req_reg <= {WIDTH{1'b0}};
    end else begin
      req_reg <= req_i;
    end
  end
  
  // 内部连线
  wire                     req_valid;
  wire [$clog2(WIDTH)-1:0] priority_index;
  
  // 请求有效性检测模块
  request_validator #(
    .WIDTH(WIDTH)
  ) u_request_validator (
    .req_i      (req_reg),
    .req_valid_o(req_valid)
  );
  
  // 优先级选择器模块
  priority_encoder #(
    .WIDTH(WIDTH)
  ) u_priority_encoder (
    .req_i     (req_reg),
    .index_o   (priority_index)
  );
  
  // 组合逻辑后的输出寄存器控制模块
  output_register #(
    .WIDTH(WIDTH)
  ) u_output_register (
    .clk          (clk),
    .reset_n      (reset_n),
    .req_valid_i  (req_valid),
    .priority_idx_i(priority_index),
    .sel_o        (sel_o),
    .valid_o      (valid_o)
  );
  
endmodule

// 请求有效性检测模块 - 纯组合逻辑
module request_validator #(
  parameter WIDTH = 4
) (
  input  [WIDTH-1:0] req_i,
  output             req_valid_o
);
  
  // 只要有任何一个请求有效，输出就为高
  assign req_valid_o = |req_i;
  
endmodule

// 优先级编码器模块 - 优化组合逻辑
module priority_encoder #(
  parameter WIDTH = 4
) (
  input  [WIDTH-1:0]        req_i,
  output [$clog2(WIDTH)-1:0] index_o
);
  
  reg [$clog2(WIDTH)-1:0] priority_index;
  
  integer i;
  
  always @(*) begin
    priority_index = {$clog2(WIDTH){1'b0}};
    
    for (i = WIDTH-1; i >= 0; i = i - 1) begin
      if (req_i[i]) begin
        priority_index = i[$clog2(WIDTH)-1:0];
      end
    end
  end
  
  assign index_o = priority_index;
  
endmodule

// 输出寄存器控制模块
module output_register #(
  parameter WIDTH = 4
) (
  input                         clk,
  input                         reset_n,
  input                         req_valid_i,
  input      [$clog2(WIDTH)-1:0] priority_idx_i,
  output reg [$clog2(WIDTH)-1:0] sel_o,
  output reg                    valid_o
);
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      sel_o <= {$clog2(WIDTH){1'b0}};
      valid_o <= 1'b0;
    end else begin
      sel_o <= priority_idx_i;
      valid_o <= req_valid_i;
    end
  end
  
endmodule