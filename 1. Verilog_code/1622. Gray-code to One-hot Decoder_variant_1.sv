//SystemVerilog
// Gray code decoder module
module gray_decoder (
    input [2:0] gray_in,
    output reg [2:0] binary_out
);
    always @(*) begin
        binary_out[2] = gray_in[2];
        binary_out[1] = gray_in[2] ^ gray_in[1];
        binary_out[0] = gray_in[2] ^ gray_in[1] ^ gray_in[0];
    end
endmodule

// Binary to one-hot encoder module
module binary_to_onehot (
    input [2:0] binary_in,
    output reg [7:0] onehot_out
);
    always @(*) begin
        case(binary_in)
            3'b000: onehot_out = 8'b00000001;
            3'b001: onehot_out = 8'b00000010;
            3'b010: onehot_out = 8'b00000100;
            3'b011: onehot_out = 8'b00001000;
            3'b100: onehot_out = 8'b00010000;
            3'b101: onehot_out = 8'b00100000;
            3'b110: onehot_out = 8'b01000000;
            3'b111: onehot_out = 8'b10000000;
            default: onehot_out = 8'b00000000;
        endcase
    end
endmodule

// Top level module
module gray_to_onehot (
    input [2:0] gray_in,
    output [7:0] onehot_out
);
    wire [2:0] binary;
    
    gray_decoder decoder (
        .gray_in(gray_in),
        .binary_out(binary)
    );
    
    binary_to_onehot encoder (
        .binary_in(binary),
        .onehot_out(onehot_out)
    );
endmodule