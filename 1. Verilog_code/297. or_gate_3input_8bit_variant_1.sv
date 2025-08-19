//SystemVerilog
module or_gate_3input_8bit (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [7:0] c,
    output reg [7:0] y
);
    // 组合逻辑直接计算
    wire [7:0] a_or_b = a | b;
    wire [7:0] final_result = a_or_b | c;
    
    // 第一级流水线：直接存储组合逻辑结果
    reg [7:0] result_reg1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg1 <= 8'b0;
        end else begin
            result_reg1 <= final_result;
        end
    end
    
    // 第二级流水线
    reg [7:0] result_reg2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg2 <= 8'b0;
        end else begin
            result_reg2 <= result_reg1;
        end
    end
    
    // 第三级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 8'b0;
        end else begin
            y <= result_reg2;
        end
    end
    
endmodule