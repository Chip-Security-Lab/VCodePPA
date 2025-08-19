module demux_1to4_case (
    input wire din,              // Data input
    input wire [1:0] select,     // 2-bit selection control
    output reg [3:0] dout        // 4-bit output bus
);
    always @(*) begin
        dout = 4'b0000;          // Default all outputs to zero
        case(select)
            2'b00: dout[0] = din;
            2'b01: dout[1] = din;
            2'b10: dout[2] = din;
            2'b11: dout[3] = din;
        endcase
    end
endmodule