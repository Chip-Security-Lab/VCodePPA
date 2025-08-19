module and_or (
    input  wire a,
    input  wire b,
    input  wire c,
    input  wire d,
    input  wire clk,
    input  wire rst_n,
    output reg  y
);

    // 第一级流水线：与门运算
    reg stage1_and;
    
    // 第二级流水线：或门运算
    reg stage2_or;
    
    // 第三级流水线：异或运算
    reg stage3_xor;
    
    // 第一级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_and <= 1'b0;
        end else begin
            stage1_and <= a & b;
        end
    end
    
    // 第二级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_or <= 1'b0;
        end else begin
            stage2_or <= c | d;
        end
    end
    
    // 第三级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_xor <= 1'b0;
        end else begin
            stage3_xor <= stage1_and ^ stage2_or;
        end
    end
    
    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 1'b0;
        end else begin
            y <= stage3_xor;
        end
    end

endmodule