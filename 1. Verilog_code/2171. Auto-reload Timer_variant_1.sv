//SystemVerilog
module auto_reload_timer (
    input  wire        clk,
    input  wire        rstn,
    input  wire        en,
    input  wire        reload_en,
    input  wire [31:0] reload_val,
    output reg  [31:0] count,
    output reg         timeout
);
    reg [31:0] reload_reg;
    
    // Reload register logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            reload_reg <= 32'hFFFFFFFF;
        else if (reload_en)
            reload_reg <= reload_val;
    end
    
    // Timer counter and timeout logic
    wire count_at_reload = (count == reload_reg);
    wire [31:0] next_count;
    
    // Instantiate parallel prefix adder for better performance
    parallel_prefix_adder_32bit ppa_inst (
        .a(count),
        .b(32'h1),
        .cin(1'b0),
        .sum(next_count),
        .cout()  // Not connected as we don't need carry out
    );
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            count   <= 32'h0;
            timeout <= 1'b0;
        end
        else if (en) begin
            if (count_at_reload) begin
                count   <= 32'h0;
                timeout <= 1'b1;
            end
            else begin
                count   <= next_count;
                timeout <= 1'b0;
            end
        end
    end
endmodule

// 32-bit Parallel Prefix Adder (Kogge-Stone algorithm)
module parallel_prefix_adder_32bit (
    input [31:0] a,
    input [31:0] b,
    input cin,
    output [31:0] sum,
    output cout
);
    // Generate propagate (P) and generate (G) signals
    wire [31:0] p, g;
    assign p = a ^ b;  // Propagate
    assign g = a & b;  // Generate

    // Group propagate and generate signals for prefix computation
    // Level 0 (Initial)
    wire [31:0] gout_0, pout_0;
    assign gout_0 = g;
    assign pout_0 = p;

    // Level 1 (2-bit groups)
    wire [31:0] gout_1, pout_1;
    genvar i;
    generate
        // First position
        assign gout_1[0] = gout_0[0];
        assign pout_1[0] = pout_0[0];
        
        // Rest of the positions
        for (i = 1; i < 32; i = i + 1) begin: level1_prefix
            // Group generate: G[i:j] = G[i:k] + (P[i:k] · G[k-1:j])
            assign gout_1[i] = gout_0[i] | (pout_0[i] & gout_0[i-1]);
            // Group propagate: P[i:j] = P[i:k] · P[k-1:j]
            assign pout_1[i] = pout_0[i] & pout_0[i-1];
        end
    endgenerate

    // Level 2 (4-bit groups)
    wire [31:0] gout_2, pout_2;
    generate
        // First two positions - no changes
        for (i = 0; i < 2; i = i + 1) begin: level2_copy
            assign gout_2[i] = gout_1[i];
            assign pout_2[i] = pout_1[i];
        end
        
        // Rest of the positions
        for (i = 2; i < 32; i = i + 1) begin: level2_prefix
            assign gout_2[i] = gout_1[i] | (pout_1[i] & gout_1[i-2]);
            assign pout_2[i] = pout_1[i] & pout_1[i-2];
        end
    endgenerate

    // Level 3 (8-bit groups)
    wire [31:0] gout_3, pout_3;
    generate
        // First four positions - no changes
        for (i = 0; i < 4; i = i + 1) begin: level3_copy
            assign gout_3[i] = gout_2[i];
            assign pout_3[i] = pout_2[i];
        end
        
        // Rest of the positions
        for (i = 4; i < 32; i = i + 1) begin: level3_prefix
            assign gout_3[i] = gout_2[i] | (pout_2[i] & gout_2[i-4]);
            assign pout_3[i] = pout_2[i] & pout_2[i-4];
        end
    endgenerate

    // Level 4 (16-bit groups)
    wire [31:0] gout_4, pout_4;
    generate
        // First eight positions - no changes
        for (i = 0; i < 8; i = i + 1) begin: level4_copy
            assign gout_4[i] = gout_3[i];
            assign pout_4[i] = pout_3[i];
        end
        
        // Rest of the positions
        for (i = 8; i < 32; i = i + 1) begin: level4_prefix
            assign gout_4[i] = gout_3[i] | (pout_3[i] & gout_3[i-8]);
            assign pout_4[i] = pout_3[i] & pout_3[i-8];
        end
    endgenerate

    // Level 5 (32-bit groups)
    wire [31:0] gout_5, pout_5;
    generate
        // First sixteen positions - no changes
        for (i = 0; i < 16; i = i + 1) begin: level5_copy
            assign gout_5[i] = gout_4[i];
            assign pout_5[i] = pout_4[i];
        end
        
        // Rest of the positions
        for (i = 16; i < 32; i = i + 1) begin: level5_prefix
            assign gout_5[i] = gout_4[i] | (pout_4[i] & gout_4[i-16]);
            assign pout_5[i] = pout_4[i] & pout_4[i-16];
        end
    endgenerate

    // Calculate carries
    wire [32:0] carry;
    assign carry[0] = cin;
    
    generate
        for (i = 0; i < 32; i = i + 1) begin: carry_gen
            // C[i+1] = G[i:0] | (P[i:0] & Cin)
            assign carry[i+1] = gout_5[i] | (pout_5[i] & cin);
        end
    endgenerate

    // Calculate sum
    generate
        for (i = 0; i < 32; i = i + 1) begin: sum_gen
            assign sum[i] = p[i] ^ carry[i];
        end
    endgenerate

    // Final carry-out
    assign cout = carry[32];
endmodule