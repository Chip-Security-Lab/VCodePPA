module signed_divider_8bit (
    input wire clk,
    input wire rst_n,
    input signed [7:0] a,
    input signed [7:0] b,
    output reg signed [7:0] quotient,
    output reg signed [7:0] remainder
);

    reg signed [7:0] dividend;
    reg signed [7:0] divisor;
    reg signed [7:0] quotient_temp;
    reg [3:0] count;
    reg sign_flag;
    wire signed [7:0] abs_a;
    wire signed [7:0] abs_b;
    wire signed [7:0] next_dividend;
    wire signed [7:0] next_quotient;
    
    assign abs_a = (a[7]) ? -a : a;
    assign abs_b = (b[7]) ? -b : b;
    assign next_dividend = (dividend >= divisor) ? ((dividend << 1) - divisor) : (dividend << 1);
    assign next_quotient = (dividend >= divisor) ? ((quotient_temp << 1) + 1'b1) : (quotient_temp << 1);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dividend <= 8'd0;
            divisor <= 8'd0;
            quotient_temp <= 8'd0;
            count <= 4'd0;
            sign_flag <= 1'b0;
            quotient <= 8'd0;
            remainder <= 8'd0;
        end else begin
            case (count)
                4'd0: begin
                    sign_flag <= (a[7] ^ b[7]);
                    dividend <= abs_a;
                    divisor <= abs_b;
                    quotient_temp <= 8'd0;
                    count <= count + 1'b1;
                end
                4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8: begin
                    dividend <= next_dividend;
                    quotient_temp <= next_quotient;
                    count <= count + 1'b1;
                end
                default: begin
                    quotient <= sign_flag ? -quotient_temp : quotient_temp;
                    remainder <= (a[7]) ? -dividend : dividend;
                    count <= 4'd0;
                end
            endcase
        end
    end

endmodule