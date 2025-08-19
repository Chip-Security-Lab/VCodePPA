//SystemVerilog
module divider_with_counter (
    input clk,
    input reset,
    input [7:0] a,
    input [7:0] b,
    input valid_in,
    output reg ready_in,
    output reg [7:0] quotient,
    output reg [7:0] remainder,
    output reg valid_out,
    input ready_out
);

    reg [7:0] dividend;
    reg [7:0] divisor;
    reg [3:0] cycle_count;
    reg [7:0] partial_remainder;
    reg [7:0] next_quotient;
    reg [7:0] next_remainder;
    reg [2:0] srt_radix;
    reg busy;
    reg result_ready;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 0;
            remainder <= 0;
            cycle_count <= 0;
            partial_remainder <= 0;
            next_quotient <= 0;
            next_remainder <= 0;
            srt_radix <= 0;
            busy <= 0;
            result_ready <= 0;
            ready_in <= 1'b1;
            valid_out <= 1'b0;
        end else begin
            // Default values
            ready_in <= 1'b1;
            
            // Handle input handshake
            if (valid_in && ready_in && !busy) begin
                dividend <= a;
                divisor <= b;
                partial_remainder <= a;
                srt_radix <= 3'b100;
                cycle_count <= 0;
                busy <= 1'b1;
                result_ready <= 1'b0;
                valid_out <= 1'b0;
            end
            
            // Processing logic
            if (busy) begin
                if (cycle_count < 8) begin
                    if (cycle_count == 0) begin
                        // Initial values already set during input handshake
                    end else begin
                        if (partial_remainder >= (divisor << srt_radix)) begin
                            next_quotient <= quotient | (1'b1 << srt_radix);
                            next_remainder <= partial_remainder - (divisor << srt_radix);
                        end else begin
                            next_quotient <= quotient;
                            next_remainder <= partial_remainder;
                        end
                        partial_remainder <= next_remainder << 1;
                        quotient <= next_quotient;
                        srt_radix <= srt_radix - 1;
                    end
                    cycle_count <= cycle_count + 1;
                end else begin
                    remainder <= partial_remainder;
                    result_ready <= 1'b1;
                    valid_out <= 1'b1;
                end
            end
            
            // Output handshake
            if (valid_out && ready_out) begin
                valid_out <= 1'b0;
                busy <= 1'b0;
                result_ready <= 1'b0;
            end
        end
    end
endmodule