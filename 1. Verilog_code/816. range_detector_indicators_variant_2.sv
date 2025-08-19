//SystemVerilog
module range_detector_indicators(
    input wire [11:0] input_value,
    input wire [11:0] min_threshold, max_threshold,
    output reg in_range,
    output reg below_range,
    output reg above_range
);
    // 定义比较结果标志
    reg [1:0] range_type;
    
    // 使用参数定义状态，提高可读性
    localparam BELOW = 2'b01;
    localparam IN_RANGE = 2'b10;
    localparam ABOVE = 2'b11;
    
    // 计算比较结果
    always @(*) begin
        if (input_value < min_threshold)
            range_type = BELOW;
        else if (input_value > max_threshold)
            range_type = ABOVE;
        else
            range_type = IN_RANGE;
    end
    
    // 基于比较结果设置输出信号
    always @(*) begin
        // 默认值设置
        below_range = 1'b0;
        in_range = 1'b0;
        above_range = 1'b0;
        
        // 使用case语句替代if-else级联
        case(range_type)
            BELOW: begin
                below_range = 1'b1;
            end
            IN_RANGE: begin
                in_range = 1'b1;
            end
            ABOVE: begin
                above_range = 1'b1;
            end
            default: begin
                // 默认情况保持所有输出为0
            end
        endcase
    end
endmodule