//SystemVerilog
module can_arbitration(
  input wire clk, rst_n,
  input wire can_rx,
  input wire [10:0] tx_id,
  input wire tx_start,
  output reg can_tx,
  output reg arbitration_lost
);
  
  // 优化状态编码，使用独热码减少译码逻辑
  localparam [2:0] IDLE = 3'b001;
  localparam [2:0] ARBITRATION = 3'b010;
  localparam [2:0] COMPLETE = 3'b100;
  
  reg [2:0] state, next_state;
  reg [10:0] shift_id;
  reg [3:0] bit_count;
  
  // 优化冲突检测逻辑
  wire dominant_conflict;
  wire arbitration_done;
  
  // 使用更高效的比较结构
  assign dominant_conflict = (~can_rx) & shift_id[10];
  assign arbitration_done = (bit_count == 4'd10);
  
  // 状态转换逻辑 - 使用非阻塞赋值提高时序性能
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state <= IDLE;
    else
      state <= next_state;
  end
  
  // 状态机下一状态逻辑 - 优化了条件判断的结构
  always @(*) begin
    // 默认保持当前状态
    next_state = state;
    
    case (state)
      IDLE:
        if (tx_start)
          next_state = ARBITRATION;
          
      ARBITRATION: 
        if (dominant_conflict)
          next_state = IDLE;
        else if (arbitration_done)
          next_state = COMPLETE;
          
      COMPLETE:
        next_state = IDLE;
        
      default:
        next_state = IDLE;
    endcase
  end
  
  // 数据通路更新逻辑 - 优化了寄存器更新逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      arbitration_lost <= 1'b0;
      can_tx <= 1'b1;
      bit_count <= 4'b0;
      shift_id <= 11'b0;
    end else begin
      // 默认不更新，减少不必要的切换
      case (state)
        IDLE: begin
          arbitration_lost <= 1'b0;
          can_tx <= 1'b1;
          bit_count <= 4'b0;
          
          // 只在需要时更新shift_id
          if (tx_start)
            shift_id <= tx_id;
        end
        
        ARBITRATION: begin
          // 更新发送位
          can_tx <= shift_id[10];
          
          // 在比较操作之后进行位移，避免潜在的竞争
          if (!dominant_conflict) begin
            shift_id <= {shift_id[9:0], 1'b0};
            bit_count <= bit_count + 4'b1;
          end else begin
            arbitration_lost <= 1'b1;
          end
        end
        
        // 其它状态保持输出不变
      endcase
    end
  end
  
endmodule