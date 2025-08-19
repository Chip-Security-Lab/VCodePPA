//SystemVerilog
module RoundRobinIVMU (
    input clk,
    input rst,
    input [7:0] irq,
    input ack,
    output reg [31:0] vector,
    output reg valid
);
    // State registers
    reg [2:0] last_served;
    reg [7:0] pending;
    
    // Memory for vector table (initialized combinatorially)
    reg [31:0] vector_table [0:7];
    
    // Combinational signals for next state calculation
    reg [7:0] next_pending;
    reg next_valid;
    reg [31:0] next_vector;
    reg [2:0] next_last_served;
    
    // Initialization of vector table (combinational context for memory init)
    initial begin
        vector_table[0] = 32'h6000_0000;
        vector_table[1] = 32'h6000_0020;
        vector_table[2] = 32'h6000_0040;
        vector_table[3] = 32'h6000_0060;
        vector_table[4] = 32'h6000_0080;
        vector_table[5] = 32'h6000_00A0;
        vector_table[6] = 32'h6000_00C0;
        vector_table[7] = 32'h6000_00E0;
    end
    
    // --- Combinational Logic Block ---
    // Calculate pending state after considering new IRQs
    wire [7:0] pending_after_irq = pending | irq;
    wire any_pending_after_irq = |pending_after_irq;
    
    // Calculate the indices in the round-robin search order starting from last_served + 1
    // Using parallel prefix adders for 3-bit additions (modulo 8 is implicit in 3-bit sum)
    wire [2:0] rr_idx_plus1;
    wire [2:0] rr_idx_plus2;
    wire [2:0] rr_idx_plus3;
    wire [2:0] rr_idx_plus4;
    wire [2:0] rr_idx_plus5;
    wire [2:0] rr_idx_plus6;
    wire [2:0] rr_idx_plus7;
    wire [2:0] rr_idx_plus8 = last_served; // This is (last_served + 8) % 8 == last_served % 8

    // Instantiate parallel prefix adders for (last_served + N) % 8
    // Cin is 0 for all additions
    parallel_prefix_adder_3bit adder_p1 (.a(last_served), .b(3'd1), .cin(1'b0), .sum(rr_idx_plus1), .cout());
    parallel_prefix_adder_3bit adder_p2 (.a(last_served), .b(3'd2), .cin(1'b0), .sum(rr_idx_plus2), .cout());
    parallel_prefix_adder_3bit adder_p3 (.a(last_served), .b(3'd3), .cin(1'b0), .sum(rr_idx_plus3), .cout());
    parallel_prefix_adder_3bit adder_p4 (.a(last_served), .b(3'd4), .cin(1'b0), .sum(rr_idx_plus4), .cout());
    parallel_prefix_adder_3bit adder_p5 (.a(last_served), .b(3'd5), .cin(1'b0), .sum(rr_idx_plus5), .cout());
    parallel_prefix_adder_3bit adder_p6 (.a(last_served), .b(3'd6), .cin(1'b0), .sum(rr_idx_plus6), .cout());
    parallel_prefix_adder_3bit adder_p7 (.a(last_served), .b(3'd7), .cin(1'b0), .sum(rr_idx_plus7), .cout());
                               
    // Determine which interrupt index to serve if any are pending in the round-robin order
    wire [2:0] served_index_comb;
    assign served_index_comb = pending_after_irq[rr_idx_plus1] ? rr_idx_plus1 :
                               pending_after_irq[rr_idx_plus2] ? rr_idx_plus2 :
                               pending_after_irq[rr_idx_plus3] ? rr_idx_plus3 :
                               pending_after_irq[rr_idx_plus4] ? rr_idx_plus4 :
                               pending_after_irq[rr_idx_plus5] ? rr_idx_plus5 :
                               pending_after_irq[rr_idx_plus6] ? rr_idx_plus6 :
                               pending_after_irq[rr_idx_plus7] ? rr_idx_plus7 :
                               rr_idx_plus8; // Default to the last_served index if none of +1..+7 are pending
                               
    // Determine if an interrupt will be served this cycle
    // An interrupt is served if the controller is not currently valid AND there are pending interrupts
    wire serve_this_cycle = (!valid && any_pending_after_irq);
    
    // Combinational logic to calculate next state values for registers
    always @(*) begin
        // Default next state is current state (or derived from current state/inputs)
        next_pending = pending_after_irq; // Always update pending with new IRQs
        next_valid = valid;
        next_vector = vector;
        next_last_served = last_served;

        // Calculate next state based on ack and serve conditions
        if (ack) begin
            // If acknowledged, clear the valid flag
            next_valid = 1'b0;
            // pending, vector, last_served remain unchanged by ack itself in terms of *which* interrupt is being handled
        end else if (serve_this_cycle) begin
            // If ready to serve and interrupts are pending
            next_valid = 1'b1; // Assert valid
            next_vector = vector_table[served_index_comb]; // Get vector for the served index
            next_last_served = served_index_comb; // Update last served index
            // Clear the served bit from the pending register state calculated above (pending_after_irq)
            next_pending = next_pending & ~(1 << served_index_comb);
        end
        // If not ack and not serving, state remains unchanged (except for pending which includes new irqs)
    end
    
    // --- Sequential Logic Block ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            last_served <= 3'b0;
            pending <= 8'b0;
            valid <= 1'b0;
            vector <= 32'h0;
        end else begin
            // Update registers with the calculated next state values
            last_served <= next_last_served;
            pending <= next_pending;
            valid <= next_valid;
            vector <= next_vector;
        end
    end

endmodule

// 3-bit Parallel Prefix Adder Module (Combinational Logic)
// Implements sum = a + b + cin
module parallel_prefix_adder_3bit (
    input [2:0] a,
    input [2:0] b,
    input cin,
    output [2:0] sum,
    output cout
);
    // Generate and Propagate signals for each bit
    wire [2:0] p = a ^ b;
    wire [2:0] g = a & b;

    // Prefix tree nodes (Kogge-Stone like structure for 3 bits)

    // Level 1 nodes (combine pairs)
    wire p1_0 = p[1] & p[0];
    wire g1_0 = g[1] | (p[1] & g[0]);

    // Level 2 nodes (combine groups)
    wire p2_0 = p[2] & p1_0;
    wire g2_0 = g[2] | (p[2] & g1_0);

    // Carries out of each bit position (c1, c2, c3)
    // c[0] is the input carry cin
    wire c [3:0];
    assign c[0] = cin;             // c0 = Cin
    assign c[1] = g[0] | (p[0] & c[0]); // c1 = G0:0 | (P0:0 & c0)
    assign c[2] = g1_0 | (p1_0 & c[0]); // c2 = G1:0 | (P1:0 & c0)
    assign c[3] = g2_0 | (p2_0 & c[0]); // c3 = G2:0 | (P2:0 & c0)

    // Sum bits
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];

    assign cout = c[3];

endmodule