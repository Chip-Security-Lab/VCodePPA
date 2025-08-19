//SystemVerilog
module jk_ff_sync_reset (
    input wire clock,
    input wire reset,
    input wire j_in,
    input wire k_in,
    output reg q_out
);
    // Pipeline stage 1: Input registration
    reg j_reg, k_reg;
    reg q_out_reg;
    
    // Input registering to break input path
    always @(posedge clock) begin
        if (reset) begin
            j_reg <= 1'b0;
            k_reg <= 1'b0;
            q_out_reg <= 1'b0;
        end else begin
            j_reg <= j_in;
            k_reg <= k_in;
            q_out_reg <= q_out;
        end
    end
    
    // Pipeline stage 2: JK decision logic and output
    reg next_q;
    
    // JK decision logic
    always @(*) begin
        case ({j_reg, k_reg})
            2'b00: next_q = q_out_reg;
            2'b01: next_q = 1'b0;
            2'b10: next_q = 1'b1;
            2'b11: next_q = ~q_out_reg;
            default: next_q = q_out_reg;
        endcase
    end
    
    // Output registration
    always @(posedge clock) begin
        if (reset)
            q_out <= 1'b0;
        else
            q_out <= next_q;
    end
endmodule

module baugh_wooley_multiplier_8bit (
    input wire clock,
    input wire reset,
    input wire [7:0] multiplicand,  // 8-bit input A
    input wire [7:0] multiplier,    // 8-bit input B
    output reg [15:0] product       // 16-bit output
);
    // Internal signals for partial products
    reg [7:0] pp [0:7];
    reg [15:0] sum;
    
    // Intermediate signals for computation
    reg [15:0] product_next;
    
    // Generate partial products using Baugh-Wooley algorithm
    always @(*) begin
        integer i, j;
        
        // Initialize partial products
        for (i = 0; i < 7; i = i + 1) begin
            for (j = 0; j < 7; j = j + 1) begin
                pp[i][j] = multiplicand[j] & multiplier[i];
            end
            // Special handling for the MSB (sign bit) in Baugh-Wooley
            pp[i][7] = ~(multiplicand[7] & multiplier[i]);
        end
        
        // Last row has special handling for Baugh-Wooley
        for (j = 0; j < 7; j = j + 1) begin
            pp[7][j] = ~(multiplicand[j] & multiplier[7]);
        end
        pp[7][7] = multiplicand[7] & multiplier[7];
        
        // Sum up the partial products
        product_next = 16'b0;
        
        // Accumulate partial products with appropriate shifts
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                product_next[i+j] = product_next[i+j] ^ pp[i][j];
            end
        end
        
        // Add correction term for Baugh-Wooley (1 in the (n-1)th position)
        product_next[14] = ~product_next[14];
        
        // Add correction term for Baugh-Wooley (1 in the (2n-2)th position)
        product_next[15] = ~product_next[15];
    end
    
    // Register the computed product
    always @(posedge clock) begin
        if (reset) begin
            product <= 16'b0;
        end else begin
            product <= product_next;
        end
    end
endmodule