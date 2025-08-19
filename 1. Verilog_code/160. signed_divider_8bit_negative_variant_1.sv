//SystemVerilog
module signed_divider_8bit_negative (
    input wire clk,
    input wire rst_n,
    input signed [7:0] dividend,
    input signed [7:0] divisor,
    output reg signed [7:0] quotient,
    output reg signed [7:0] remainder
);

    reg signed [7:0] dividend_abs;
    reg signed [7:0] divisor_abs;
    reg sign_quotient;
    reg sign_remainder;
    reg [7:0] partial_remainder;
    reg [7:0] partial_quotient;
    reg [3:0] iteration_count;
    reg signed [7:0] quotient_abs;
    reg signed [7:0] remainder_abs;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dividend_abs <= 8'd0;
            divisor_abs <= 8'd0;
            sign_quotient <= 1'b0;
            sign_remainder <= 1'b0;
        end else begin
            if (dividend[7]) begin
                dividend_abs <= -dividend;
            end else begin
                dividend_abs <= dividend;
            end
            
            if (divisor[7]) begin
                divisor_abs <= -divisor;
            end else begin
                divisor_abs <= divisor;
            end
            
            sign_quotient <= dividend[7] ^ divisor[7];
            sign_remainder <= dividend[7];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            partial_remainder <= 8'd0;
            partial_quotient <= 8'd0;
            iteration_count <= 4'd0;
        end else begin
            if (iteration_count == 4'd0) begin
                partial_remainder <= dividend_abs;
                partial_quotient <= 8'd0;
                iteration_count <= iteration_count + 1;
            end else if (iteration_count < 4'd8) begin
                if (partial_remainder >= divisor_abs) begin
                    partial_remainder <= partial_remainder - divisor_abs;
                    partial_quotient <= {partial_quotient[6:0], 1'b1};
                end else begin
                    partial_quotient <= {partial_quotient[6:0], 1'b0};
                end
                partial_remainder <= {partial_remainder[6:0], 1'b0};
                iteration_count <= iteration_count + 1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quotient_abs <= 8'd0;
            remainder_abs <= 8'd0;
            quotient <= 8'd0;
            remainder <= 8'd0;
        end else begin
            if (iteration_count == 4'd8) begin
                quotient_abs <= partial_quotient;
                remainder_abs <= partial_remainder >> 1;
                
                if (sign_quotient) begin
                    quotient <= -quotient_abs;
                end else begin
                    quotient <= quotient_abs;
                end
                
                if (sign_remainder) begin
                    remainder <= -remainder_abs;
                end else begin
                    remainder <= remainder_abs;
                end
            end
        end
    end

endmodule