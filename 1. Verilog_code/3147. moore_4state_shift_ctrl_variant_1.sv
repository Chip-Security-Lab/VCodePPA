//SystemVerilog
module moore_4state_shift_ctrl #(
  parameter COUNT_WIDTH = 4
)(
  input  wire                    clk,
  input  wire                    rst,
  input  wire                    start,
  input  wire [COUNT_WIDTH-1:0]  shift_count,
  output wire                    shift_en,
  output wire                    done
);
  
  // 状态定义
  localparam [1:0] STATE_WAIT  = 2'b00,
                   STATE_LOAD  = 2'b01,
                   STATE_SHIFT = 2'b10,
                   STATE_DONE  = 2'b11;
                   
  // 状态寄存器和计数器
  reg [1:0]             curr_state;
  reg [1:0]             next_state;
  reg [COUNT_WIDTH-1:0] counter_r;
  reg [COUNT_WIDTH-1:0] next_counter;
  
  // 输出信号寄存器
  reg shift_en_r;
  reg done_r;
  
  // 流水线化状态转换逻辑
  always @* begin
    next_state = curr_state;
    next_counter = counter_r;
    
    case (curr_state)
      STATE_WAIT: begin
        if (start) begin
          next_state = STATE_LOAD;
        end
      end
      
      STATE_LOAD: begin
        next_counter = shift_count;
        next_state = STATE_SHIFT;
      end
      
      STATE_SHIFT: begin
        if (counter_r == 0) begin
          next_state = STATE_DONE;
        end else begin
          next_counter = counter_r - 1'b1;
        end
      end
      
      STATE_DONE: begin
        next_state = STATE_WAIT;
      end
    endcase
  end
  
  // 寄存器更新逻辑
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      curr_state <= STATE_WAIT;
      counter_r <= {COUNT_WIDTH{1'b0}};
    end else begin
      curr_state <= next_state;
      counter_r <= next_counter;
    end
  end
  
  // 输出逻辑 - 分离成单独的流程以改善时序
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      shift_en_r <= 1'b0;
      done_r <= 1'b0;
    end else begin
      shift_en_r <= (next_state == STATE_SHIFT);
      done_r <= (next_state == STATE_DONE);
    end
  end
  
  // 将寄存器化的输出暴露为模块输出
  assign shift_en = shift_en_r;
  assign done = done_r;
  
endmodule