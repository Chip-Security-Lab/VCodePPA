//SystemVerilog
module reset_stability_monitor (
  input  wire clk,
  input  wire reset_n,
  output reg  reset_unstable
);
  reg reset_prev;
  reg reset_n_reg;
  reg [3:0] glitch_counter;
  
  // 状态定义
  localparam TRANSITION    = 2'b00;
  localparam COUNTING      = 2'b01;
  localparam THRESHOLD_MET = 2'b10;
  localparam STABLE        = 2'b11;
  
  // First register the input to reduce input-to-register delay
  always @(posedge clk) begin
    reset_n_reg <= reset_n;
  end

  // Now detect transitions on the registered input using case statement
  always @(posedge clk) begin
    reset_prev <= reset_n_reg;
    
    // 确定当前状态
    case ({(reset_n_reg != reset_prev), 
           (glitch_counter > 4'd0 && glitch_counter <= 4'd5),
           (glitch_counter > 4'd5)})
      
      // 检测到转换
      3'b100, 3'b101, 3'b110, 3'b111: begin
        glitch_counter <= glitch_counter + 1'b1;
      end
      
      // 没有转换，但计数器已开始计数且未超过阈值
      3'b010: begin
        // 保持当前计数器值
        glitch_counter <= glitch_counter;
      end
      
      // 没有转换，计数器已超过阈值
      3'b001: begin
        // 保持计数器在最大值
        glitch_counter <= glitch_counter;
      end
      
      // 稳定状态，无转换
      3'b000: begin
        // 复位计数器
        glitch_counter <= 4'd0;
      end
      
      default: begin
        // 安全状态
        glitch_counter <= glitch_counter;
      end
    endcase
  end

  // Output logic with case statement
  always @(posedge clk) begin
    case (glitch_counter > 4'd5)
      1'b1: reset_unstable <= 1'b1;
      1'b0: reset_unstable <= 1'b0;
    endcase
  end
endmodule