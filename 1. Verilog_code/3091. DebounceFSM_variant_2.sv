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

    // 扁平化时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            debounce_counter <= 0;
            key_stable <= 1'b1;
            key_valid <= 0;
            key_sampled <= 1'b1;
        end else begin
            current_state <= next_state;
            key_valid <= 0; // 默认复位key_valid
            
            // 扁平化的条件结构
            if (current_state == DEBOUNCE && debounce_counter == COUNTER_MAX) begin
                key_stable <= key_sampled;
                key_valid <= 1;
            end
            
            if (current_state == DEBOUNCE) begin
                debounce_counter <= debounce_counter + 1;
            end
            
            if (current_state == IDLE) begin
                debounce_counter <= 0;
                key_sampled <= key_raw;
            end
        end
    end

    // 扁平化组合逻辑
    always @(*) begin
        next_state = current_state;
        
        if (current_state == IDLE && key_stable != key_raw) begin
            next_state = DEBOUNCE;
        end
        
        if (current_state == DEBOUNCE && debounce_counter >= COUNTER_MAX) begin
            next_state = IDLE;
        end
        
        if (current_state == DEBOUNCE && key_raw != key_sampled) begin
            next_state = IDLE;
        end
        
        // 默认安全保护
        if (current_state != IDLE && current_state != DEBOUNCE) begin
            next_state = IDLE;
        end
    end
endmodule