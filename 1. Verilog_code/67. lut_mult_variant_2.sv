//SystemVerilog
module lut_mult (
    input clk,
    input rst_n,
    input valid,
    input [3:0] a,
    input [3:0] b,
    output reg ready,
    output reg [7:0] product
);

    reg [7:0] product_reg;
    reg valid_reg;
    wire [7:0] a_ext = {4'b0, a};
    wire [7:0] b_ext = {4'b0, b};
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready <= 1'b0;
            product <= 8'h00;
            product_reg <= 8'h00;
            valid_reg <= 1'b0;
        end else begin
            if (valid && !valid_reg) begin
                product_reg <= a_ext * b_ext;
                valid_reg <= 1'b1;
                ready <= 1'b1;
            end else if (ready) begin
                product <= product_reg;
                ready <= 1'b0;
                valid_reg <= 1'b0;
            end
        end
    end
endmodule