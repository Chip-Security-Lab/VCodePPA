//SystemVerilog
module poly1305_mac #(parameter WIDTH = 32) (
    input wire clk, reset_n,
    input wire update, finalize,
    input wire [WIDTH-1:0] r_key, s_key, data_in,
    output reg [WIDTH-1:0] mac_out,
    output reg ready, mac_valid
);
    reg [WIDTH-1:0] accumulator, r;
    reg [1:0] state, next_state;
    
    localparam IDLE = 2'b00;
    localparam ACCUMULATE = 2'b01;
    localparam FINAL = 2'b10;
    
    // 状态寄存器更新
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) 
            state <= IDLE;
        else 
            state <= next_state;
    end
    
    // 扁平化状态转换逻辑
    always @(*) begin
        next_state = state;
        
        if (state == IDLE && update && ready)
            next_state = ACCUMULATE;
        else if (state == ACCUMULATE && finalize)
            next_state = FINAL;
        else if (state == FINAL)
            next_state = IDLE;
    end
    
    // r寄存器控制逻辑
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            r <= 0;
        else if (state == IDLE && update && ready)
            r <= r_key & 32'h0FFFFFFF; // Mask off top bits as in Poly1305
    end
    
    // 累加器控制逻辑
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            accumulator <= 0;
        else if (state == IDLE && update && ready)
            accumulator <= 0;
        else if (state == ACCUMULATE && update)
            // Add data and multiply by r (simplified)
            accumulator <= ((accumulator + data_in) * r) % (2**WIDTH - 5);
    end
    
    // MAC输出控制逻辑 - 扁平化结构
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            mac_out <= 0;
            mac_valid <= 0;
        end
        else if (state == FINAL) begin
            mac_out <= (accumulator + s_key) % (2**WIDTH);
            mac_valid <= 1;
        end
        else if (state == IDLE) 
            mac_valid <= 0;
    end
    
    // ready信号控制逻辑 - 扁平化结构
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            ready <= 1;
        else if (state == IDLE && update && ready)
            ready <= 0;
        else if (state == ACCUMULATE && !update && !finalize)
            ready <= 1;
        else if (state == FINAL)
            ready <= 1;
    end
    
endmodule