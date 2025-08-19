//SystemVerilog
`timescale 1ns / 1ps
module serializer_reset #(parameter WIDTH = 8)(
  input clk, rst_n, load,
  input [WIDTH-1:0] parallel_in,
  output serial_out
);
  // 流水线寄存器和控制信号
  reg [WIDTH-1:0] shift_reg_stage1;
  reg [WIDTH-1:0] shift_reg_stage2;
  reg [$clog2(WIDTH)-1:0] bit_counter_stage1;
  reg [$clog2(WIDTH)-1:0] bit_counter_stage2;
  reg valid_stage1, valid_stage2;
  
  // 优化的阶段1计数器逻辑
  wire [$clog2(WIDTH)-1:0] next_counter_stage1;
  
  // 使用范围比较代替单独的比较
  assign next_counter_stage1 = (bit_counter_stage1 == WIDTH-1) ? bit_counter_stage1 : bit_counter_stage1 + 1'b1;
  
  // 优化的阶段2输出索引计算
  wire [$clog2(WIDTH)-1:0] output_index_stage2;
  
  // 直接计算索引，避免补码计算
  assign output_index_stage2 = WIDTH - 1 - bit_counter_stage2;
  
  // 阶段1流水线逻辑 - 优化复位逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shift_reg_stage1 <= '0;
      bit_counter_stage1 <= '0;
      valid_stage1 <= 1'b0;
    end else if (load) begin
      shift_reg_stage1 <= parallel_in;
      bit_counter_stage1 <= '0;
      valid_stage1 <= 1'b1;
    end else begin
      bit_counter_stage1 <= next_counter_stage1;
      valid_stage1 <= 1'b1;
    end
  end
  
  // 阶段2流水线逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shift_reg_stage2 <= '0;
      bit_counter_stage2 <= '0;
      valid_stage2 <= 1'b0;
    end else begin
      shift_reg_stage2 <= shift_reg_stage1;
      bit_counter_stage2 <= bit_counter_stage1;
      valid_stage2 <= valid_stage1;
    end
  end
  
  // 串行输出 - 优化了输出逻辑
  reg serial_out_reg;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      serial_out_reg <= 1'b0;
    end else if (valid_stage2) begin
      serial_out_reg <= shift_reg_stage2[output_index_stage2];
    end
  end
  
  assign serial_out = serial_out_reg;
endmodule