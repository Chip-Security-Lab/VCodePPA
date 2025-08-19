//SystemVerilog
module ecc_signal_recovery (
    input wire clock,
    input wire reset,
    input wire valid_in,
    input wire [6:0] encoded_data,
    output wire [3:0] corrected_data,
    output wire error_detected,
    output wire valid_out
);
    // Stage 1 registers
    reg [6:0] encoded_data_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg [6:0] encoded_data_stage2;
    reg [2:0] syndrome_stage2;
    reg valid_stage2;
    
    // Output registers
    reg [3:0] corrected_data_reg;
    reg error_detected_reg;
    reg valid_out_reg;
    
    // Combinational logic for stage 1
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
    
    // Stage 1: Register inputs and calculate syndrome
    always @(posedge clock) begin
        if (reset) begin
            encoded_data_stage1 <= 7'b0;
            valid_stage1 <= 1'b0;
        end else begin
            encoded_data_stage1 <= encoded_data;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Register syndrome and encoded data
    always @(posedge clock) begin
        if (reset) begin
            encoded_data_stage2 <= 7'b0;
            syndrome_stage2 <= 3'b0;
            valid_stage2 <= 1'b0;
        end else begin
            encoded_data_stage2 <= encoded_data_stage1;
            syndrome_stage2 <= syndrome;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Perform error correction based on syndrome
    always @(posedge clock) begin
        if (reset) begin
            corrected_data_reg <= 4'b0;
            error_detected_reg <= 1'b0;
            valid_out_reg <= 1'b0;
        end else begin
            valid_out_reg <= valid_stage2;
            
            if (valid_stage2) begin
                error_detected_reg <= |syndrome_stage2;
                
                case (syndrome_stage2)
                    3'b000: corrected_data_reg <= {encoded_data_stage2[6], encoded_data_stage2[5], encoded_data_stage2[4], encoded_data_stage2[2]};
                    3'b001: corrected_data_reg <= {encoded_data_stage2[6], encoded_data_stage2[5], encoded_data_stage2[4], encoded_data_stage2[2]};  // p1 error
                    3'b010: corrected_data_reg <= {encoded_data_stage2[6], encoded_data_stage2[5], encoded_data_stage2[4], encoded_data_stage2[2]};  // p2 error
                    3'b011: corrected_data_reg <= {encoded_data_stage2[6], encoded_data_stage2[5], encoded_data_stage2[4], ~encoded_data_stage2[2]}; // d1 error
                    3'b100: corrected_data_reg <= {encoded_data_stage2[6], encoded_data_stage2[5], encoded_data_stage2[4], encoded_data_stage2[2]};  // p3 error
                    3'b101: corrected_data_reg <= {encoded_data_stage2[6], encoded_data_stage2[5], ~encoded_data_stage2[4], encoded_data_stage2[2]}; // d2 error
                    3'b110: corrected_data_reg <= {encoded_data_stage2[6], ~encoded_data_stage2[5], encoded_data_stage2[4], encoded_data_stage2[2]}; // d3 error
                    3'b111: corrected_data_reg <= {~encoded_data_stage2[6], encoded_data_stage2[5], encoded_data_stage2[4], encoded_data_stage2[2]}; // d4 error
                endcase
            end
        end
    end
    
    // Connect output registers to module outputs
    assign corrected_data = corrected_data_reg;
    assign error_detected = error_detected_reg;
    assign valid_out = valid_out_reg;
    
endmodule