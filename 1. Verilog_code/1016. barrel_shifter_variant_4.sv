//SystemVerilog
module barrel_shifter #(parameter N=8) (
    input  wire [N-1:0] in,
    input  wire [$clog2(N)-1:0] shift,
    output reg  [N-1:0] out
);
    wire [$clog2(N)-1:0] shift_mod;
    wire [N-1:0] left_part, right_part;
    assign shift_mod = shift % N;

    assign left_part  = in << shift_mod;
    assign right_part = in >> (N - shift_mod);

    always @* begin
        if (shift_mod == 0) begin
            out = in;
        end else begin
            out = left_part | right_part;
        end
    end
endmodule