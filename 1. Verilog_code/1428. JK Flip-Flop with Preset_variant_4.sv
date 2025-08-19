//SystemVerilog
// Top level module with integrated Baugh-Wooley multiplier
module jk_ff_preset (
    input wire clk,
    input wire preset_n,
    input wire j,
    input wire k,
    output wire q,
    // Additional ports for multiplier
    input wire [7:0] multiplicand,
    input wire [7:0] multiplier,
    output wire [15:0] product
);
    // Internal signals for JK flip-flop
    wire next_state;
    wire preset_value;
    
    // Submodule instantiations for JK flip-flop
    jk_logic_unit logic_unit (
        .j(j),
        .k(k),
        .current_state(q),
        .next_state(next_state)
    );
    
    preset_control preset_ctrl (
        .preset_n(preset_n),
        .preset_value(preset_value)
    );
    
    state_register state_reg (
        .clk(clk),
        .preset_n(preset_n),
        .preset_value(preset_value),
        .next_state(next_state),
        .q(q)
    );
    
    // Baugh-Wooley multiplier instantiation
    baugh_wooley_multiplier bw_mult (
        .clk(clk),
        .reset_n(preset_n),
        .multiplicand(multiplicand),
        .multiplier(multiplier),
        .product(product)
    );
endmodule

// JK logic evaluation unit
module jk_logic_unit (
    input wire j,
    input wire k,
    input wire current_state,
    output reg next_state
);
    always @(*) begin
        case ({j, k})
            2'b00: next_state = current_state; // Hold state
            2'b01: next_state = 1'b0;          // Reset
            2'b10: next_state = 1'b1;          // Set
            2'b11: next_state = ~current_state; // Toggle
        endcase
    end
endmodule

// Preset control unit
module preset_control (
    input wire preset_n,
    output wire preset_value
);
    // Preset value is always 1 for this design
    assign preset_value = 1'b1;
endmodule

// State register with asynchronous preset
module state_register (
    input wire clk,
    input wire preset_n,
    input wire preset_value,
    input wire next_state,
    output reg q
);
    always @(posedge clk or negedge preset_n) begin
        if (!preset_n)
            q <= preset_value;  // Asynchronous preset
        else
            q <= next_state;    // Normal operation
    end
endmodule

// 8-bit Baugh-Wooley Multiplier implementation
module baugh_wooley_multiplier (
    input wire clk,
    input wire reset_n,
    input wire [7:0] multiplicand,
    input wire [7:0] multiplier,
    output reg [15:0] product
);
    // Internal signals
    reg [7:0] a_reg, b_reg;
    wire [15:0] pp [7:0];  // Partial products
    wire [15:0] result;    // Combinational result
    
    // Register input operands
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            product <= 16'b0;
        end else begin
            a_reg <= multiplicand;
            b_reg <= multiplier;
            product <= result;
        end
    end
    
    // Generate partial products according to Baugh-Wooley algorithm
    // For positive weights (i < 7, j < 7)
    genvar i, j;
    generate
        for (i = 0; i < 7; i = i + 1) begin: pp_gen_rows
            for (j = 0; j < 7; j = j + 1) begin: pp_gen_cols
                assign pp[i][i+j] = a_reg[i] & b_reg[j];
            end
        end
    endgenerate
    
    // For negative weights (MSB handling)
    generate
        // When multiplicand MSB (a[7]) is used with non-MSB bits of multiplier
        for (j = 0; j < 7; j = j + 1) begin: neg_a_msb
            assign pp[7][7+j] = ~(a_reg[7] & b_reg[j]);
        end
        
        // When multiplier MSB (b[7]) is used with non-MSB bits of multiplicand
        for (i = 0; i < 7; i = i + 1) begin: neg_b_msb
            assign pp[i][i+7] = ~(a_reg[i] & b_reg[7]);
        end
        
        // When both MSBs are used
        assign pp[7][14] = a_reg[7] & b_reg[7];
    endgenerate
    
    // Additional '1' bits for Baugh-Wooley algorithm
    wire [15:0] correction;
    assign correction[0] = 1'b0;  // No correction at position 0
    
    // Add correction bits at positions 7 to 14
    generate
        for (i = 7; i < 15; i = i + 1) begin: correction_bits
            assign correction[i] = 1'b1;
        end
        
        // No correction needed for other positions
        for (i = 1; i < 7; i = i + 1) begin: zero_correction
            assign correction[i] = 1'b0;
        end
    endgenerate
    
    assign correction[15] = 1'b0;  // No correction at position 15
    
    // Sum all partial products and correction bits using carry-save addition
    wire [15:0] sum_level1_a, sum_level1_b, sum_level1_c, sum_level1_d;
    wire [15:0] sum_level2_a, sum_level2_b;
    
    // First level of reduction (4 to 2)
    assign sum_level1_a = pp[0] ^ pp[1] ^ pp[2] ^ pp[3];
    assign sum_level1_b = {(pp[0] & pp[1]) | (pp[0] & pp[2]) | (pp[1] & pp[2]) | 
                           (pp[0] & pp[3]) | (pp[1] & pp[3]) | (pp[2] & pp[3]), 1'b0};
    assign sum_level1_c = pp[4] ^ pp[5] ^ pp[6] ^ pp[7];
    assign sum_level1_d = {(pp[4] & pp[5]) | (pp[4] & pp[6]) | (pp[5] & pp[6]) | 
                           (pp[4] & pp[7]) | (pp[5] & pp[7]) | (pp[6] & pp[7]), 1'b0};
    
    // Second level of reduction (4 to 2)
    assign sum_level2_a = sum_level1_a ^ sum_level1_b ^ sum_level1_c ^ sum_level1_d;
    assign sum_level2_b = {(sum_level1_a & sum_level1_b) | (sum_level1_a & sum_level1_c) | 
                           (sum_level1_b & sum_level1_c) | (sum_level1_a & sum_level1_d) | 
                           (sum_level1_b & sum_level1_d) | (sum_level1_c & sum_level1_d), 1'b0};
    
    // Final addition with correction bits
    assign result = sum_level2_a + sum_level2_b + correction;
endmodule