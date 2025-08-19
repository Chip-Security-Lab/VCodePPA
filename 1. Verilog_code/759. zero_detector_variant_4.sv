//SystemVerilog
module zero_detector #(
    parameter WIDTH = 12
)(
    input [WIDTH-1:0] data_bus,
    output zero_flag,            // High when all bits are zero
    output non_zero_flag,        // High when any bit is one
    output [3:0] leading_zeros   // Count of leading zeros (MSB side)
);
    // Detect if all bits are zero
    assign zero_flag = (data_bus == {WIDTH{1'b0}});
    
    // Detect if any bit is one
    assign non_zero_flag = |data_bus;
    
    // 条件反相减法器实现计数器
    wire [3:0] init_count = 4'd0;
    wire [3:0] max_width = (WIDTH > 15) ? 4'd15 : WIDTH[3:0];
    
    // 条件反相减法器信号
    wire [3:0] subtrahend = 4'd1;
    wire cin = 1'b1; // 取反加一的进位
    wire [3:0] subtrahend_complement;
    wire [3:0] interim_result;
    wire [3:0] lz_count;
    
    // 生成减数的反码
    assign subtrahend_complement = ~subtrahend;
    
    // 使用条件反相减法器算法实现leading zeros计数
    assign interim_result = init_count;
    
    reg [3:0] conditional_sub_result;
    always @(*) begin
        conditional_sub_result = interim_result;
        
        if (!data_bus[WIDTH-1]) begin
            conditional_sub_result = interim_result + subtrahend_complement + cin;
            
            if (!data_bus[WIDTH-2]) begin
                conditional_sub_result = conditional_sub_result + subtrahend_complement + cin;
                
                if (!data_bus[WIDTH-3]) begin
                    conditional_sub_result = conditional_sub_result + subtrahend_complement + cin;
                    
                    if (!data_bus[WIDTH-4]) begin
                        conditional_sub_result = conditional_sub_result + subtrahend_complement + cin;
                        
                        if (WIDTH > 4 && !data_bus[WIDTH-5]) begin
                            conditional_sub_result = conditional_sub_result + subtrahend_complement + cin;
                            
                            if (WIDTH > 5 && !data_bus[WIDTH-6]) begin
                                conditional_sub_result = conditional_sub_result + subtrahend_complement + cin;
                                
                                if (WIDTH > 6 && !data_bus[WIDTH-7]) begin
                                    conditional_sub_result = conditional_sub_result + subtrahend_complement + cin;
                                    
                                    if (WIDTH > 7 && !data_bus[WIDTH-8]) begin
                                        conditional_sub_result = conditional_sub_result + subtrahend_complement + cin;
                                        
                                        if (WIDTH > 8 && !data_bus[WIDTH-9]) begin
                                            conditional_sub_result = conditional_sub_result + subtrahend_complement + cin;
                                            
                                            if (WIDTH > 9 && !data_bus[WIDTH-10]) begin
                                                conditional_sub_result = conditional_sub_result + subtrahend_complement + cin;
                                                
                                                if (WIDTH > 10 && !data_bus[WIDTH-11]) begin
                                                    conditional_sub_result = conditional_sub_result + subtrahend_complement + cin;
                                                    
                                                    if (WIDTH > 11 && !data_bus[WIDTH-12]) begin
                                                        conditional_sub_result = conditional_sub_result + subtrahend_complement + cin;
                                                        
                                                        if (WIDTH > 12 && !data_bus[WIDTH-13]) begin
                                                            conditional_sub_result = conditional_sub_result + subtrahend_complement + cin;
                                                            
                                                            if (WIDTH > 13 && !data_bus[WIDTH-14]) begin
                                                                conditional_sub_result = conditional_sub_result + subtrahend_complement + cin;
                                                                
                                                                if (WIDTH > 14 && !data_bus[WIDTH-15]) begin
                                                                    conditional_sub_result = conditional_sub_result + subtrahend_complement + cin;
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    // 使用条件反相减法结果或最大值
    assign lz_count = (conditional_sub_result <= max_width) ? conditional_sub_result : max_width;
    
    // 输出结果
    assign leading_zeros = lz_count;
endmodule