//SystemVerilog
module SmallMultiplier(
    input clk,
    input rst_n,
    input [1:0] a,
    input [1:0] b, 
    output reg [3:0] prod
);

    // Pipeline stage 1: Input registers
    reg [1:0] a_reg, b_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 2'b0;
            b_reg <= 2'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    // Pipeline stage 2: Multiplication
    reg [3:0] mult_result;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mult_result <= 4'b0;
        end else begin
            mult_result <= a_reg * b_reg;
        end
    end

    // Pipeline stage 3: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prod <= 4'b0;
        end else begin
            prod <= mult_result;
        end
    end

endmodule