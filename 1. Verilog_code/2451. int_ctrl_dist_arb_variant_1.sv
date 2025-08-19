//SystemVerilog
///////////////////////////////////////////////////////////////////////////
// Module: int_ctrl_dist_arb
// Description: Top-level arbitration module implementing round-robin priority
//              encoding through a hierarchical design.
//              Using IEEE 1364-2005 Verilog standard
///////////////////////////////////////////////////////////////////////////
module int_ctrl_dist_arb #(
    parameter N = 4  // Number of request inputs
) (
    input  wire [N-1:0] req,    // Request signals
    output wire [N-1:0] grant   // Grant signals (one-hot)
);

    wire [N-1:0] req_minus_one;
    wire [N-1:0] negated_result;

    // Calculate req minus 1 operation using parallel prefix subtractor
    parallel_prefix_subtractor #(
        .WIDTH(N)
    ) u_req_subtractor (
        .minuend(req),
        .subtrahend(1'b1),
        .difference(req_minus_one)
    );

    // Negate the subtraction result
    bit_negation #(
        .WIDTH(N)
    ) u_bit_negation (
        .data_in(req_minus_one),
        .data_out(negated_result)
    );

    // Generate final grant signal
    grant_generator #(
        .WIDTH(N)
    ) u_grant_generator (
        .request(req),
        .negated_value(negated_result),
        .grant(grant)
    );

endmodule

///////////////////////////////////////////////////////////////////////////
// Module: parallel_prefix_subtractor
// Description: Implements subtraction using parallel prefix algorithm
///////////////////////////////////////////////////////////////////////////
module parallel_prefix_subtractor #(
    parameter WIDTH = 8
) (
    input  wire [WIDTH-1:0] minuend,
    input  wire subtrahend,
    output wire [WIDTH-1:0] difference
);
    // Internal signals
    wire [WIDTH-1:0] p; // Propagate signals
    wire [WIDTH-1:0] g; // Generate signals
    wire [WIDTH-1:0] c; // Carry signals
    
    // Step 1: Generate initial p and g values
    // For subtraction: p = minuend ^ subtrahend, g = ~minuend & subtrahend
    assign p[0] = minuend[0] ^ subtrahend;
    assign g[0] = ~minuend[0] & subtrahend;
    
    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : gen_init_pg
            assign p[i] = minuend[i] ^ 1'b0;  // XOR with 0 for higher bits
            assign g[i] = ~minuend[i] & 1'b0; // AND with 0 for higher bits (always 0)
        end
    endgenerate

    // Step 2: Parallel prefix computation for carries
    // Level 1 (pairs)
    wire [WIDTH-1:0] p_l1, g_l1;
    
    assign c[0] = g[0]; // First carry equals first generate
    
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : gen_level1
            if (i == 1) begin
                assign p_l1[i] = p[i] & p[i-1];
                assign g_l1[i] = g[i] | (p[i] & g[i-1]);
                assign c[i] = g_l1[i];
            end
            else begin
                assign p_l1[i] = p[i];
                assign g_l1[i] = g[i];
            end
        end
    endgenerate
    
    // Level 2 (groups of 4)
    wire [WIDTH-1:0] p_l2, g_l2;
    
    generate
        for (i = 2; i < WIDTH; i = i + 1) begin : gen_level2
            if (i == 2 || i == 3) begin
                assign p_l2[i] = p_l1[i] & p_l1[i-2];
                assign g_l2[i] = g_l1[i] | (p_l1[i] & g_l1[i-2]);
                assign c[i] = g_l2[i];
            end
            else begin
                assign p_l2[i] = p_l1[i];
                assign g_l2[i] = g_l1[i];
            end
        end
    endgenerate
    
    // Level 3 (groups of 8)
    wire [WIDTH-1:0] p_l3, g_l3;
    
    generate
        for (i = 4; i < WIDTH; i = i + 1) begin : gen_level3
            if (i >= 4 && i < 8) begin
                assign p_l3[i] = p_l2[i] & p_l2[i-4];
                assign g_l3[i] = g_l2[i] | (p_l2[i] & g_l2[i-4]);
                assign c[i] = g_l3[i];
            end
            else begin
                assign p_l3[i] = p_l2[i];
                assign g_l3[i] = g_l2[i];
            end
        end
    endgenerate
    
    // Step 3: Compute difference using carries
    // difference = minuend ^ subtrahend ^ carry
    assign difference[0] = minuend[0] ^ subtrahend;
    
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : gen_difference
            assign difference[i] = minuend[i] ^ c[i-1];
        end
    endgenerate
    
endmodule

///////////////////////////////////////////////////////////////////////////
// Module: bit_negation
// Description: Performs bitwise NOT operation on input data
///////////////////////////////////////////////////////////////////////////
module bit_negation #(
    parameter WIDTH = 4
) (
    input  wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);

    assign data_out = ~data_in;

endmodule

///////////////////////////////////////////////////////////////////////////
// Module: grant_generator
// Description: Generates final grant signal by bitwise AND of request
//              with negated (req-1) value
///////////////////////////////////////////////////////////////////////////
module grant_generator #(
    parameter WIDTH = 4
) (
    input  wire [WIDTH-1:0] request,
    input  wire [WIDTH-1:0] negated_value,
    output wire [WIDTH-1:0] grant
);

    assign grant = request & negated_value;

endmodule