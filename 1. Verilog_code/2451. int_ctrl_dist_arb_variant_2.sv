//SystemVerilog
// Top-level module
module int_ctrl_dist_arb #(
    parameter N = 4
)(
    input  [N-1:0] req,
    output [N-1:0] grant
);
    // Intermediate signals
    wire [N-1:0] priority_mask;
    
    // Priority encoder module for generating active-low mask using parallel prefix subtractor
    priority_encoder #(
        .WIDTH(N)
    ) priority_enc_inst (
        .request(req),
        .mask(priority_mask)
    );
    
    // Arbiter logic that applies the priority mask
    arbiter_logic #(
        .WIDTH(N)
    ) arbiter_logic_inst (
        .request(req),
        .priority_mask(priority_mask),
        .grant(grant)
    );
endmodule

// Priority encoder to generate mask using parallel prefix subtraction
module priority_encoder #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0] request,
    output [WIDTH-1:0] mask
);
    // Generate a mask where all bits below the highest priority bit are set
    // Using parallel prefix subtraction algorithm

    // Define propagate (P) and generate (G) signals for subtraction
    wire [WIDTH-1:0] P, G;
    wire [WIDTH-1:0] not_req = ~request;
    
    // First level: initialize P and G for each bit
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : init_pg
            assign P[i] = request[i] | not_req[i]; // Propagate = a XOR b = a | b for subtraction
            assign G[i] = ~request[i] & 1'b1;      // Generate = ~a & b for subtraction
        end
    endgenerate
    
    // Parallel prefix tree for 8-bit subtraction
    // Pre-compute group P and G signals
    wire [WIDTH-1:0] group_P, group_G;
    
    // Level 1 computation (2-bit groups)
    wire [WIDTH/2-1:0] P_L1, G_L1;
    generate
        for (i = 0; i < WIDTH; i = i + 2) begin : level1
            if (i+1 < WIDTH) begin
                assign P_L1[i/2] = P[i] & P[i+1];
                assign G_L1[i/2] = G[i] | (P[i] & G[i+1]);
            end
        end
    endgenerate
    
    // Level 2 computation (4-bit groups)
    wire [WIDTH/4-1:0] P_L2, G_L2;
    generate
        for (i = 0; i < WIDTH/2; i = i + 2) begin : level2
            if (i+1 < WIDTH/2) begin
                assign P_L2[i/2] = P_L1[i] & P_L1[i+1];
                assign G_L2[i/2] = G_L1[i] | (P_L1[i] & G_L1[i+1]);
            end
        end
    endgenerate
    
    // Level 3 computation (8-bit groups)
    wire P_L3, G_L3;
    generate
        if (WIDTH >= 8) begin : level3
            assign P_L3 = P_L2[0] & P_L2[1];
            assign G_L3 = G_L2[0] | (P_L2[0] & G_L2[1]);
        end
    endgenerate
    
    // Compute final borrow signals using prefix results
    wire [WIDTH:0] borrow;
    assign borrow[0] = 1'b1; // Initial borrow = 1 (subtract 1)
    
    // Calculate borrows at different bit positions
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : calc_borrow
            case (i)
                0: assign borrow[i+1] = G[i] | (P[i] & borrow[i]);
                1: assign borrow[i+1] = G[i] | (P[i] & borrow[i]);
                2: assign borrow[i+1] = G[i] | (P[i] & G_L1[0]) | (P[i] & P_L1[0] & borrow[0]);
                3: assign borrow[i+1] = G[i] | (P[i] & G_L1[1]) | (P[i] & P_L1[1] & G_L1[0]) | (P[i] & P_L1[1] & P_L1[0] & borrow[0]);
                4: assign borrow[i+1] = G[i] | (P[i] & G_L2[0]) | (P[i] & P_L2[0] & borrow[0]);
                5: assign borrow[i+1] = G[i] | (P[i] & G_L1[2]) | (P[i] & P_L1[2] & G_L2[0]) | (P[i] & P_L1[2] & P_L2[0] & borrow[0]);
                6: assign borrow[i+1] = G[i] | (P[i] & G_L1[3]) | (P[i] & P_L1[3] & G_L2[0]) | (P[i] & P_L1[3] & P_L2[0] & borrow[0]);
                7: assign borrow[i+1] = G[i] | (P[i] & G_L2[1]) | (P[i] & P_L2[1] & G_L2[0]) | (P[i] & P_L2[1] & P_L2[0] & borrow[0]);
                default: assign borrow[i+1] = G[i] | (P[i] & borrow[i]);
            endcase
        end
    endgenerate
    
    // Calculate mask from borrows
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : calc_mask
            assign mask[i] = request[i] ^ not_req[i] ^ borrow[i];
        end
    endgenerate
endmodule

// Arbiter logic module to apply the mask
module arbiter_logic #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0] request,
    input  [WIDTH-1:0] priority_mask,
    output [WIDTH-1:0] grant
);
    // Apply mask to isolate only the highest priority bit
    assign grant = request & ~priority_mask;
endmodule