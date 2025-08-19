//SystemVerilog
module shannon_fano_encoder (
    input  logic        clk,            // Clock input for pipeline registers
    input  logic        rst_n,          // Reset signal for proper initialization
    input  logic [3:0]  symbol,
    input  logic        valid,          // Indicates input data is valid
    output logic        ready,          // Indicates encoder is ready for input
    output logic [7:0]  code,
    output logic [2:0]  code_length,
    output logic        code_valid      // Indicates output data is valid
);
    // Pre-computed codes and lengths - would normally be generated
    logic [7:0] codes [0:15];
    logic [2:0] lengths [0:15];
    
    // Pipeline stage registers
    logic [3:0] symbol_stage1, symbol_stage2;
    logic       valid_stage1, valid_stage2, valid_stage3;
    logic [7:0] code_stage2, code_stage3;
    logic [2:0] length_stage2, length_stage3;
    
    // Processing state tracking
    logic processing_r;
    logic [2:0] pipeline_count;
    
    // Code table initialization
    always_comb begin
        // Symbol 0 (most common)
        codes[0] = 8'b0;        lengths[0] = 1;
        // Symbol 1-2 (common)
        codes[1] = 8'b10;       lengths[1] = 2;
        codes[2] = 8'b11;       lengths[2] = 2;
        // Symbol 3-6 (less common)
        codes[3] = 8'b100;      lengths[3] = 3;
        codes[4] = 8'b101;      lengths[4] = 3;
        codes[5] = 8'b110;      lengths[5] = 3;
        codes[6] = 8'b111;      lengths[6] = 3;
        // And so on with remaining symbols (keeping the rest the same)
        codes[7] = 8'b1000;     lengths[7] = 4;
        codes[8] = 8'b1001;     lengths[8] = 4;
        codes[9] = 8'b1010;     lengths[9] = 4;
        codes[10] = 8'b1011;    lengths[10] = 4;
        codes[11] = 8'b1100;    lengths[11] = 4;
        codes[12] = 8'b1101;    lengths[12] = 4;
        codes[13] = 8'b1110;    lengths[13] = 4;
        codes[14] = 8'b1111;    lengths[14] = 4;
        codes[15] = 8'b11111;   lengths[15] = 5;
    end
    
    // Pipeline counter management using two's complement adder for decrement
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipeline_count <= 3'b0;
            processing_r <= 1'b0;
        end else begin
            if (valid && ready)
                pipeline_count <= 3'b011; // 3-stage pipeline
            else if (pipeline_count > 0) begin
                // Implement subtraction using two's complement addition
                // For 8-bit: pipeline_count = pipeline_count + (~1'b1 + 1'b1) = pipeline_count + 8'b11111111
                // For 3-bit: pipeline_count = pipeline_count + (~1'b1 + 1'b1) = pipeline_count + 3'b111
                logic [2:0] ones_complement;
                logic [2:0] twos_complement;
                logic [2:0] result;
                
                ones_complement = ~3'b001;             // One's complement of 1
                twos_complement = ones_complement + 1; // Two's complement of 1 (3'b111)
                result = pipeline_count + twos_complement;
                pipeline_count <= result;
            end
                
            // Set processing state
            if (valid && ready)
                processing_r <= 1'b1;
            else if (pipeline_count == 3'b001) // Last stage
                processing_r <= 1'b0;
        end
    end
    
    // Ready signal logic
    assign ready = !processing_r;
    
    // Pipeline stage 1: Register input symbols
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            symbol_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end else begin
            if (valid && ready) begin
                symbol_stage1 <= symbol;
                valid_stage1 <= 1'b1;
            end else begin
                // Use comparison with two's complement addition
                logic [2:0] compare_value;
                logic [2:0] twos_comp_result;
                
                compare_value = 3'b010; // Value to compare against (2)
                // Compute pipeline_count - compare_value using two's complement
                twos_comp_result = pipeline_count + (~compare_value + 1'b1);
                // If result's MSB is 0, then pipeline_count >= compare_value
                valid_stage1 <= !twos_comp_result[2];
            end
        end
    end
    
    // Pipeline stage 2: Lookup code and length
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            symbol_stage2 <= 4'b0;
            valid_stage2 <= 1'b0;
            code_stage2 <= 8'b0;
            length_stage2 <= 3'b0;
        end else begin
            symbol_stage2 <= symbol_stage1;
            valid_stage2 <= valid_stage1;
            
            if (valid_stage1) begin
                code_stage2 <= codes[symbol_stage1];
                length_stage2 <= lengths[symbol_stage1];
            end else begin
                code_stage2 <= 8'b0;
                length_stage2 <= 3'b0;
            end
        end
    end
    
    // Pipeline stage 3: Final output stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 1'b0;
            code_stage3 <= 8'b0;
            length_stage3 <= 3'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            code_stage3 <= code_stage2;
            length_stage3 <= length_stage2;
        end
    end
    
    // Output assignment
    assign code = code_stage3;
    assign code_length = length_stage3;
    assign code_valid = valid_stage3;
    
endmodule