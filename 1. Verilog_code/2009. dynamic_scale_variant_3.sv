//SystemVerilog
module dynamic_scale #(parameter W = 24) (
    input  wire [W-1:0] in,
    input  wire [4:0] shift,
    output wire [W-1:0] out
);
    reg [4:0] shift_magnitude;
    reg [W-1:0] out_reg;
    reg [4:0] twos_complement_shift;

    always @* begin
        if (shift[4] == 1'b1) begin
            // Calculate two's complement of shift[3:0] for left shift amount
            twos_complement_shift = (~shift + 5'd1);
            shift_magnitude = twos_complement_shift[3:0];
            out_reg = in << shift_magnitude;
        end else begin
            shift_magnitude = shift[3:0];
            out_reg = in >> shift_magnitude;
        end
    end

    assign out = out_reg;
endmodule