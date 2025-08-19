//SystemVerilog
module hamming_decoder (
    input  wire [6:0] encoded_in,
    output reg  [3:0] decoded_out,
    output wire       error_detected,
    output wire       error_corrected
);
    wire [2:0] syndrome;
    wire [6:0] corrected_code;
    
    syndrome_calc SYNDROME (
        .encoded_in(encoded_in),
        .syndrome(syndrome)
    );
    
    error_detect ERROR (
        .syndrome(syndrome),
        .error_detected(error_detected),
        .error_corrected(error_corrected)
    );
    
    error_correct CORRECT (
        .encoded_in(encoded_in),
        .syndrome(syndrome),
        .corrected_code(corrected_code)
    );
    
    data_extract EXTRACT (
        .corrected_code(corrected_code),
        .decoded_out(decoded_out)
    );
endmodule

module syndrome_calc (
    input  wire [6:0] encoded_in,
    output wire [2:0] syndrome
);
    wire p1 = encoded_in[0];
    wire p2 = encoded_in[1];
    wire d1 = encoded_in[2];
    wire p4 = encoded_in[3];
    wire d2 = encoded_in[4];
    wire d3 = encoded_in[5];
    wire d4 = encoded_in[6];
    
    assign syndrome[0] = p1 ^ d1 ^ d2 ^ d4;
    assign syndrome[1] = p2 ^ d1 ^ d3 ^ d4;
    assign syndrome[2] = p4 ^ d2 ^ d3 ^ d4;
endmodule

module error_detect (
    input  wire [2:0] syndrome,
    output wire       error_detected,
    output wire       error_corrected
);
    assign error_detected = |syndrome;
    assign error_corrected = error_detected;
endmodule

module error_correct (
    input  wire [6:0] encoded_in,
    input  wire [2:0] syndrome,
    output wire [6:0] corrected_code
);
    wire [6:0] booth_mult_result;
    booth_multiplier #(.WIDTH(7)) BOOTH_MULT (
        .a(encoded_in),
        .b({4'b0, syndrome}),
        .result(booth_mult_result)
    );
    
    assign corrected_code = booth_mult_result;
endmodule

module booth_multiplier #(
    parameter WIDTH = 7
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] result
);
    reg [WIDTH-1:0] P;
    reg [WIDTH-1:0] A;
    reg [WIDTH-1:0] S;
    reg [WIDTH-1:0] temp;
    integer i;
    
    always @(*) begin
        A = a;
        S = ~a + 1;
        P = {b, 1'b0};
        
        for (i = 0; i < WIDTH; i = i + 1) begin
            case (P[1:0])
                2'b01: temp = P + A;
                2'b10: temp = P + S;
                default: temp = P;
            endcase
            P = {temp[WIDTH-1], temp[WIDTH-1:1]};
        end
    end
    
    assign result = P[WIDTH-1:0];
endmodule

module data_extract (
    input  wire [6:0] corrected_code,
    output reg  [3:0] decoded_out
);
    always @(*) begin
        decoded_out[0] = corrected_code[2];
        decoded_out[1] = corrected_code[4];
        decoded_out[2] = corrected_code[5];
        decoded_out[3] = corrected_code[6];
    end
endmodule