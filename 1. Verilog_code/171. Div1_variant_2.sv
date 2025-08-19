//SystemVerilog
module Div1(
    input clk,
    input rst_n,
    input [7:0] dividend,
    input [7:0] divisor,
    output reg [7:0] quotient
);

    reg [7:0] x0, x1;
    reg [15:0] temp;
    reg [2:0] iter;
    reg [2:0] iter_buf;
    reg valid;
    reg [7:0] h0;
    reg [7:0] h0_buf;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x0 <= 8'h0;
            x1 <= 8'h0;
            temp <= 16'h0;
            iter <= 3'h0;
            iter_buf <= 3'h0;
            valid <= 1'b0;
            quotient <= 8'hFF;
            h0 <= 8'h0;
            h0_buf <= 8'h0;
        end else begin
            if (divisor == 8'h0) begin
                quotient <= 8'hFF;
                valid <= 1'b1;
            end else if (!valid) begin
                if (iter == 3'h0) begin
                    x0 <= 8'h80;
                    iter <= iter + 1;
                end else if (iter < 3'h4) begin
                    h0 <= divisor * x0;
                    h0_buf <= h0;
                    temp <= x0 * (16'h100 - h0_buf);
                    x1 <= temp[15:8];
                    x0 <= x1;
                    iter_buf <= iter;
                    iter <= iter_buf + 1;
                end else begin
                    quotient <= dividend * x1;
                    valid <= 1'b1;
                end
            end
        end
    end

endmodule