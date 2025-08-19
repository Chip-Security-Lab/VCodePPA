module string_valid_xnor (a_valid, b_valid, data_a, data_b, out);
    input a_valid, b_valid;
    input wire [7:0] data_a, data_b;
    output reg [7:0] out;

    always @(*) begin
        if (a_valid && b_valid) begin
            out = ~(data_a ^ data_b);
        end else begin
            out = 8'b0;
        end
    end
endmodule