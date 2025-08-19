//SystemVerilog
// 顶层模块
module usb_transaction_ctrl(
    input wire Clock,
    input wire Reset_n,
    input wire SOF_Received,
    input wire TOKEN_Received,
    input wire DATA_Received,
    input wire ACK_Received, 
    input wire NAK_Received,
    output reg SendACK,
    output reg SendNAK,
    output reg SendDATA,
    output wire [1:0] CurrentState
);
    // 状态定义
    localparam IDLE=2'b00, TOKEN=2'b01, DATA=2'b10, STATUS=2'b11;
    
    // 内部信号
    wire [1:0] next_state;
    reg [1:0] current_state;
    
    // 将当前状态输出到外部
    assign CurrentState = current_state;
    
    // 实例化状态转换模块
    usb_state_transition state_transition_inst (
        .current_state(current_state),
        .SOF_Received(SOF_Received),
        .TOKEN_Received(TOKEN_Received),
        .DATA_Received(DATA_Received),
        .next_state(next_state)
    );
    
    // 状态寄存器模块
    always @(posedge Clock or negedge Reset_n) begin
        if(!Reset_n) begin
            current_state <= 2'b00; // IDLE
        end else begin
            current_state <= next_state;
        end
    end
    
    // 输出控制逻辑 - 寄存器已移动到输出端前面
    always @(posedge Clock or negedge Reset_n) begin
        if(!Reset_n) begin
            SendACK <= 1'b0;
            SendNAK <= 1'b0;
            SendDATA <= 1'b0;
        end else begin
            SendACK <= (current_state == DATA && next_state == STATUS);
            SendNAK <= 1'b0; // Simplified for brevity
            SendDATA <= (current_state == TOKEN && next_state == DATA);
        end
    end
endmodule

// 状态转换逻辑子模块
module usb_state_transition (
    input wire [1:0] current_state,
    input wire SOF_Received,
    input wire TOKEN_Received,
    input wire DATA_Received,
    output reg [1:0] next_state
);
    // 状态定义
    localparam IDLE=2'b00, TOKEN=2'b01, DATA=2'b10, STATUS=2'b11;
    
    // 状态转换逻辑
    always @(*) begin
        next_state = current_state;
        case(current_state)
            IDLE:   if(TOKEN_Received) next_state = TOKEN;
                    else if(SOF_Received) next_state = IDLE;
            TOKEN:  if(DATA_Received) next_state = DATA;
            DATA:   next_state = STATUS;
            STATUS: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
endmodule