//SystemVerilog
module RangeDetector_Pipelined #(
    parameter WIDTH = 8,
    parameter PIPELINE_STAGES = 4  // 增加流水线级数
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
    
    // 比较结果的流水线寄存器
    reg comp_lower_stage1;
    reg comp_lower_stage2;
    reg comp_upper_stage1;
    reg comp_upper_stage2;
    
    // 有效信号流水线
    reg [PIPELINE_STAGES-1:0] valid_pipe;
    
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0; i<PIPELINE_STAGES; i=i+1) begin
                data_pipe[i] <= 0;
                lower_pipe[i] <= 0;
                upper_pipe[i] <= 0;
                valid_pipe[i] <= 0;
            end
            comp_lower_stage1 <= 0;
            comp_lower_stage2 <= 0;
            comp_upper_stage1 <= 0;
            comp_upper_stage2 <= 0;
            out_valid <= 0;
            out_flag <= 0;
        end else begin
            // 第一级流水线：输入寄存
            data_pipe[0] <= data_in;
            lower_pipe[0] <= lower;
            upper_pipe[0] <= upper;
            valid_pipe[0] <= 1'b1;
            
            // 第二级流水线：数据移动和第一阶段比较
            data_pipe[1] <= data_pipe[0];
            lower_pipe[1] <= lower_pipe[0];
            upper_pipe[1] <= upper_pipe[0];
            valid_pipe[1] <= valid_pipe[0];
            comp_lower_stage1 <= (data_pipe[0] >= lower_pipe[0]); // 第一级比较
            
            // 第三级流水线：数据移动和第二阶段比较
            data_pipe[2] <= data_pipe[1];
            lower_pipe[2] <= lower_pipe[1];
            upper_pipe[2] <= upper_pipe[1];
            valid_pipe[2] <= valid_pipe[1];
            comp_lower_stage2 <= comp_lower_stage1;
            comp_upper_stage1 <= (data_pipe[1] <= upper_pipe[1]); // 第二级比较
            
            // 剩余流水线级数的数据移动
            for(i=3; i<PIPELINE_STAGES; i=i+1) begin
                data_pipe[i] <= data_pipe[i-1];
                lower_pipe[i] <= lower_pipe[i-1];
                upper_pipe[i] <= upper_pipe[i-1];
                valid_pipe[i] <= valid_pipe[i-1];
            end
            
            // 最后阶段：结果计算和输出
            comp_upper_stage2 <= comp_upper_stage1;
            out_flag <= comp_lower_stage2 && comp_upper_stage2; // 最终比较结果合并
            out_valid <= valid_pipe[PIPELINE_STAGES-1];
        end
    end
endmodule