//SystemVerilog
module therm2bin_converter #(
    parameter THERM_WIDTH = 7
)(
    input  wire [THERM_WIDTH-1:0] therm_code,
    output wire [$clog2(THERM_WIDTH+1)-1:0] bin_code
);
    // 内部连接信号
    wire [$clog2(THERM_WIDTH+1)-1:0] count_result;
    
    // 实例化计数子模块
    ones_counter #(
        .INPUT_WIDTH(THERM_WIDTH)
    ) counter_inst (
        .data_in(therm_code),
        .count_out(count_result)
    );
    
    // 结果映射
    assign bin_code = count_result;
endmodule

module ones_counter #(
    parameter INPUT_WIDTH = 7
)(
    input  wire [INPUT_WIDTH-1:0] data_in,
    output reg [$clog2(INPUT_WIDTH+1)-1:0] count_out
);
    // 计数1的数量
    integer i;
    
    // 使用并行加法树结构来提高性能
    always @(*) begin
        count_out = 0;
        for (i = 0; i < INPUT_WIDTH; i = i + 1) begin
            count_out = count_out + data_in[i];
        end
    end
endmodule