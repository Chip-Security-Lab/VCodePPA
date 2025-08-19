// Bit manipulation submodule with optimized implementation
module bit_manipulator(
    input [2:0] bin,
    output reg [7:0] shifted_value
);
    always @(*) begin
        case(bin)
            3'b000: shifted_value = 8'b00000001;
            3'b001: shifted_value = 8'b00000010;
            3'b010: shifted_value = 8'b00000100;
            3'b011: shifted_value = 8'b00001000;
            3'b100: shifted_value = 8'b00010000;
            3'b101: shifted_value = 8'b00100000;
            3'b110: shifted_value = 8'b01000000;
            3'b111: shifted_value = 8'b10000000;
            default: shifted_value = 8'b00000001;
        endcase
    end
endmodule

// Optimized thermometer code generator
module thermometer_generator(
    input [7:0] shifted_value,
    output reg [7:0] th_code
);
    always @(*) begin
        th_code = shifted_value - 1'b1;
    end
endmodule

// Top-level module with optimized structure
module thermometer_encoder(
    input [2:0] bin,
    output [7:0] th_code
);
    wire [7:0] shifted_value;
    
    bit_manipulator bit_manip_inst(
        .bin(bin),
        .shifted_value(shifted_value)
    );
    
    thermometer_generator th_gen_inst(
        .shifted_value(shifted_value),
        .th_code(th_code)
    );
endmodule