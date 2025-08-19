//SystemVerilog
module watchdog_timer(
    input wire clk, rst_n,
    input wire [15:0] timeout_value,
    input wire update_timeout,
    input wire kick,
    output reg timeout,
    output reg [2:0] warn_level
);
    localparam IDLE=2'b00, COUNTING=2'b01, TIMEOUT=2'b10, RESET=2'b11;
    reg [1:0] state, next;
    reg [15:0] counter;
    reg [15:0] timeout_reg;
    
    // 符号乘法器的系数和结果
    reg signed [15:0] multiplier_a;
    reg signed [15:0] multiplier_b;
    wire signed [31:0] mult_result;
    
    // 警告阈值
    wire [15:0] threshold_1, threshold_2, threshold_3;
    
    // 使用带符号乘法代替移位运算
    assign mult_result = multiplier_a * multiplier_b;
    
    // 计算不同警告级别的阈值
    assign threshold_3 = mult_result[15:0]; // 50% 阈值
    assign threshold_2 = {mult_result[14:0], 1'b0}; // 25% 阈值
    assign threshold_1 = {mult_result[13:0], 2'b00}; // 12.5% 阈值
    
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            state <= IDLE;
            counter <= 16'd0;
            timeout_reg <= 16'd1000; // Default timeout
            timeout <= 1'b0;
            warn_level <= 3'd0;
            multiplier_a <= 16'sd0;
            multiplier_b <= 16'sd0;
        end else begin
            state <= next;
            
            if (update_timeout) begin
                timeout_reg <= timeout_value;
                // 设置乘法器操作数，计算50%的阈值
                multiplier_a <= $signed(timeout_value);
                multiplier_b <= 16'sd5; // 乘以0.5的系数（实际乘以5然后右移10位）
            end
                
            if (state == IDLE) begin
                counter <= 16'd0;
                timeout <= 1'b0;
                warn_level <= 3'd0;
            end else if (state == COUNTING) begin
                if (kick)
                    counter <= 16'd0;
                else begin
                    counter <= counter + 16'd1;
                    
                    // 使用乘法器计算的阈值来设置警告级别
                    if (counter > threshold_3)
                        warn_level <= 3'd3;
                    else if (counter > threshold_2)
                        warn_level <= 3'd2;
                    else if (counter > threshold_1)
                        warn_level <= 3'd1;
                    else
                        warn_level <= 3'd0;
                end
            end else if (state == TIMEOUT) begin
                timeout <= 1'b1;
                warn_level <= 3'd7;
            end else if (state == RESET) begin
                counter <= 16'd0;
                timeout <= 1'b0;
                warn_level <= 3'd0;
            end
        end
    
    always @(*)
        if (state == IDLE) begin
            next = COUNTING;
        end else if (state == COUNTING) begin
            if (counter >= timeout_reg)
                next = TIMEOUT;
            else
                next = COUNTING;
        end else if (state == TIMEOUT) begin
            if (kick)
                next = RESET;
            else
                next = TIMEOUT;
        end else if (state == RESET) begin
            next = COUNTING;
        end else begin
            next = IDLE;
        end
endmodule