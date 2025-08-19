//SystemVerilog
module round_robin_intr_ctrl #(parameter WIDTH=4)(
  input wire clock, reset,
  input wire [WIDTH-1:0] req,
  output reg [WIDTH-1:0] grant,
  output reg active
);
  reg [WIDTH-1:0] pointer;
  wire [2*WIDTH-1:0] double_req, double_grant;
  
  assign double_req = {req, req};
  assign double_grant = double_req & ~((double_req - {{(WIDTH){1'b0}}, pointer}) | {{(WIDTH){1'b0}}, pointer});
  
  // 使用格雷码编码状态
  // IDLE    = 3'b000 -> 3'b000
  // GRANT   = 3'b001 -> 3'b001
  // WAIT    = 3'b010 -> 3'b011
  // INVALID = 3'b011 -> 3'b010
  // DEFAULT = 3'b1xx -> 3'b1xx (未使用)
  
  localparam [2:0] IDLE = 3'b000,
                  GRANT = 3'b001,
                  WAIT = 3'b011,
                  INVALID = 3'b010;
  
  reg [2:0] current_state, next_state;
  
  // 状态转换逻辑
  always @(*) begin
    if (reset)
      next_state = IDLE;
    else begin
      case (current_state)
        IDLE: next_state = |req ? GRANT : IDLE;
        GRANT: next_state = WAIT;
        WAIT: next_state = |req ? GRANT : IDLE;
        INVALID: next_state = IDLE;
        default: next_state = IDLE;
      endcase
    end
  end
  
  // 状态寄存器
  always @(posedge clock) begin
    if (reset)
      current_state <= IDLE;
    else
      current_state <= next_state;
  end
  
  // 输出逻辑
  always @(posedge clock) begin
    if (reset) begin
      pointer <= {{(WIDTH-1){1'b0}}, 1'b1};
      grant <= {WIDTH{1'b0}};
      active <= 1'b0;
    end
    else begin
      case (current_state)
        IDLE: begin
          active <= 1'b0;
        end
        
        GRANT: begin
          grant <= double_grant[WIDTH-1:0] | double_grant[2*WIDTH-1:WIDTH];
          pointer <= {grant[WIDTH-2:0], grant[WIDTH-1]};
          active <= 1'b1;
        end
        
        WAIT: begin
          active <= 1'b0;
        end
        
        default: begin
          // 保持输出不变
          active <= active;
          grant <= grant;
          pointer <= pointer;
        end
      endcase
    end
  end
endmodule