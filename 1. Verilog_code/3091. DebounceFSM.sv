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
            
            if (current_state == DEBOUNCE) begin
                debounce_counter <= debounce_counter + 1;
                if (debounce_counter == COUNTER_MAX) begin
                    key_stable <= key_sampled;
                    key_valid <= 1; // 直接在时序逻辑中设置key_valid
                end
            end else begin
                debounce_counter <= 0;
                key_sampled <= key_raw; // 采样当前按键状态
            end
        end
    end

    always @(*) begin
        next_state = current_state;
        case(current_state)
            IDLE: if (key_stable != key_raw) next_state = DEBOUNCE;
            DEBOUNCE: begin
                if (debounce_counter >= COUNTER_MAX) begin
                    next_state = IDLE;
                end
                if (key_raw != key_sampled) begin
                    next_state = IDLE;
                end
            end
            default: next_state = IDLE;
        endcase
    end
endmodule