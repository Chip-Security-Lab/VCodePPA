//SystemVerilog
module key_debouncer(
    input wire clk,
    input wire reset,
    input wire key_in,
    output reg key_pressed,
    output reg key_released
);
    parameter [1:0] IDLE = 2'b00, DETECTED = 2'b01, 
                    PRESSED = 2'b10, RELEASED = 2'b11;
    reg [1:0] state, next_state;
    reg [15:0] debounce_counter;
    parameter DEBOUNCE_TIME = 16'd1000; // Adjust based on clock frequency
    
    // 状态寄存器和输出逻辑
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            debounce_counter <= 16'd0;
            key_pressed <= 1'b0;
            key_released <= 1'b0;
        end else begin
            state <= next_state;
            
            // 默认值设置
            key_pressed <= 1'b0;
            key_released <= 1'b0;
            
            // 计数器逻辑
            if (state == IDLE || state == RELEASED) begin
                debounce_counter <= 16'd0;
            end else if (state == DETECTED) begin
                debounce_counter <= debounce_counter + 1'b1;
            end
            
            // 输出逻辑
            if (state == PRESSED) begin
                key_pressed <= 1'b1;
            end else if (state == RELEASED) begin
                key_released <= 1'b1;
            end
        end
    end
    
    // 扁平化的状态转换逻辑
    always @(*) begin
        // 默认状态
        next_state = state;
        
        // IDLE状态转换
        if (state == IDLE && key_in) begin
            next_state = DETECTED;
        end
        
        // DETECTED状态转换
        if (state == DETECTED && !key_in) begin
            next_state = IDLE;
        end else if (state == DETECTED && key_in && debounce_counter >= DEBOUNCE_TIME) begin
            next_state = PRESSED;
        end
        
        // PRESSED状态转换
        if (state == PRESSED && !key_in) begin
            next_state = RELEASED;
        end
        
        // RELEASED状态转换
        if (state == RELEASED) begin
            next_state = IDLE;
        end
    end
endmodule