//SystemVerilog
module PipelinedNOT(
    input wire clk,
    input wire [31:0] stage_in,
    output reg [31:0] stage_out
);
    // 中间寄存器，分割数据流路径
    reg [31:0] intermediate_data;
    
    // 合并后的流水线 - 同时处理所有位并组合输出
    always @(posedge clk) begin
        intermediate_data <= ~stage_in;
        stage_out <= intermediate_data;
    end
endmodule