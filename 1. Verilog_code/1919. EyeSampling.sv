module EyeSampling #(parameter SAMPLE_OFFSET=3) (
    input clk,
    input serial_in,
    output reg recovered_bit
);
    reg [7:0] shift_reg;
    always @(posedge clk) begin
        shift_reg <= {shift_reg[6:0], serial_in};
        recovered_bit <= shift_reg[SAMPLE_OFFSET];
    end
endmodule
