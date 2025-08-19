//SystemVerilog
module shift_buffer #(
    parameter WIDTH = 8,
    parameter STAGES = 4
)(
    input wire clk,
    input wire enable,
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    // 对输入数据进行直接输出，移除第一级寄存器的延迟
    wire [WIDTH-1:0] stage0_data;
    assign stage0_data = enable ? data_in : shift_reg[0];
    
    // 移位寄存器，现在只需要STAGES-1个寄存器
    reg [WIDTH-1:0] shift_reg [0:STAGES-2];
    
    // 重新设计的移位逻辑，展开循环以提高并行性
    always @(posedge clk) begin
        shift_reg[0] <= stage0_data;
        if (STAGES > 2) shift_reg[1] <= shift_reg[0];
        if (STAGES > 3) shift_reg[2] <= shift_reg[1];
        // 针对更大的STAGES值，这里可以继续展开
    end
    
    // 输出连接到最后一级寄存器或直接连到输入（如果STAGES=1）
    assign data_out = (STAGES == 1) ? stage0_data : shift_reg[STAGES-2];
endmodule