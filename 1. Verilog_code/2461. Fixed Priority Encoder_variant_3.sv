//SystemVerilog
//IEEE 1364-2005 SystemVerilog
module fixed_priority_intr_ctrl(
  input wire clk, rst_n,
  input wire [7:0] intr_src,
  output reg [2:0] intr_id,
  output reg intr_valid
);
  
  // 内部信号定义
  reg [7:0] highest_priority;
  
  // 组合逻辑部分：检测是否有中断请求
  always @(*) begin
    intr_valid = |intr_src;
  end
  
  // 组合逻辑部分：优先编码器 - 提取最高优先级中断
  always @(*) begin
    casez (intr_src)
      8'b1???????: highest_priority = 8'b1000_0000;
      8'b01??????: highest_priority = 8'b0100_0000;
      8'b001?????: highest_priority = 8'b0010_0000;
      8'b0001????: highest_priority = 8'b0001_0000;
      8'b00001???: highest_priority = 8'b0000_1000;
      8'b000001??: highest_priority = 8'b0000_0100;
      8'b0000001?: highest_priority = 8'b0000_0010;
      8'b00000001: highest_priority = 8'b0000_0001;
      default:     highest_priority = 8'b0000_0000;
    endcase
  end
  
  // 时序逻辑部分：根据最高优先级确定中断ID
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id <= 3'b0;
    end else begin
      case (highest_priority)
        8'b1000_0000: intr_id <= 3'd7;
        8'b0100_0000: intr_id <= 3'd6;
        8'b0010_0000: intr_id <= 3'd5;
        8'b0001_0000: intr_id <= 3'd4;
        8'b0000_1000: intr_id <= 3'd3;
        8'b0000_0100: intr_id <= 3'd2;
        8'b0000_0010: intr_id <= 3'd1;
        8'b0000_0001: intr_id <= 3'd0;
        default:      intr_id <= intr_id; // 保持原值
      endcase
    end
  end
  
  // 时序逻辑部分：中断有效信号寄存
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_valid <= 1'b0;
    end else begin
      intr_valid <= |intr_src;
    end
  end
  
endmodule