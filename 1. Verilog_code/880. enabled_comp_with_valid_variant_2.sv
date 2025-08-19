//SystemVerilog
module enabled_comp_with_valid #(parameter WIDTH = 4)(
    input clock, reset, enable,
    input [WIDTH-1:0] in_values [0:WIDTH-1],
    output reg [$clog2(WIDTH)-1:0] highest_idx,
    output reg valid_result
);
    integer j;
    reg [WIDTH-1:0] max_value;
    wire [WIDTH-1:0] twos_comp_diff;
    reg [WIDTH-1:0] current_value;
    
    // Two's complement subtraction
    assign twos_comp_diff = max_value + (~current_value + 1'b1);
    
    always @(posedge clock) begin
        if (reset) begin
            highest_idx <= 0;
            valid_result <= 0;
            max_value <= 0;
            current_value <= 0;
        end else if (enable) begin
            max_value <= in_values[0];
            highest_idx <= 0;
            
            // 初始化循环变量
            j = 1;
            
            // 使用 while 循环代替 for 循环
            while (j < WIDTH) begin
                current_value <= in_values[j];
                
                if (twos_comp_diff[WIDTH-1] == 1'b0 && current_value > max_value) begin
                    max_value <= current_value;
                    highest_idx <= j[$clog2(WIDTH)-1:0];
                end
                
                // 迭代步骤放在循环体末尾
                j = j + 1;
            end
            
            valid_result <= 1;
        end else begin
            valid_result <= 0;
        end
    end
endmodule