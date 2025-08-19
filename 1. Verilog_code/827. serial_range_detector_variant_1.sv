//SystemVerilog
module serial_range_detector(
    input wire clk, rst, data_bit, valid,
    input wire [7:0] lower, upper,
    output reg in_range
);
    reg [7:0] shift_reg;
    reg [2:0] bit_count;
    wire [7:0] next_shift_reg;
    wire [2:0] next_bit_count;
    wire range_check;
    
    // 优化的移位寄存器逻辑
    assign next_shift_reg = {shift_reg[6:0], data_bit};
    assign next_bit_count = bit_count + 1'b1;
    
    // 优化的范围检测逻辑
    // 使用单次比较而不是两次独立比较，减少逻辑层级
    wire less_than_lower, greater_than_upper;
    assign less_than_lower = (next_shift_reg < lower);
    assign greater_than_upper = (next_shift_reg > upper);
    assign range_check = ~(less_than_lower || greater_than_upper);
    
    // 添加流水线寄存器来改善时序
    reg byte_complete;
    
    always @(posedge clk) begin
        if (rst) begin 
            shift_reg <= 8'b0; 
            bit_count <= 3'b0; 
            in_range <= 1'b0;
            byte_complete <= 1'b0;
        end
        else if (valid) begin
            shift_reg <= next_shift_reg;
            bit_count <= next_bit_count;
            
            // 检测完整字节
            byte_complete <= (bit_count == 3'b111);
            
            // 只在收到完整字节时更新输出
            if (byte_complete)
                in_range <= range_check;
        end
    end
endmodule