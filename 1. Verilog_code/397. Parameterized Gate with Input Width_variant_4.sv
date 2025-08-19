//SystemVerilog
module nand2_17 #(
    parameter WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] A, B,
    output reg [WIDTH-1:0] Y
);
    // 分段处理，提高数据流的清晰度
    reg [WIDTH-1:0] a_reg, b_reg;
    reg [WIDTH-1:0] and_result;
    
    // A输入寄存器阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= {WIDTH{1'b0}};
        end else begin
            a_reg <= A;
        end
    end
    
    // B输入寄存器阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b_reg <= {WIDTH{1'b0}};
        end else begin
            b_reg <= B;
        end
    end
    
    // 第一阶段逻辑：与操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result <= {WIDTH{1'b0}};
        end else begin
            and_result <= a_reg & b_reg;
        end
    end
    
    // 第二阶段逻辑：非操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= {WIDTH{1'b1}};
        end else begin
            Y <= ~and_result;
        end
    end
    
endmodule