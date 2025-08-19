//SystemVerilog
module ecc_signal_recovery (
    input wire clock,
    input wire [6:0] encoded_data,
    output reg [3:0] corrected_data,
    output reg error_detected
);
    // Register encoded data to reduce input pin loading
    reg [6:0] encoded_data_reg;
    always @(posedge clock) begin
        encoded_data_reg <= encoded_data;
    end
    
    // Extract and buffer data bits in a more balanced way
    // First stage registers - direct from input
    reg p1_s1, p2_s1, d1_s1, p3_s1, d2_s1, d3_s1, d4_s1;
    always @(posedge clock) begin
        p1_s1 <= encoded_data_reg[0]; // p1
        p2_s1 <= encoded_data_reg[1]; // p2
        d1_s1 <= encoded_data_reg[2]; // d1
        p3_s1 <= encoded_data_reg[3]; // p3
        d2_s1 <= encoded_data_reg[4]; // d2
        d3_s1 <= encoded_data_reg[5]; // d3
        d4_s1 <= encoded_data_reg[6]; // d4
    end
    
    // Partial syndrome calculation - break into smaller chunks
    // This reduces the critical path by parallelizing operations
    reg p1_xor_d1, d2_xor_d4;
    reg p2_xor_d1, d3_xor_d4;
    reg p3_xor_d2, d3_xor_d4_c3;
    
    always @(posedge clock) begin
        // Split XOR operations for c1 into two balanced paths
        p1_xor_d1 <= p1_s1 ^ d1_s1;
        d2_xor_d4 <= d2_s1 ^ d4_s1;
        
        // Split XOR operations for c2 into two balanced paths
        p2_xor_d1 <= p2_s1 ^ d1_s1;
        d3_xor_d4 <= d3_s1 ^ d4_s1;
        
        // Split XOR operations for c3 into two balanced paths
        p3_xor_d2 <= p3_s1 ^ d2_s1;
        d3_xor_d4_c3 <= d3_s1 ^ d4_s1;
    end
    
    // Complete syndrome calculation with balanced paths
    reg c1, c2, c3;
    always @(posedge clock) begin
        c1 <= p1_xor_d1 ^ d2_xor_d4;
        c2 <= p2_xor_d1 ^ d3_xor_d4;
        c3 <= p3_xor_d2 ^ d3_xor_d4_c3;
    end
    
    // Pre-calculate all possible corrections in parallel
    // This removes the case statement from the critical path
    reg [3:0] data_no_correction;
    reg [3:0] data_d1_correction;
    reg [3:0] data_d2_correction;
    reg [3:0] data_d3_correction;
    reg [3:0] data_d4_correction;
    
    always @(posedge clock) begin
        // Register data bits for correction
        data_no_correction <= {d4_s1, d3_s1, d2_s1, d1_s1};
        data_d1_correction <= {d4_s1, d3_s1, d2_s1, ~d1_s1};
        data_d2_correction <= {d4_s1, d3_s1, ~d2_s1, d1_s1};
        data_d3_correction <= {d4_s1, ~d3_s1, d2_s1, d1_s1};
        data_d4_correction <= {~d4_s1, d3_s1, d2_s1, d1_s1};
    end
    
    // Register syndrome for error detection and correction selection
    reg [2:0] syndrome;
    always @(posedge clock) begin
        syndrome <= {c3, c2, c1};
        error_detected <= c1 | c2 | c3; // Optimized OR calculation
    end
    
    // Final mux stage - select the appropriate correction based on syndrome
    // Pre-decoded logic reduces critical path
    always @(posedge clock) begin
        case (syndrome)
            3'b000, 3'b001, 3'b010, 3'b100: 
                corrected_data <= data_no_correction;  // No data error or parity error
            3'b011: 
                corrected_data <= data_d1_correction;  // d1 error
            3'b101: 
                corrected_data <= data_d2_correction;  // d2 error
            3'b110: 
                corrected_data <= data_d3_correction;  // d3 error
            3'b111: 
                corrected_data <= data_d4_correction;  // d4 error
        endcase
    end
endmodule