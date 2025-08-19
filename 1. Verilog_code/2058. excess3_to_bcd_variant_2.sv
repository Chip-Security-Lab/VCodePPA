//SystemVerilog
module excess3_to_bcd (
    input wire [3:0] excess3_in,
    output reg [3:0] bcd_out,
    output reg valid_out
);
    wire input_valid_range;
    assign input_valid_range = (excess3_in[3] == 1'b1) || (excess3_in[2:0] >= 3'b011);

    reg [3:0] conditional_sum;
    reg carry0, carry1, carry2, carry3;

    always @(*) begin
        // Conditional Sum Subtraction (A - B) => (A + (~B + 1))
        // Here, B = 4'h3 = 4'b0011
        // Compute ~B = 4'b1100
        // So, sum = excess3_in + 4'b1101 (because ~B + 1 = 4'b1101)
        {carry3, conditional_sum[3]} = excess3_in[3] + 1'b1 + 1'b1; // MSB + ~B[3] + carry_in
        {carry2, conditional_sum[2]} = excess3_in[2] + 1'b1 + carry3; // + ~B[2]
        {carry1, conditional_sum[1]} = excess3_in[1] + 1'b0 + carry2; // + ~B[1]
        {carry0, conditional_sum[0]} = excess3_in[0] + 1'b1 + carry1; // + ~B[0]
        
        if (input_valid_range && (excess3_in <= 4'hC)) begin
            bcd_out = conditional_sum;
            valid_out = 1'b1;
        end else begin
            bcd_out = 4'h0;
            valid_out = 1'b0;
        end
    end
endmodule