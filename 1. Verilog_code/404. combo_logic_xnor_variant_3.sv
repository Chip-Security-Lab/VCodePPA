//SystemVerilog
//IEEE 1364-2005 Standard
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
module combo_logic_xnor (
    input  wire clk,         // System clock
    input  wire rst_n,       // Active low reset
    input  wire in_data1,    // First input data bit
    input  wire in_data2,    // Second input data bit
    output wire out_data     // Output data (XNOR result)
);

    // Internal pipeline registers
    reg stage1_data_equal;   // Equality comparison result
    reg stage1_data_valid;   // Valid data tracking
    reg stage2_result_r;     // Final output register

    // Stage 1: Optimized equality comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data_equal <= 1'b0;
            stage1_data_valid <= 1'b0;
        end else begin
            // Direct equality comparison with XOR reduction
            // This leverages hardware comparator structures more efficiently
            stage1_data_equal <= ~(in_data1 ^ in_data2); 
            stage1_data_valid <= 1'b1;
        end
    end

    // Stage 2: Result registration with valid data gating
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result_r <= 1'b0;
        end else if (stage1_data_valid) begin
            // Pass through equality result only when data is valid
            stage2_result_r <= stage1_data_equal;
        end
    end

    // Assign registered output
    assign out_data = stage2_result_r;

endmodule