module subtractor_8bit_borrow (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    output reg [7:0] diff,
    output reg borrow
);

    // 输入寄存器
    reg [7:0] a_reg;
    reg [7:0] b_reg;
    
    // 中间结果寄存器
    reg [8:0] add_result;
    wire [8:0] b_comp;  // b的补码
    
    // 输入寄存器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end
    
    // 计算b的补码
    assign b_comp = {1'b0, ~b_reg} + 9'b1;
    
    // 补码加法运算逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            add_result <= 9'b0;
        end else begin
            add_result <= {1'b0, a_reg} + b_comp;
        end
    end
    
    // 输出寄存器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff <= 8'b0;
            borrow <= 1'b0;
        end else begin
            diff <= add_result[7:0];
            borrow <= add_result[8];
        end
    end

endmodule