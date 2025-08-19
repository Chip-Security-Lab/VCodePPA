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

    // 组合逻辑信号
    wire [WIDTH:0] diff_lower, diff_upper;
    wire lower_flag, upper_flag;
    
    // 重定时后的流水线寄存器
    reg [WIDTH-1:0] data_pipe [PIPELINE_STAGES-1:0];
    reg [WIDTH-1:0] lower_pipe [PIPELINE_STAGES-1:0];
    reg [WIDTH-1:0] upper_pipe [PIPELINE_STAGES-1:0];
    reg [WIDTH:0] diff_lower_reg, diff_upper_reg;
    reg lower_flag_reg, upper_flag_reg;
    
    integer i;

    // 组合逻辑比较电路
    assign diff_lower = {1'b0, data_in} + {1'b0, ~lower} + 1'b1;
    assign lower_flag = diff_lower[WIDTH];
    
    assign diff_upper = {1'b0, upper} + {1'b0, ~data_in} + 1'b1;
    assign upper_flag = diff_upper[WIDTH];

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            i = 0;
            while(i < PIPELINE_STAGES) begin
                data_pipe[i] <= 0;
                lower_pipe[i] <= 0;
                upper_pipe[i] <= 0;
                i = i + 1;
            end
            diff_lower_reg <= 0;
            diff_upper_reg <= 0;
            lower_flag_reg <= 0;
            upper_flag_reg <= 0;
            out_valid <= 0;
            out_flag <= 0;
        end else begin
            // 流水线第一级
            data_pipe[0] <= data_in;
            lower_pipe[0] <= lower;
            upper_pipe[0] <= upper;
            diff_lower_reg <= diff_lower;
            diff_upper_reg <= diff_upper;
            lower_flag_reg <= lower_flag;
            upper_flag_reg <= upper_flag;
            
            // 流水线后续级
            i = 1;
            while(i < PIPELINE_STAGES) begin
                data_pipe[i] <= data_pipe[i-1];
                lower_pipe[i] <= lower_pipe[i-1];
                upper_pipe[i] <= upper_pipe[i-1];
                i = i + 1;
            end
            
            // 输出结果
            out_flag <= lower_flag_reg && upper_flag_reg;
            out_valid <= 1'b1;
        end
    end
endmodule