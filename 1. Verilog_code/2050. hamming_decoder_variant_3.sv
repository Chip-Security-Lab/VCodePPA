//SystemVerilog
// Top-level Hamming Decoder Pipeline Module
module hamming_decoder (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [6:0]  hamming_in,
    output wire [3:0]  data_out,
    output wire        error_detected
);

    // ===============================
    // Pipeline Stage 1: Input Register
    // ===============================
    reg [6:0] hamming_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            hamming_stage1 <= 7'b0;
        else
            hamming_stage1 <= hamming_in;
    end

    // ===========================================
    // Pipeline Stage 2: Syndrome and Data Extract
    // ===========================================
    wire [2:0] syndrome_stage2_wire;
    wire [3:0] data_stage2_wire;

    hamming_syndrome_calc u_syndrome_calc (
        .hamming_code (hamming_stage1),
        .syndrome     (syndrome_stage2_wire)
    );

    hamming_data_extract u_data_extract (
        .hamming_code (hamming_stage1),
        .data_out     (data_stage2_wire)
    );

    reg [2:0] syndrome_stage2;
    reg [3:0] data_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            syndrome_stage2 <= 3'b0;
            data_stage2     <= 4'b0;
        end else begin
            syndrome_stage2 <= syndrome_stage2_wire;
            data_stage2     <= data_stage2_wire;
        end
    end

    // ==================================
    // Pipeline Stage 3: Error Detection
    // ==================================
    wire error_stage3_wire;
    hamming_error_detect u_error_detect (
        .syndrome        (syndrome_stage2),
        .error_detected  (error_stage3_wire)
    );

    reg [3:0]  data_out_reg;
    reg        error_detected_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_reg       <= 4'b0;
            error_detected_reg <= 1'b0;
        end else begin
            data_out_reg       <= data_stage2;
            error_detected_reg <= error_stage3_wire;
        end
    end

    assign data_out       = data_out_reg;
    assign error_detected = error_detected_reg;

endmodule

// -----------------------------------------------------------------------------
// Syndrome Calculation Module
// Calculates the 3-bit syndrome from the input 7-bit Hamming code.
// -----------------------------------------------------------------------------
module hamming_syndrome_calc (
    input  wire [6:0] hamming_code,
    output wire [2:0] syndrome
);
    assign syndrome[0] = hamming_code[0] ^ hamming_code[2] ^ hamming_code[4] ^ hamming_code[6];
    assign syndrome[1] = hamming_code[1] ^ hamming_code[2] ^ hamming_code[5] ^ hamming_code[6];
    assign syndrome[2] = hamming_code[3] ^ hamming_code[4] ^ hamming_code[5] ^ hamming_code[6];
endmodule

// -----------------------------------------------------------------------------
// Error Detection Module
// Detects if there is an error based on the syndrome value.
// -----------------------------------------------------------------------------
module hamming_error_detect (
    input  wire [2:0] syndrome,
    output wire       error_detected
);
    assign error_detected = |syndrome;
endmodule

// -----------------------------------------------------------------------------
// Data Extraction Module
// Extracts the 4-bit data from the input 7-bit Hamming code.
// -----------------------------------------------------------------------------
module hamming_data_extract (
    input  wire [6:0] hamming_code,
    output wire [3:0] data_out
);
    assign data_out = {hamming_code[6], hamming_code[5], hamming_code[4], hamming_code[2]};
endmodule