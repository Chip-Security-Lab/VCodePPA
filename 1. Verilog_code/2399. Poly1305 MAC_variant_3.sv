//SystemVerilog
module poly1305_mac #(parameter WIDTH = 32) (
    input wire clk, reset_n,
    input wire update, finalize,
    input wire [WIDTH-1:0] r_key, s_key, data_in,
    output reg [WIDTH-1:0] mac_out,
    output reg ready, mac_valid
);
    // 状态定义
    localparam IDLE = 2'b00;
    localparam ACCUMULATE = 2'b01;
    localparam FINAL = 2'b10;
    
    // 内部寄存器
    reg [WIDTH-1:0] accumulator, r;
    reg [1:0] state, next_state;
    reg [WIDTH-1:0] acc_plus_data; // 预计算部分结果
    reg [2*WIDTH-1:0] mult_result; // 乘法结果暂存
    reg [WIDTH-1:0] modulo_result; // 取模结果
    
    // 常量定义
    localparam [WIDTH-1:0] MODULO = (2**WIDTH - 5);
    localparam [WIDTH-1:0] MASK = 32'h0FFFFFFF;
    
    // 状态转换逻辑 - 组合逻辑部分
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (update)
                    next_state = ACCUMULATE;
            end
            ACCUMULATE: begin
                if (finalize)
                    next_state = FINAL;
            end
            FINAL: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // 前馈计算逻辑 - 分解关键路径
    always @(*) begin
        // 预计算加法
        acc_plus_data = accumulator + data_in;
        
        // 预计算乘法
        mult_result = acc_plus_data * r;
        
        // 预计算模运算
        modulo_result = mult_result % MODULO;
    end
    
    // 时序逻辑
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            accumulator <= 0;
            r <= 0;
            state <= IDLE;
            ready <= 1'b1;
            mac_valid <= 1'b0;
            mac_out <= 0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    if (update && ready) begin
                        r <= r_key & MASK; // 应用Poly1305中的掩码
                        accumulator <= 0;
                        ready <= 1'b0;
                        mac_valid <= 1'b0;
                    end
                end
                
                ACCUMULATE: begin
                    if (update) begin
                        // 使用预计算结果
                        accumulator <= modulo_result;
                    end else if (!finalize) begin
                        ready <= 1'b1;
                    end
                end
                
                FINAL: begin
                    mac_out <= (accumulator + s_key) % (2**WIDTH);
                    mac_valid <= 1'b1;
                    ready <= 1'b1;
                end
            endcase
        end
    end
endmodule