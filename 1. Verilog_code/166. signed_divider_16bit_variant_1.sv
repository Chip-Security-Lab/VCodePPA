//SystemVerilog
module signed_divider_16bit (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    output reg ready_in,
    input wire signed [15:0] dividend,
    input wire signed [15:0] divisor,
    output reg valid_out,
    input wire ready_out,
    output reg signed [15:0] quotient,
    output reg signed [15:0] remainder
);

    // Pipeline stage 1: Input processing and division core
    reg signed [15:0] dividend_abs;
    reg signed [15:0] divisor_abs;
    reg sign_quotient;
    reg sign_remainder;
    reg [31:0] dividend_ext;
    reg [15:0] divisor_reg;
    reg [4:0] counter;
    reg [31:0] partial_remainder;
    reg [15:0] quotient_temp;
    reg valid_stage1;

    // Pipeline stage 2: Output processing
    reg signed [15:0] quotient_abs;
    reg signed [15:0] remainder_abs;
    reg valid_stage2;

    // Stage 1: Input processing and division core
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dividend_abs <= 16'd0;
            divisor_abs <= 16'd0;
            sign_quotient <= 1'b0;
            sign_remainder <= 1'b0;
            dividend_ext <= 32'd0;
            divisor_reg <= 16'd0;
            counter <= 5'd0;
            partial_remainder <= 32'd0;
            quotient_temp <= 16'd0;
            valid_stage1 <= 1'b0;
            ready_in <= 1'b1;
        end else begin
            if (valid_in && ready_in) begin
                dividend_abs <= (dividend[15]) ? -dividend : dividend;
                divisor_abs <= (divisor[15]) ? -divisor : divisor;
                sign_quotient <= dividend[15] ^ divisor[15];
                sign_remainder <= dividend[15];
                dividend_ext <= {16'd0, (dividend[15]) ? -dividend : dividend};
                divisor_reg <= (divisor[15]) ? -divisor : divisor;
                counter <= 5'd16;
                partial_remainder <= 32'd0;
                quotient_temp <= 16'd0;
                valid_stage1 <= 1'b1;
                ready_in <= 1'b0;
            end else if (valid_stage1) begin
                if (counter == 5'd0) begin
                    valid_stage1 <= 1'b0;
                    valid_stage2 <= 1'b1;
                end else begin
                    partial_remainder <= {partial_remainder[30:0], dividend_ext[15]};
                    dividend_ext <= dividend_ext << 1;
                    
                    if (partial_remainder >= {16'd0, divisor_reg}) begin
                        partial_remainder <= partial_remainder - {16'd0, divisor_reg};
                        quotient_temp <= {quotient_temp[14:0], 1'b1};
                    end else begin
                        quotient_temp <= {quotient_temp[14:0], 1'b0};
                    end
                    
                    counter <= counter - 5'd1;
                end
            end else if (!valid_stage1 || ready_in) begin
                ready_in <= 1'b1;
            end
        end
    end

    // Stage 2: Output processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quotient_abs <= 16'd0;
            remainder_abs <= 16'd0;
            quotient <= 16'd0;
            remainder <= 16'd0;
            valid_out <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage2) begin
                quotient_abs <= quotient_temp;
                remainder_abs <= partial_remainder[15:0];
                quotient <= sign_quotient ? -quotient_abs : quotient_abs;
                remainder <= sign_remainder ? -remainder_abs : remainder_abs;
                valid_out <= 1'b1;
                valid_stage2 <= 1'b0;
            end else if (valid_out && ready_out) begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule