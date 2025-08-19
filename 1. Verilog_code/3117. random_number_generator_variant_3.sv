//SystemVerilog
module random_number_generator(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [7:0] seed,
    input wire load_seed,
    output reg [15:0] random_value
);
    localparam [1:0] IDLE = 2'b00, LOAD = 2'b01, GENERATE = 2'b10;
    
    reg [1:0] state, next_state;
    reg [15:0] lfsr_reg;
    wire feedback;
    
    // 简化反馈逻辑，使用wire替代reg以减少时序复杂度
    assign feedback = lfsr_reg[15] ^ (lfsr_reg[14] ^ lfsr_reg[12] ^ lfsr_reg[3]);
    
    // 状态转换逻辑扁平化优化
    always @(*) begin
        if (state == IDLE && load_seed)
            next_state = LOAD;
        else if (state == IDLE && enable)
            next_state = GENERATE;
        else if (state == IDLE && !load_seed && !enable)
            next_state = IDLE;
        else if (state == LOAD)
            next_state = GENERATE;
        else if (state == GENERATE && load_seed)
            next_state = LOAD;
        else if (state == GENERATE && !load_seed && !enable)
            next_state = IDLE;
        else if (state == GENERATE && !load_seed && enable)
            next_state = GENERATE;
        else
            next_state = IDLE;
    end
    
    // 时序逻辑扁平化优化
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            lfsr_reg <= 16'h1234; // 默认种子
            random_value <= 16'h0000;
        end else begin
            state <= next_state;
            
            if (state == LOAD) 
                lfsr_reg <= {seed, 8'h01}; // 确保不全为0
            else if (state == GENERATE && enable) begin
                lfsr_reg <= {lfsr_reg[14:0], feedback};
                random_value <= {lfsr_reg[14:0], feedback}; // 直接使用新计算的值，减少一个时钟周期延迟
            end
        end
    end
endmodule