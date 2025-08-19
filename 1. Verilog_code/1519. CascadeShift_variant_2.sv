//SystemVerilog
// IEEE 1364-2005 Verilog standard
module CascadeShift #(parameter STAGES=2, WIDTH=8) (
    input clk, cascade_en,
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] dout
);
    // 主流水线寄存器
    reg [WIDTH-1:0] stage [0:STAGES-1];
    
    // 缓冲寄存器，为高扇出信号stage添加缓冲
    reg [WIDTH-1:0] stage_buf1 [0:STAGES-2];
    reg [WIDTH-1:0] stage_buf2 [0:STAGES-2];
    
    integer i;

    always @(posedge clk) begin
        if (cascade_en) begin
            // 第一级直接加载输入数据
            stage[0] <= din;
            
            // 为每级stage[i-1]添加两级扇出缓冲
            for(i=1; i<STAGES; i=i+1) begin
                stage_buf1[i-1] <= stage[i-1];
                stage_buf2[i-1] <= stage_buf1[i-1];
                stage[i] <= stage_buf2[i-1];
            end
        end
    end

    // 最终输出使用最后一级寄存器
    assign dout = stage[STAGES-1];
endmodule