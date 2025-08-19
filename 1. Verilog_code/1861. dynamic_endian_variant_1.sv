//SystemVerilog
module dynamic_endian #(parameter WIDTH=32) (
    input [WIDTH-1:0] data_in,
    input reverse_en,
    output [WIDTH-1:0] data_out
);

    // Manchester carry chain adder implementation
    wire [WIDTH-1:0] carry;
    wire [WIDTH-1:0] sum;
    
    // Generate carry chain
    genvar i;
    generate
        for(i=0; i<WIDTH; i=i+1) begin: carry_chain
            if(i == 0) begin
                assign carry[i] = reverse_en;
            end else begin
                assign carry[i] = (data_in[i-1] & carry[i-1]) | 
                                (data_in[i-1] & reverse_en) |
                                (carry[i-1] & reverse_en);
            end
        end
    endgenerate

    // Generate sum bits
    generate
        for(i=0; i<WIDTH; i=i+1) begin: sum_bits
            assign sum[i] = data_in[i] ^ carry[i];
        end
    endgenerate

    // Final output selection
    assign data_out = reverse_en ? sum : data_in;

endmodule