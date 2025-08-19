//SystemVerilog
module DebounceFSM #(
    parameter DEBOUNCE_MS = 20,
    parameter CLK_FREQ = 50_000_000
)(
    input clk, rst_n,
    input key_raw,
    output reg key_stable,
    output reg key_valid
);
    localparam COUNTER_MAX = (CLK_FREQ/1000)*DEBOUNCE_MS;
    
    // 使用localparam代替typedef enum
    localparam IDLE = 1'b0, DEBOUNCE = 1'b1;
    reg current_state, next_state;
    
    reg [31:0] debounce_counter;
    reg key_sampled;

    // 合并always块，将时序逻辑和状态转换逻辑放在一起
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位初始化
            current_state <= IDLE;
            debounce_counter <= 0;
            key_stable <= 1'b1;
            key_valid <= 0;
            key_sampled <= 1'b1;
        end else begin
            // 默认复位key_valid
            key_valid <= 0;
            
            // 状态转换逻辑
            case(current_state)
                IDLE: begin
                    // 时序逻辑
                    debounce_counter <= 0;
                    key_sampled <= key_raw; // 采样当前按键状态
                    
                    // 状态转换
                    if (key_stable != key_raw) 
                        current_state <= DEBOUNCE;
                end
                
                DEBOUNCE: begin
                    // 时序逻辑
                    debounce_counter <= debounce_counter + 1;
                    
                    // 状态转换和输出控制
                    if (debounce_counter == COUNTER_MAX) begin
                        key_stable <= key_sampled;
                        key_valid <= 1;
                        current_state <= IDLE;
                    end else if (key_raw != key_sampled) begin
                        current_state <= IDLE;
                    end
                end
                
                default: current_state <= IDLE;
            endcase
        end
    end
endmodule