//SystemVerilog
module can_bit_destuffer(
  input wire clk, rst_n,
  input wire data_in, data_valid,
  input wire destuffing_active,
  output reg data_out,
  output reg data_out_valid,
  output reg stuff_error
);
  // 主计数器状态
  reg [2:0] same_bit_count;
  reg last_bit;
  
  // 优化1: 拆分检测逻辑，减少关键路径深度
  reg is_stuff_bit;
  reg is_error_condition;
  reg update_needed;
  reg [2:0] next_count;
  
  // 优化2: 预计算条件判断，减少组合逻辑层级
  always @(*) begin
    is_stuff_bit = (same_bit_count == 3'd4);
    is_error_condition = is_stuff_bit && (data_in == last_bit);
    update_needed = data_valid && destuffing_active;
    
    // 将条件运算符转换为if-else结构
    if (data_in == last_bit) begin
      next_count = same_bit_count + 1'b1;
    end else begin
      next_count = 3'b000;
    end
  end
  
  // 主状态跟踪逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      same_bit_count <= 3'b000;
      last_bit <= 1'b0;
      data_out <= 1'b1;
      data_out_valid <= 1'b0;
      stuff_error <= 1'b0;
    end else begin
      data_out_valid <= 1'b0;
      
      if (update_needed) begin
        if (is_error_condition) begin
          stuff_error <= 1'b1;  // Six consecutive identical bits is an error
        end else if (is_stuff_bit) begin
          // This is a stuff bit, don't forward it
          same_bit_count <= 3'b000;
          last_bit <= data_in;
        end else begin
          data_out <= data_in;
          data_out_valid <= 1'b1;
          same_bit_count <= next_count;
          last_bit <= data_in;
        end
      end
    end
  end
endmodule