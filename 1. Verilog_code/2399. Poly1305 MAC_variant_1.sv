//SystemVerilog
module poly1305_mac #(parameter WIDTH = 32) (
    input wire clk, reset_n,
    input wire update, finalize,
    input wire [WIDTH-1:0] r_key, s_key, data_in,
    output reg [WIDTH-1:0] mac_out,
    output reg ready, mac_valid
);
    // 内部信号定义
    reg [WIDTH-1:0] accumulator, r;
    reg [1:0] state, next_state;
    reg [WIDTH-1:0] data_in_reg, r_key_masked;
    reg update_reg, finalize_reg;
    
    // 状态定义
    localparam IDLE = 2'b00;
    localparam ACCUMULATE = 2'b01;
    localparam FINAL = 2'b10;
    
    // 将输入寄存器前移到组合逻辑前
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_in_reg <= 0;
            update_reg <= 0;
            finalize_reg <= 0;
            r_key_masked <= 0;
        end else begin
            data_in_reg <= data_in;
            update_reg <= update;
            finalize_reg <= finalize;
            r_key_masked <= r_key & 32'h0FFFFFFF; // 预先计算掩码
        end
    end
    
    // 组合逻辑部分计算状态转换
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (update_reg && ready)
                    next_state = ACCUMULATE;
            end
            ACCUMULATE: begin
                if (finalize_reg)
                    next_state = FINAL;
            end
            FINAL: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // 状态寄存器更新
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // r寄存器控制逻辑 - 重定时后
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            r <= 0;
        end else if (state == IDLE && update_reg && ready) begin
            r <= r_key_masked; // 使用预先计算的掩码值
        end
    end
    
    // 累加器逻辑 - 使用寄存后的输入数据
    reg [WIDTH-1:0] acc_add_result, acc_mul_result, acc_mod_result;
    
    // 将复杂组合运算拆分为多级流水线
    always @(*) begin
        acc_add_result = accumulator + data_in_reg;
        acc_mul_result = acc_add_result * r;
        acc_mod_result = acc_mul_result % (2**WIDTH - 5);
    end
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            accumulator <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (update_reg && ready)
                        accumulator <= 0;
                end
                ACCUMULATE: begin
                    if (update_reg) begin
                        accumulator <= acc_mod_result;
                    end
                end
                default: accumulator <= accumulator;
            endcase
        end
    end
    
    // 输出控制逻辑
    reg [WIDTH-1:0] final_result;
    
    always @(*) begin
        final_result = (accumulator + s_key) % (2**WIDTH);
    end
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            mac_out <= 0;
            mac_valid <= 0;
        end else if (state == FINAL) begin
            mac_out <= final_result;
            mac_valid <= 1;
        end else begin
            mac_valid <= 0;
        end
    end
    
    // ready信号控制逻辑
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            ready <= 1;
        end else begin
            case (state)
                IDLE: begin
                    if (update_reg && ready)
                        ready <= 0;
                end
                ACCUMULATE: begin
                    if (!update_reg && !finalize_reg)
                        ready <= 1;
                end
                FINAL: begin
                    ready <= 1;
                end
                default: ready <= ready;
            endcase
        end
    end
    
endmodule