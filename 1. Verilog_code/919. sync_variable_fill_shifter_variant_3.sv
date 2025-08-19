//SystemVerilog
// SystemVerilog
module sync_variable_fill_shifter (
    input                clk,
    input                rst,
    input      [7:0]     data_in,
    input      [2:0]     shift_val,
    input                shift_dir,  // 0: left, 1: right
    input                fill_bit,   // Value to fill vacant positions
    output reg [7:0]     data_out
);
    // Pipeline registers
    reg [7:0] data_in_reg;
    reg [2:0] shift_val_reg;
    reg shift_dir_reg;
    reg fill_bit_reg;
    
    // Intermediate signals for right shift calculation
    reg [15:0] extended_data;
    reg [7:0] right_shifted;
    
    // Intermediate signals for left shift calculation
    reg [7:0] left_shifted_data;
    reg [7:0] fill_mask;
    reg [7:0] left_shifted;
    
    // Final shifted result
    reg [7:0] shifted;
    
    // Signals for parallel prefix subtractor
    wire [7:0] mask_value;
    wire [8:0] p_terms[3:0]; // Propagate terms
    wire [8:0] g_terms[3:0]; // Generate terms
    
    // Register inputs to break long paths
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_in_reg <= 8'h00;
            shift_val_reg <= 3'h0;
            shift_dir_reg <= 1'b0;
            fill_bit_reg <= 1'b0;
        end else begin
            data_in_reg <= data_in;
            shift_val_reg <= shift_val;
            shift_dir_reg <= shift_dir;
            fill_bit_reg <= fill_bit;
        end
    end
    
    // Parallel prefix subtractor for (1 << shift_val_reg) - 1
    // Compute base value (1 << shift_val_reg)
    assign mask_value = 8'h01 << shift_val_reg;
    
    // Level 0: Initial propagate and generate terms
    assign p_terms[0] = {1'b0, ~mask_value}; // Bitwise complement for subtraction
    assign g_terms[0] = 9'h001;              // Initial generate for -1
    
    // Level 1: First level of prefix computation
    assign p_terms[1][0] = p_terms[0][0];
    assign g_terms[1][0] = g_terms[0][0];
    
    genvar i;
    generate
        for (i = 1; i < 9; i = i + 1) begin : prefix_level1
            assign p_terms[1][i] = p_terms[0][i] & p_terms[0][i-1];
            assign g_terms[1][i] = g_terms[0][i] | (p_terms[0][i] & g_terms[0][i-1]);
        end
    endgenerate
    
    // Level 2: Second level of prefix computation
    assign p_terms[2][0] = p_terms[1][0];
    assign g_terms[2][0] = g_terms[1][0];
    assign p_terms[2][1] = p_terms[1][1];
    assign g_terms[2][1] = g_terms[1][1];
    
    generate
        for (i = 2; i < 9; i = i + 1) begin : prefix_level2
            assign p_terms[2][i] = p_terms[1][i] & p_terms[1][i-2];
            assign g_terms[2][i] = g_terms[1][i] | (p_terms[1][i] & g_terms[1][i-2]);
        end
    endgenerate
    
    // Level 3: Final level of prefix computation
    assign p_terms[3][0] = p_terms[2][0];
    assign g_terms[3][0] = g_terms[2][0];
    assign p_terms[3][1] = p_terms[2][1];
    assign g_terms[3][1] = g_terms[2][1];
    assign p_terms[3][2] = p_terms[2][2];
    assign g_terms[3][2] = g_terms[2][2];
    assign p_terms[3][3] = p_terms[2][3];
    assign g_terms[3][3] = g_terms[2][3];
    
    generate
        for (i = 4; i < 9; i = i + 1) begin : prefix_level3
            assign p_terms[3][i] = p_terms[2][i] & p_terms[2][i-4];
            assign g_terms[3][i] = g_terms[2][i] | (p_terms[2][i] & g_terms[2][i-4]);
        end
    endgenerate
    
    // Stage 1: Prepare shift operands
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            extended_data <= 16'h0000;
            left_shifted_data <= 8'h00;
            fill_mask <= 8'h00;
        end else begin
            // Prepare for right shift
            extended_data <= {fill_bit_reg ? {8{1'b1}} : 8'b0, data_in_reg};
            
            // Prepare for left shift
            left_shifted_data <= data_in_reg << shift_val_reg;
            
            // Use parallel prefix subtractor result for fill mask
            fill_mask <= fill_bit_reg ? (mask_value ^ g_terms[3][7:0]) : 8'h00;
        end
    end
    
    // Stage 2: Perform the shifts
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            right_shifted <= 8'h00;
            left_shifted <= 8'h00;
        end else begin
            // Complete right shift
            right_shifted <= extended_data >> shift_val_reg;
            
            // Complete left shift
            left_shifted <= left_shifted_data | fill_mask;
        end
    end
    
    // Stage 3: Select final output based on direction
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shifted <= 8'h00;
        end else begin
            shifted <= shift_dir_reg ? right_shifted : left_shifted;
        end
    end
    
    // Final output register
    always @(posedge clk or posedge rst) begin
        if (rst) data_out <= 8'h00;
        else data_out <= shifted;
    end
endmodule