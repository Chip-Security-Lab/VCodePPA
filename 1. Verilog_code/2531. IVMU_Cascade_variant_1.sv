//SystemVerilog
// SystemVerilog
// Combinational Karatsuba multiplication for 4x4 bits
// This module implements the purely combinational Karatsuba algorithm.
module karatsuba_comb_4x4 (
    input wire [3:0] i_a,
    input wire [3:0] i_b,
    output wire [7:0] o_p
);

    // Split inputs into high and low parts (2 bits each)
    wire [1:0] a_h, a_l;
    wire [1:0] b_h, b_l;

    assign a_h = i_a[3:2];
    assign a_l = i_a[1:0];
    assign b_h = i_b[3:2];
    assign b_l = i_b[1:0];

    // Step 1: Calculate P1 = a_l * b_l (2x2 multiplication)
    // Result is 4 bits
    wire [3:0] p1_o;
    assign p1_o = a_l * b_l;

    // Step 2: Calculate P2 = a_h * b_h (2x2 multiplication)
    // Result is 4 bits
    wire [3:0] p2_o;
    assign p2_o = a_h * b_h;

    // Step 3: Calculate S1 = a_l + a_h and S2 = b_l + b_h (2-bit addition)
    // Sums can be up to 3+3=6, requiring 3 bits
    wire [2:0] s1_o, s2_o;
    assign s1_o = a_l + a_h;
    assign s2_o = b_l + b_h;

    // Step 4: Calculate P3 = S1 * S2 (3x3 multiplication)
    // Product can be up to 6*6=36, requiring 6 bits
    wire [5:0] p3_o;
    assign p3_o = s1_o * s2_o;

    // Step 5: Calculate the intermediate term (a_l*b_h + a_h*b_l)
    // Using the Karatsuba identity: (a_l*b_h + a_h*b_l) = P3 - P1 - P2
    // Need to extend P1 and P2 to 6 bits for subtraction
    wire [5:0] p1_ext, p2_ext;
    assign p1_ext = {2'b0, p1_o};
    assign p2_ext = {2'b0, p2_o};

    wire [5:0] mid_o; // Result of subtraction is 6 bits (max value 18)
    assign mid_o = p3_o - p1_ext - p2_ext;

    // Step 6: Combine the terms to get the final product
    // p = (P2 << 4) + (intermediate_term << 2) + P1
    wire [7:0] term1, term2, term3;

    // P2 << 4
    assign term1 = {p2_o, 4'b0};

    // intermediate_term << 2
    // mid_o is 6 bits, shift left by 2 results in 8 bits
    assign term2 = {mid_o, 2'b0};

    // P1 (padded to 8 bits)
    assign term3 = {4'b0, p1_o};

    // Sum the terms
    assign o_p = term1 + term2 + term3;

endmodule

// SystemVerilog
// Pipelined 4x4 Karatsuba multiplier with Valid-Ready handshake.
// Separates combinational Karatsuba logic into a sub-module.
module karatsuba_mul_4x4_valid_ready (
    input wire clk,
    input wire rst_n,

    // Input interface (Valid-Ready)
    input wire i_valid,
    input wire [3:0] i_a,
    input wire [3:0] i_b,
    output logic i_ready,

    // Output interface (Valid-Ready)
    input wire o_ready,
    output logic o_valid,
    output logic [7:0] o_p
);

    // Internal registers to hold input data for pipelined processing
    logic [3:0] reg_a;
    logic [3:0] reg_b;

    // Output of the combinational Karatsuba logic
    wire [7:0] comb_p;

    // Registers to hold the output data and valid signal
    logic [7:0] reg_p;
    logic reg_o_valid;

    // Instantiate the combinational Karatsuba multiplier
    karatsuba_comb_4x4 u_karatsuba_comb (
        .i_a (reg_a),
        .i_b (reg_b),
        .o_p (comb_p)
    );

    // Combinational logic for input ready signal
    // Ready to accept new input if the output buffer is empty
    // or if the output is being consumed in the current cycle.
    assign i_ready = !reg_o_valid || o_ready;

    // Assign output signals from registers
    assign o_valid = reg_o_valid;
    assign o_p = reg_p;

    // Synchronous logic for handshake and data pipelining
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_a <= '0;
            reg_b <= '0;
            reg_p <= '0;
            reg_o_valid <= 1'b0;
        end else begin
            // Capture input data when input is valid and module is ready
            if (i_valid && i_ready) begin
                reg_a <= i_a;
                reg_b <= i_b;
            end

            // Manage output valid and data register
            if (reg_o_valid && o_ready) begin // Output consumed
                reg_o_valid <= 1'b0;
            end else if (i_valid && i_ready) begin // New input accepted -> new output available next cycle
                reg_o_valid <= 1'b1;
                reg_p <= comb_p; // Load new result from combinational logic
            end
            // If neither condition met, reg_o_valid and reg_p hold their values
        end
    end

endmodule