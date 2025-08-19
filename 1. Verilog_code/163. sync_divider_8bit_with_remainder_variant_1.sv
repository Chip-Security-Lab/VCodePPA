//SystemVerilog
module sync_divider_8bit_with_remainder (
    input clk,
    input reset,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

    reg [7:0] dividend;
    reg [7:0] divisor;
    reg [7:0] temp_quotient;
    reg [7:0] temp_remainder;
    reg [3:0] count;
    reg state;
    
    // Pipeline registers
    reg [7:0] temp_remainder_pipe;
    reg [7:0] temp_quotient_pipe;
    reg [3:0] count_pipe;
    reg comparison_result;
    reg [7:0] subtraction_result;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 8'b0;
            remainder <= 8'b0;
            dividend <= 8'b0;
            divisor <= 8'b0;
            temp_quotient <= 8'b0;
            temp_remainder <= 8'b0;
            count <= 4'b0;
            state <= 1'b0;
            temp_remainder_pipe <= 8'b0;
            temp_quotient_pipe <= 8'b0;
            count_pipe <= 4'b0;
            comparison_result <= 1'b0;
            subtraction_result <= 8'b0;
        end else begin
            if (state == 1'b0) begin
                dividend <= a;
                divisor <= b;
                temp_quotient <= 8'b0;
                temp_remainder <= 8'b0;
                count <= 4'd7;
                state <= 1'b1;
            end else begin
                if (count > 4'b0) begin
                    // Stage 1: Shift and comparison
                    temp_remainder_pipe <= {temp_remainder[6:0], dividend[count]};
                    comparison_result <= (temp_remainder >= divisor);
                    count_pipe <= count;
                    temp_quotient_pipe <= temp_quotient;
                    
                    // Stage 2: Subtraction and quotient update
                    if (comparison_result) begin
                        subtraction_result <= temp_remainder_pipe - divisor;
                        temp_quotient[count_pipe] <= 1'b1;
                    end else begin
                        subtraction_result <= temp_remainder_pipe;
                    end
                    
                    temp_remainder <= subtraction_result;
                    count <= count_pipe - 1'b1;
                end else begin
                    quotient <= temp_quotient;
                    remainder <= temp_remainder;
                    state <= 1'b0;
                end
            end
        end
    end

endmodule