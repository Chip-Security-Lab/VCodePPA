//SystemVerilog
module mul_add (
    input clk,
    input rst_n,
    input req,
    output reg ack,
    input [3:0] num1,
    input [3:0] num2,
    output reg [7:0] product,
    output reg [4:0] sum
);

    reg req_d;
    reg [3:0] num1_reg;
    reg [3:0] num2_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_d <= 1'b0;
            ack <= 1'b0;
            num1_reg <= 4'b0;
            num2_reg <= 4'b0;
            product <= 8'b0;
            sum <= 5'b0;
        end else begin
            req_d <= req;
            if (req && !req_d) begin
                num1_reg <= num1;
                num2_reg <= num2;
                product <= num1 * num2;
                sum <= num1 + num2;
                ack <= 1'b1;
            end else if (!req && req_d) begin
                ack <= 1'b0;
            end
        end
    end

endmodule