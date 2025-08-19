//SystemVerilog
module ManchesterDecoder (
    input clk_16x,
    input manchester_in,
    output reg [7:0] decoded_data,
    output reg req,          // 原valid信号，现在是req请求信号
    input ack               // 新增ack应答信号，替代原ready信号
);
    // Register moved before combinational logic
    reg manchester_in_reg;
    reg [14:0] shift_reg;
    reg [3:0] bit_counter;
    reg [7:0] pattern_reg;
    reg pattern_matched;
    reg req_pending;        // 跟踪请求状态
    
    always @(posedge clk_16x) begin
        // Input registration
        manchester_in_reg <= manchester_in;
        
        // Shift register now uses registered input
        shift_reg <= {shift_reg[13:0], manchester_in_reg};
        
        // Pre-compute pattern match to reduce critical path
        pattern_reg <= {shift_reg[14:8], manchester_in_reg};
        pattern_matched <= (pattern_reg == 8'b01010101);
        
        // Req-Ack握手逻辑
        if (req && ack) begin
            // 握手完成，清除请求
            req <= 1'b0;
            req_pending <= 1'b0;
        end else if (pattern_matched && !req_pending) begin
            // 检测到匹配模式且没有未完成的请求，发出新请求
            decoded_data <= shift_reg[7:0];
            req <= 1'b1;
            req_pending <= 1'b1;
            bit_counter <= 4'd0;
        end else if (!req && pattern_matched && req_pending) begin
            // 重新发出请求（如果之前的请求被接收方确认后，又检测到了新模式）
            req <= 1'b1;
        end else begin
            bit_counter <= (bit_counter == 4'd15) ? 4'd0 : bit_counter + 4'd1;
        end
    end
endmodule