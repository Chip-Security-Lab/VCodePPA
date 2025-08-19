//SystemVerilog
module pipelined_range_detector(
    input wire clock, reset,
    input wire [23:0] data,
    input wire [23:0] min_range, max_range,
    output reg valid_range
);
    // 移除中间寄存器，将比较逻辑直接连接到输出寄存器
    wire data_in_range;
    
    // 先执行组合逻辑比较
    assign data_in_range = (data >= min_range) && (data <= max_range);
    
    always @(posedge clock) begin
        if (reset) begin
            valid_range <= 1'b0;
        end else begin
            // 直接将组合逻辑结果注册到输出
            valid_range <= data_in_range;
        end
    end
endmodule