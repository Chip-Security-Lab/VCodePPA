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
    // 預計算常量值，避免運行時計算
    localparam COUNTER_MAX = (CLK_FREQ/1000)*DEBOUNCE_MS;
    localparam CNT_WIDTH = $clog2(COUNTER_MAX+1);
    
    // 使用one-hot編碼降低FSM的組合邏輯深度
    localparam IDLE = 2'b01;
    localparam DEBOUNCE = 2'b10;
    reg [1:0] current_state, next_state;
    
    // 優化計數器位寬以減少資源使用
    reg [CNT_WIDTH-1:0] debounce_counter;
    reg key_sampled;
    
    // 提前計算狀態轉換條件以減少組合邏輯延遲
    wire is_max_count = (debounce_counter >= COUNTER_MAX - 1);
    wire key_changed = (key_stable != key_raw);
    wire sample_mismatch = (key_raw != key_sampled);

    // 狀態寄存器和數據路徑更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            debounce_counter <= 0;
            key_stable <= 1'b1;
            key_valid <= 1'b0;
            key_sampled <= 1'b1;
        end else begin
            current_state <= next_state;
            
            // 默認復位key_valid
            key_valid <= 1'b0;
            
            case (current_state)
                IDLE: begin
                    key_sampled <= key_raw;
                    debounce_counter <= 0;
                end
                
                DEBOUNCE: begin
                    // 增加計數器
                    debounce_counter <= debounce_counter + 1'b1;
                    
                    // 優化if條件檢查，減少組合邏輯深度
                    if (is_max_count) begin
                        key_stable <= key_sampled;
                        key_valid <= 1'b1;
                    end
                end
                
                default: begin
                    debounce_counter <= 0;
                    key_sampled <= key_raw;
                end
            endcase
        end
    end

    // 優化FSM狀態轉換邏輯
    always @(*) begin
        // 默認保持當前狀態
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                // 直接使用預計算的條件
                if (key_changed) next_state = DEBOUNCE;
            end
            
            DEBOUNCE: begin
                // 使用預計算條件並平衡邏輯路徑
                if (sample_mismatch || is_max_count) begin
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
endmodule