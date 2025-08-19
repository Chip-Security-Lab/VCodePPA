//SystemVerilog
module ecc_signal_recovery (
    input  wire        clock,
    input  wire [6:0]  encoded_data,
    output reg  [3:0]  corrected_data,
    output reg         error_detected
);
    // Stage 1: Data extraction and parity calculation
    reg [6:0] encoded_data_reg;
    reg [2:0] syndrome_stage1;
    
    // Data extraction
    always @(posedge clock) begin
        encoded_data_reg <= encoded_data;
    end
    
    // Parity bits and data bits
    wire p1 = encoded_data_reg[0];
    wire p2 = encoded_data_reg[1];
    wire d1 = encoded_data_reg[2];
    wire p3 = encoded_data_reg[3];
    wire d2 = encoded_data_reg[4];
    wire d3 = encoded_data_reg[5];
    wire d4 = encoded_data_reg[6];
    
    // Stage 2: Syndrome calculation pipeline
    // Breaking down the XOR operations to reduce logic depth
    reg [3:0] data_bits_reg;
    
    always @(posedge clock) begin
        // Store data bits for later correction
        data_bits_reg <= {d4, d3, d2, d1};
        
        // Calculate syndrome with reduced logic depth
        syndrome_stage1[0] <= p1 ^ (d1 ^ (d2 ^ d4));
        syndrome_stage1[1] <= p2 ^ (d1 ^ (d3 ^ d4));
        syndrome_stage1[2] <= p3 ^ (d2 ^ (d3 ^ d4));
    end
    
    // Stage 3: Error correction
    reg [2:0] syndrome_stage2;
    
    always @(posedge clock) begin
        syndrome_stage2 <= syndrome_stage1;
        error_detected <= |syndrome_stage1;
    end
    
    // Final stage: Data correction based on syndrome
    always @(posedge clock) begin
        case (syndrome_stage2)
            3'b000: corrected_data <= data_bits_reg;                              // No error
            3'b001: corrected_data <= data_bits_reg;                              // p1 error
            3'b010: corrected_data <= data_bits_reg;                              // p2 error
            3'b011: corrected_data <= {data_bits_reg[3:1], ~data_bits_reg[0]};    // d1 error
            3'b100: corrected_data <= data_bits_reg;                              // p3 error
            3'b101: corrected_data <= {data_bits_reg[3:2], ~data_bits_reg[1], data_bits_reg[0]}; // d2 error
            3'b110: corrected_data <= {data_bits_reg[3], ~data_bits_reg[2], data_bits_reg[1:0]}; // d3 error
            3'b111: corrected_data <= {~data_bits_reg[3], data_bits_reg[2:0]};    // d4 error
        endcase
    end
endmodule