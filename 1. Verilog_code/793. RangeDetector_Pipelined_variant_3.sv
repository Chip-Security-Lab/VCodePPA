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
    reg [WIDTH-1:0] data_pipe [PIPELINE_STAGES-1:0];
    reg [WIDTH-1:0] lower_pipe [PIPELINE_STAGES-1:0];
    reg [WIDTH-1:0] upper_pipe [PIPELINE_STAGES-1:0];
    
    // 将比较逻辑从寄存器后移到寄存器前
    reg cmp_lower, cmp_upper;
    integer i;

    // 提前进行比较操作，减少关键路径
    always @(*) begin
        cmp_lower = (data_pipe[PIPELINE_STAGES-2] >= lower_pipe[PIPELINE_STAGES-2]);
        cmp_upper = (data_pipe[PIPELINE_STAGES-2] <= upper_pipe[PIPELINE_STAGES-2]);
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0; i<PIPELINE_STAGES; i=i+1) begin
                data_pipe[i] <= 0;
                lower_pipe[i] <= 0;
                upper_pipe[i] <= 0;
            end
            out_valid <= 0;
            out_flag <= 0;
        end else begin
            data_pipe[0] <= data_in;
            lower_pipe[0] <= lower;
            upper_pipe[0] <= upper;
            for(i=1; i<PIPELINE_STAGES; i=i+1) begin
                data_pipe[i] <= data_pipe[i-1];
                lower_pipe[i] <= lower_pipe[i-1];
                upper_pipe[i] <= upper_pipe[i-1];
            end
            
            // 将比较结果寄存
            out_flag <= cmp_lower && cmp_upper;
            out_valid <= 1'b1;
        end
    end
endmodule