//SystemVerilog
module frame_assembler #(
    parameter DATA_W = 8,
    parameter HEADER = 8'hAA
)(
    input                   clk,
    input                   rst,
    input                   en,
    input  [DATA_W-1:0]     payload,
    output [DATA_W-1:0]     frame_out,
    output                  frame_valid
);

    // 状态定义
    localparam STATE_IDLE    = 2'b00;
    localparam STATE_HEADER  = 2'b01;
    localparam STATE_PAYLOAD = 2'b10;

    // 状态寄存器
    reg [1:0]           state_r;
    reg [1:0]           next_state;
    
    // 数据流水线寄存器
    reg [DATA_W-1:0]    payload_r;
    reg [DATA_W-1:0]    frame_data_r;
    reg                 frame_valid_r;
    
    // 输出赋值
    assign frame_out = frame_data_r;
    assign frame_valid = frame_valid_r;
    
    // 状态转移逻辑 - 将状态逻辑与数据路径分开
    always @(*) begin
        next_state = state_r;
        
        case (state_r)
            STATE_IDLE: 
                if (en) next_state = STATE_HEADER;
            
            STATE_HEADER: 
                next_state = STATE_PAYLOAD;
            
            STATE_PAYLOAD: 
                next_state = STATE_IDLE;
                
            default: 
                next_state = STATE_IDLE;
        endcase
    end
    
    // 状态寄存器更新
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_r <= STATE_IDLE;
        end else begin
            state_r <= next_state;
        end
    end
    
    // 数据路径 - 分离的payload寄存
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            payload_r <= {DATA_W{1'b0}};
        end else if (state_r == STATE_IDLE && en) begin
            payload_r <= payload;
        end
    end
    
    // 输出数据路径 - 帧数据生成
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_data_r <= {DATA_W{1'b0}};
        end else begin
            case (state_r)
                STATE_IDLE:
                    if (en) frame_data_r <= HEADER;
                
                STATE_HEADER:
                    frame_data_r <= payload_r;
                    
                default: 
                    frame_data_r <= frame_data_r;
            endcase
        end
    end
    
    // 有效信号控制 - 单独的控制路径
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_valid_r <= 1'b0;
        end else begin
            case (next_state)
                STATE_HEADER: 
                    frame_valid_r <= 1'b1;
                    
                STATE_PAYLOAD:
                    frame_valid_r <= 1'b1;
                    
                default:
                    frame_valid_r <= 1'b0;
            endcase
        end
    end

endmodule