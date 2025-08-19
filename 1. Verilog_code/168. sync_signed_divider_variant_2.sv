//SystemVerilog
module sync_signed_divider (
    input clk,
    input reset,
    input signed [7:0] a,
    input signed [7:0] b,
    output reg signed [7:0] quotient,
    output reg signed [7:0] remainder
);

    // Pipeline stage 1: Input registers and sign handling
    reg signed [7:0] a_stage1, b_stage1;
    reg a_sign_stage1, b_sign_stage1;
    reg [6:0] a_abs_stage1, b_abs_stage1;

    // Pipeline stage 2: Division preparation and iteration
    reg [6:0] a_abs_stage2, b_abs_stage2;
    reg [13:0] dividend_stage2;
    reg [6:0] divisor_stage2;
    reg [3:0] counter_stage2;
    reg [6:0] quotient_stage2;
    reg [6:0] remainder_stage2;

    // Pipeline stage 3: Result assembly
    reg signed [7:0] quotient_stage3;
    reg signed [7:0] remainder_stage3;

    // Stage 1: Input processing
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            a_stage1 <= 0;
            b_stage1 <= 0;
            a_sign_stage1 <= 0;
            b_sign_stage1 <= 0;
            a_abs_stage1 <= 0;
            b_abs_stage1 <= 0;
        end else begin
            a_stage1 <= a;
            b_stage1 <= b;
            a_sign_stage1 <= a[7];
            b_sign_stage1 <= b[7];
            a_abs_stage1 <= a[7] ? -a[6:0] : a[6:0];
            b_abs_stage1 <= b[7] ? -b[6:0] : b[6:0];
        end
    end

    // Stage 2: Division preparation and iteration
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            a_abs_stage2 <= 0;
            b_abs_stage2 <= 0;
            dividend_stage2 <= 0;
            divisor_stage2 <= 0;
            counter_stage2 <= 0;
            quotient_stage2 <= 0;
            remainder_stage2 <= 0;
        end else begin
            if (counter_stage2 == 0) begin
                a_abs_stage2 <= a_abs_stage1;
                b_abs_stage2 <= b_abs_stage1;
                dividend_stage2 <= {7'b0, a_abs_stage1};
                divisor_stage2 <= b_abs_stage1;
                counter_stage2 <= 7;
                quotient_stage2 <= 0;
                remainder_stage2 <= 0;
            end else begin
                dividend_stage2 <= {dividend_stage2[12:0], 1'b0};
                counter_stage2 <= counter_stage2 - 1;
                if (dividend_stage2 >= {7'b0, divisor_stage2}) begin
                    quotient_stage2 <= {quotient_stage2[5:0], 1'b1};
                    remainder_stage2 <= dividend_stage2 - {7'b0, divisor_stage2};
                end else begin
                    quotient_stage2 <= {quotient_stage2[5:0], 1'b0};
                    remainder_stage2 <= dividend_stage2;
                end
            end
        end
    end

    // Stage 3: Result assembly
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient_stage3 <= 0;
            remainder_stage3 <= 0;
        end else begin
            quotient_stage3 <= (a_sign_stage1 ^ b_sign_stage1) ? -quotient_stage2 : quotient_stage2;
            remainder_stage3 <= a_sign_stage1 ? -remainder_stage2 : remainder_stage2;
        end
    end

    // Output assignment
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 0;
            remainder <= 0;
        end else begin
            quotient <= quotient_stage3;
            remainder <= remainder_stage3;
        end
    end

endmodule