//SystemVerilog
module serial_range_detector(
    input wire clk, rst, data_bit, valid,
    input wire [7:0] lower, upper,
    output reg in_range
);
    reg [7:0] shift_reg;
    reg [2:0] bit_count;
    
    wire [7:0] next_shift_reg = {shift_reg[6:0], data_bit};
    
    // 条件反相减法器实现
    // 减法器1：计算next_shift_reg与lower的比较
    wire [7:0] lower_diff;
    wire [7:0] lower_inverted = ~lower;
    wire lower_carry;
    assign {lower_carry, lower_diff} = next_shift_reg + lower_inverted + 1'b1;
    wire lower_check = lower_carry;
    
    // 减法器2：计算upper与next_shift_reg的比较
    wire [7:0] upper_diff;
    wire [7:0] next_shift_reg_inverted = ~next_shift_reg;
    wire upper_carry;
    assign {upper_carry, upper_diff} = upper + next_shift_reg_inverted + 1'b1;
    wire upper_check = upper_carry;
    
    // 使用进位信号检查范围
    wire in_range_next = lower_check && upper_check;
    
    always @(posedge clk) begin
        if (rst) begin 
            shift_reg <= 8'b0; 
            bit_count <= 3'b0; 
            in_range <= 1'b0; 
        end
        else if (valid) begin
            shift_reg <= next_shift_reg;
            bit_count <= bit_count + 1'b1;
            
            if (bit_count == 3'b111)
                in_range <= in_range_next;
        end
    end
endmodule