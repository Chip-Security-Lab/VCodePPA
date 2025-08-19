//SystemVerilog
module salsa20_qround_pipe (
    input wire clk, 
    input wire en,
    input wire [31:0] a, b, c, d,
    output reg [31:0] a_out, d_out
);
    reg [31:0] addition_result;
    reg [31:0] rotated_result;
    reg [31:0] stage1_result;
    reg [31:0] stage2_result;
    
    always @(posedge clk) begin
        if (en) begin
            // 优化阶段1：提前计算加法结果并分开位移操作，减少关键路径
            addition_result <= a + d;
            rotated_result <= {addition_result[24:0], addition_result[31:25]}; // 左旋7位
            stage1_result <= b + rotated_result;
            
            // 优化阶段2：使用预计算值并分开操作
            addition_result <= stage1_result + a;
            rotated_result <= {addition_result[22:0], addition_result[31:23]}; // 左旋9位
            stage2_result <= c ^ rotated_result;
            
            // 最终输出
            a_out <= a ^ stage2_result;
            d_out <= d + stage2_result;
        end
    end
endmodule