module ecc_signal_recovery (
    input wire clock,
    input wire [6:0] encoded_data,
    output reg [3:0] corrected_data,
    output reg error_detected
);
    wire p1 = encoded_data[0];
    wire p2 = encoded_data[1];
    wire d1 = encoded_data[2];
    wire p3 = encoded_data[3];
    wire d2 = encoded_data[4];
    wire d3 = encoded_data[5];
    wire d4 = encoded_data[6];
    
    wire c1 = p1 ^ d1 ^ d2 ^ d4;
    wire c2 = p2 ^ d1 ^ d3 ^ d4;
    wire c3 = p3 ^ d2 ^ d3 ^ d4;
    wire [2:0] syndrome = {c3, c2, c1};
    
    always @(posedge clock) begin
        error_detected <= |syndrome;
        case (syndrome)
            3'b000: corrected_data <= {d4, d3, d2, d1};
            3'b001: corrected_data <= {d4, d3, d2, d1};  // p1 error
            3'b010: corrected_data <= {d4, d3, d2, d1};  // p2 error
            3'b011: corrected_data <= {d4, d3, d2, ~d1}; // d1 error
            3'b100: corrected_data <= {d4, d3, d2, d1};  // p3 error
            3'b101: corrected_data <= {d4, d3, ~d2, d1}; // d2 error
            3'b110: corrected_data <= {d4, ~d3, d2, d1}; // d3 error
            3'b111: corrected_data <= {~d4, d3, d2, d1}; // d4 error
        endcase
    end
endmodule