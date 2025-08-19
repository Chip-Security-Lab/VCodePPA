//SystemVerilog
module ShiftDetector #(parameter WIDTH=8) (
    input clk, rst_n,
    input data_in,
    input valid_in,
    output reg valid_out,
    output reg sequence_found
);
    localparam PATTERN = 8'b11010010;
    
    // 流水线寄存器
    reg [WIDTH-1:0] shift_reg_stage1;
    reg pattern_match_stage2;
    reg valid_stage1, valid_stage2;
    
    // 补码加法实现减法
    wire [WIDTH-1:0] pattern_comp = ~PATTERN + 1'b1;
    wire [WIDTH-1:0] diff_result;
    wire carry_out;
    
    // 8位补码加法器
    assign {carry_out, diff_result} = shift_reg_stage1 + pattern_comp;
    
    // 第一级流水线：数据移位和存储
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage1 <= 0;
            valid_stage1 <= 0;
        end
        else begin
            shift_reg_stage1 <= {shift_reg_stage1[WIDTH-2:0], data_in};
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线：模式匹配
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pattern_match_stage2 <= 0;
            valid_stage2 <= 0;
        end
        else begin
            pattern_match_stage2 <= (diff_result == 0) & (carry_out == 1);
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线：输出寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sequence_found <= 0;
            valid_out <= 0;
        end
        else begin
            sequence_found <= pattern_match_stage2;
            valid_out <= valid_stage2;
        end
    end
endmodule