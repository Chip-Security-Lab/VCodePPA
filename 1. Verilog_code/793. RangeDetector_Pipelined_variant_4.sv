//SystemVerilog
module RangeDetector_Pipelined #(
    parameter WIDTH = 8,
    parameter PIPELINE_STAGES = 2
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] lower,
    input [WIDTH-1:0] upper,
    output reg out_valid,
    output reg out_flag
);
    // 不再直接寄存输入数据
    wire lower_comparison_wire = (data_in >= lower);
    wire upper_comparison_wire = (data_in <= upper);
    
    // 修改管道寄存器结构
    reg [PIPELINE_STAGES-1:0] lower_comparison;
    reg [PIPELINE_STAGES-1:0] upper_comparison;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0; i<PIPELINE_STAGES; i=i+1) begin
                lower_comparison[i] <= 0;
                upper_comparison[i] <= 0;
            end
            out_valid <= 0;
            out_flag <= 0;
        end else begin
            // 直接寄存比较结果，而不是寄存输入数据
            lower_comparison[0] <= lower_comparison_wire;
            upper_comparison[0] <= upper_comparison_wire;
            
            // 中间管道寄存器
            for(i=1; i<PIPELINE_STAGES; i=i+1) begin
                lower_comparison[i] <= lower_comparison[i-1];
                upper_comparison[i] <= upper_comparison[i-1];
            end
            
            // 最终的逻辑只是简单的AND操作
            out_flag <= lower_comparison[PIPELINE_STAGES-1] && upper_comparison[PIPELINE_STAGES-1];
            out_valid <= 1'b1;
        end
    end
endmodule