module golomb_encoder #(
    parameter M_POWER = 2  // M = 2^M_POWER
)(
    input             i_clk,
    input             i_enable,
    input      [15:0] i_value,
    output reg        o_valid,
    output reg [31:0] o_code,
    output reg [5:0]  o_len
);
    reg [15:0] quotient, remainder;
    
    always @(posedge i_clk) begin
        if (i_enable) begin
            // Calculate quotient and remainder
            quotient <= i_value >> M_POWER;
            remainder <= i_value & ((1 << M_POWER) - 1);
            
            // Unary code for quotient + binary code for remainder
            o_code <= {{16{1'b1}} >> (16-quotient), 1'b0, remainder};
            o_len <= quotient + 1 + M_POWER;
            o_valid <= 1;
        end else begin
            o_valid <= 0;
        end
    end
endmodule