//SystemVerilog
module priority_reset(
  input clk, global_rst, subsystem_rst, local_rst,
  input [7:0] data_in,
  output reg [7:0] data_out
);
  reg global_rst_reg, subsystem_rst_reg, local_rst_reg;
  reg [7:0] data_in_reg;
  
  reg [2:0] reset_priority;
  
  always @(posedge clk) begin
    // 输入信号寄存器化部分
    global_rst_reg <= global_rst;
    subsystem_rst_reg <= subsystem_rst;
    local_rst_reg <= local_rst;
    data_in_reg <= data_in;
    
    // 生成复位优先级编码
    reset_priority <= {global_rst_reg, subsystem_rst_reg, local_rst_reg};
    
    // 使用case语句替代if-else级联
    case(reset_priority)
      3'b100, 3'b101, 3'b110, 3'b111: // 任何global_rst为1的情况
        data_out <= 8'h00;
      3'b010, 3'b011: // global_rst为0，subsystem_rst为1的情况
        data_out <= 8'h01;
      3'b001: // 只有local_rst为1的情况
        data_out <= 8'h02;
      3'b000: // 没有任何复位信号
        data_out <= data_in_reg;
    endcase
  end
endmodule