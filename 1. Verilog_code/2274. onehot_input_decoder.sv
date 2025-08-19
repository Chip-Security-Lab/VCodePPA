module onehot_input_decoder(
    input [7:0] onehot_in,
    output reg [2:0] binary_out,
    output reg valid
);
    always @(*) begin
        valid = 1'b1;
        case (onehot_in)
            8'b00000001: binary_out = 3'b000;
            8'b00000010: binary_out = 3'b001;
            8'b00000100: binary_out = 3'b010;
            8'b00001000: binary_out = 3'b011;
            8'b00010000: binary_out = 3'b100;
            8'b00100000: binary_out = 3'b101;
            8'b01000000: binary_out = 3'b110;
            8'b10000000: binary_out = 3'b111;
            default: begin binary_out = 3'b000; valid = 1'b0; end
        endcase
    end
endmodule