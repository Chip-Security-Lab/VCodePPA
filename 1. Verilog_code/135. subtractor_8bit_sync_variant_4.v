module subtractor_8bit_sync (
    input clk,
    input reset,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] diff
);

    // 输入寄存器子模块
    reg [7:0] a_reg, b_reg;
    
    // 减法运算子模块
    wire [7:0] diff_wire;
    
    // 输入寄存器控制
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end
    
    // 减法运算
    assign diff_wire = a_reg - b_reg;
    
    // 输出寄存器控制
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            diff <= 8'b0;
        end else begin
            diff <= diff_wire;
        end
    end

endmodule