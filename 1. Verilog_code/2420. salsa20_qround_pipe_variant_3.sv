//SystemVerilog
module salsa20_qround_pipe (
    input wire clk,
    input wire rst,  // 添加复位信号
    input wire valid_in,
    output wire ready_out,
    input wire [31:0] a, b, c, d,
    output reg [31:0] a_out, d_out,
    output reg valid_out,
    input wire ready_in
);
    // IEEE 1364-2005 Verilog标准

    // 扩展为5级流水线
    reg [31:0] a_stage1, a_stage2, a_stage3, a_stage4;
    reg [31:0] d_stage1, d_stage2, d_stage3, d_stage4;
    
    reg [31:0] sum1_stage1;         // a + d 的结果
    reg [31:0] shifted_sum1_stage2; // (a + d) <<< 7 的结果
    reg [31:0] b_plus_stage3;       // b + ((a + d) <<< 7) 的结果
    
    reg [31:0] sum2_stage3;         // stage1 + a 的结果
    reg [31:0] shifted_sum2_stage4; // (stage1 + a) <<< 9 的结果
    reg [31:0] c_xor_stage5;        // c ^ ((stage1 + a) <<< 9) 的结果
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4, valid_stage5;
    reg processing;
    
    // 当模块空闲或输出被接收时，表示可以接收新数据
    assign ready_out = !processing || (valid_out && ready_in);
    
    always @(posedge clk) begin
        if (rst) begin
            // 复位所有状态
            processing <= 1'b0;
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
            valid_stage4 <= 1'b0;
            valid_stage5 <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            // 第1阶段：计算 a + d
            if (valid_in && ready_out) begin
                processing <= 1'b1;
                a_stage1 <= a;
                d_stage1 <= d;
                sum1_stage1 <= a + d;
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= valid_stage1 && !valid_stage2;
            end
            
            // 第2阶段：计算 (a + d) <<< 7
            if (valid_stage1) begin
                a_stage2 <= a_stage1;
                d_stage2 <= d_stage1;
                shifted_sum1_stage2 <= sum1_stage1 <<< 7;
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= valid_stage2 && !valid_stage3;
            end
            
            // 第3阶段：计算 b + ((a + d) <<< 7) 和 保存 stage1 + a 结果
            if (valid_stage2) begin
                a_stage3 <= a_stage2;
                d_stage3 <= d_stage2;
                b_plus_stage3 <= b + shifted_sum1_stage2;
                sum2_stage3 <= b + shifted_sum1_stage2 + a_stage2;
                valid_stage3 <= 1'b1;
            end else begin
                valid_stage3 <= valid_stage3 && !valid_stage4;
            end
            
            // 第4阶段：计算 (b_plus + a) <<< 9
            if (valid_stage3) begin
                a_stage4 <= a_stage3;
                d_stage4 <= d_stage3;
                shifted_sum2_stage4 <= sum2_stage3 <<< 9;
                valid_stage4 <= 1'b1;
            end else begin
                valid_stage4 <= valid_stage4 && !valid_stage5;
            end
            
            // 第5阶段：计算 c ^ ((b_plus + a) <<< 9)
            if (valid_stage4) begin
                c_xor_stage5 <= c ^ shifted_sum2_stage4;
                valid_stage5 <= 1'b1;
            end else begin
                valid_stage5 <= valid_stage5 && !valid_out;
            end
            
            // 输出阶段：计算最终的a_out和d_out
            if (valid_stage5 && !valid_out) begin
                a_out <= a_stage4 ^ c_xor_stage5;
                d_out <= d_stage4 + c_xor_stage5;
                valid_out <= 1'b1;
            end else if (valid_out && ready_in) begin
                valid_out <= 1'b0;
                if (!valid_in && !valid_stage1 && !valid_stage2 && !valid_stage3 && !valid_stage4 && !valid_stage5) begin
                    processing <= 1'b0;
                end
            end
        end
    end
endmodule