//SystemVerilog
module pipelined_matcher #(parameter WIDTH = 8) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in, pattern,
    output reg match_out
);
    reg [WIDTH-1:0] data_reg;
    reg [(WIDTH/2)-1:0] partial_match_stage1;
    reg [1:0] partial_match_stage2;
    reg comp_result;
    
    // 内部信号用于并行前缀比较
    wire [WIDTH-1:0] xnor_result;
    
    // 生成XNOR结果 - 相同位产生1，不同位产生0
    assign xnor_result = ~(data_reg ^ pattern);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 0;
            partial_match_stage1 <= 0;
            partial_match_stage2 <= 0;
            comp_result <= 0;
            match_out <= 0;
        end else begin
            data_reg <= data_in;
            
            // 第一级并行规约 - 将8位分为4组
            partial_match_stage1[0] <= xnor_result[0] & xnor_result[1];
            partial_match_stage1[1] <= xnor_result[2] & xnor_result[3];
            partial_match_stage1[2] <= xnor_result[4] & xnor_result[5];
            partial_match_stage1[3] <= xnor_result[6] & xnor_result[7];
            
            // 第二级并行规约 - 将4组合并为2组
            partial_match_stage2[0] <= partial_match_stage1[0] & partial_match_stage1[1];
            partial_match_stage2[1] <= partial_match_stage1[2] & partial_match_stage1[3];
            
            // 最终比较结果
            comp_result <= partial_match_stage2[0] & partial_match_stage2[1];
            
            // 输出结果
            match_out <= comp_result;
        end
    end
endmodule