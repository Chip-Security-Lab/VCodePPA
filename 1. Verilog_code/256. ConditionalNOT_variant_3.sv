//SystemVerilog
module ConditionalNOT(
    input wire clk,
    input wire rst_n,
    input wire [31:0] data_in,
    output reg [31:0] result_out
);
    // 数据流水线寄存器
    reg [31:0] data_stage1;
    reg all_ones_detected_stage1;
    reg [31:0] inverted_data_stage2;
    reg all_ones_flag_stage2;
    
    // 第一级流水线：寄存输入数据和全1检测
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 32'h0;
            all_ones_detected_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data_in;
            all_ones_detected_stage1 <= (data_in == 32'hFFFFFFFF);
        end
    end
    
    // 第二级流水线：数据求反和标志位传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inverted_data_stage2 <= 32'h0;
            all_ones_flag_stage2 <= 1'b0;
        end else begin
            inverted_data_stage2 <= ~data_stage1;
            all_ones_flag_stage2 <= all_ones_detected_stage1;
        end
    end
    
    // 输出级：根据标志位选择最终结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_out <= 32'h0;
        end else begin
            result_out <= all_ones_flag_stage2 ? 32'h00000000 : inverted_data_stage2;
        end
    end
endmodule