//SystemVerilog
module error_detect_bridge #(parameter DWIDTH=32) (
    input clk, rst_n,
    input [DWIDTH-1:0] in_data,
    input in_valid,
    output reg in_ready,
    output reg [DWIDTH-1:0] out_data,
    output reg out_valid,
    output reg error,
    input out_ready
);
    // 优化奇偶校验计算 - 使用异或归约运算符
    wire calc_parity;
    assign calc_parity = ^in_data;
    
    // 状态定义
    localparam IDLE = 2'b00;
    localparam ACTIVE = 2'b01;
    localparam ERROR_STATE = 2'b10;
    
    reg [1:0] state, next_state;
    
    // 状态转移逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // 下一状态逻辑
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: 
                if (in_valid)
                    next_state = ACTIVE;
            ACTIVE: 
                if (out_ready)
                    next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 0;
            in_ready <= 1;
            error <= 0;
            out_data <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (in_valid) begin
                        out_data <= in_data;
                        out_valid <= 1;
                        in_ready <= 0;
                        error <= ~calc_parity; // 奇校验：如果为0则有错误
                    end
                end
                ACTIVE: begin
                    if (out_ready) begin
                        out_valid <= 0;
                        in_ready <= 1;
                        error <= 0;
                    end
                end
            endcase
        end
    end
endmodule