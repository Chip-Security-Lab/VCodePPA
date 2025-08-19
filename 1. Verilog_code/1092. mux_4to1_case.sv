module mux_4to1_case (
    input wire [1:0] sel,         // 2-bit selection lines
    input wire [7:0] in0, in1, in2, in3, // Data inputs
    output reg [7:0] data_out     // Output data
);
    always @(*) begin
        case(sel)
            2'b00: data_out = in0;
            2'b01: data_out = in1;
            2'b10: data_out = in2;
            2'b11: data_out = in3;
        endcase
    end
endmodule