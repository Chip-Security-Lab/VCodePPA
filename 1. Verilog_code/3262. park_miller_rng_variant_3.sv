//SystemVerilog
module park_miller_rng_axi_stream (
    input  wire         aclk,
    input  wire         aresetn,
    output reg  [31:0]  m_axis_tdata,
    output reg          m_axis_tvalid,
    input  wire         m_axis_tready,
    output reg          m_axis_tlast
);
    // Park-Miller constants
    parameter A = 16807;
    parameter M = 32'h7FFFFFFF; // 2^31 - 1
    parameter Q = 127773;       // M / A
    parameter R = 2836;         // M % A

    reg  [31:0] rand_val_reg;
    reg  [31:0] q_reg, r_reg;
    reg  [31:0] mult_q_reg, mult_r_reg, mult_a_reg;
    reg  [31:0] temp_reg;
    wire [31:0] wallace_mult_q;
    wire [31:0] wallace_mult_r;

    reg         valid_reg;
    reg         last_reg;

    // Wallace Tree Multiplier for 32x32 bits
    wallace_multiplier_32x32 mult_q_inst (
        .a(rand_val_reg / Q),
        .b(A * (rand_val_reg % Q)),
        .product(wallace_mult_q)
    );
    wallace_multiplier_32x32 mult_r_inst (
        .a(A),
        .b(rand_val_reg % Q),
        .product(wallace_mult_r)
    );

    // AXI-Stream handshake and random value generation
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rand_val_reg   <= 32'd1;
            valid_reg      <= 1'b0;
            m_axis_tdata   <= 32'd0;
            m_axis_tvalid  <= 1'b0;
            m_axis_tlast   <= 1'b0;
            q_reg          <= 32'd0;
            r_reg          <= 32'd0;
            mult_a_reg     <= 32'd0;
            mult_q_reg     <= 32'd0;
            temp_reg       <= 32'd0;
            last_reg       <= 1'b0;
        end else begin
            if (!valid_reg || (m_axis_tvalid && m_axis_tready)) begin
                q_reg      <= rand_val_reg / Q;
                r_reg      <= rand_val_reg % Q;
                mult_a_reg <= wallace_mult_r;
                mult_q_reg <= q_reg * R;
                temp_reg   <= (mult_a_reg - mult_q_reg);
                if ($signed(mult_a_reg - mult_q_reg) <= 0)
                    rand_val_reg <= (mult_a_reg - mult_q_reg) + M;
                else
                    rand_val_reg <= (mult_a_reg - mult_q_reg);

                m_axis_tdata  <= rand_val_reg;
                valid_reg     <= 1'b1;
                last_reg      <= 1'b0; // No packetization, tlast always 0
            end

            // AXI-Stream protocol
            if (valid_reg && m_axis_tready) begin
                m_axis_tvalid <= 1'b1;
                m_axis_tlast  <= last_reg;
                valid_reg     <= 1'b0;
            end else if (valid_reg) begin
                m_axis_tvalid <= 1'b1;
                m_axis_tlast  <= last_reg;
            end else begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast  <= 1'b0;
            end
        end
    end

endmodule

module wallace_multiplier_32x32 (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] product
);
    wire [63:0] full_product;
    wallace_tree_32x32 wallace_tree_inst (
        .a(a),
        .b(b),
        .product(full_product)
    );
    assign product = full_product[31:0];
endmodule

module wallace_tree_32x32 (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [63:0] product
);
    wire [31:0] pp[31:0];
    genvar i;
    generate
        for (i=0; i<32; i=i+1) begin : partial_products
            assign pp[i] = b[i] ? a : 32'd0;
        end
    endgenerate

    // Wallace Tree Reduction
    // First Level
    wire [33:0] sum1[15:0];
    wire [33:0] carry1[15:0];
    generate
        for (i=0; i<16; i=i+1) begin : level1
            wallace_full_adder_32 add1 (
                .a({2'b00, pp[2*i]}),
                .b({1'b0, pp[2*i+1], 1'b0}),
                .cin(34'd0),
                .sum(sum1[i]),
                .carry(carry1[i])
            );
        end
    endgenerate

    // Second Level
    wire [35:0] sum2[7:0];
    wire [35:0] carry2[7:0];
    generate
        for (i=0; i<8; i=i+1) begin : level2
            wallace_full_adder_34 add2 (
                .a({2'b00, sum1[2*i]}),
                .b({1'b0, sum1[2*i+1], 1'b0}),
                .cin({2'b00, carry1[2*i]}),
                .sum(sum2[i]),
                .carry(carry2[i])
            );
        end
    endgenerate

    // Third Level
    wire [37:0] sum3[3:0];
    wire [37:0] carry3[3:0];
    generate
        for (i=0; i<4; i=i+1) begin : level3
            wallace_full_adder_36 add3 (
                .a({2'b00, sum2[2*i]}),
                .b({1'b0, sum2[2*i+1], 1'b0}),
                .cin({2'b00, carry2[2*i]}),
                .sum(sum3[i]),
                .carry(carry3[i])
            );
        end
    endgenerate

    // Fourth Level
    wire [39:0] sum4[1:0];
    wire [39:0] carry4[1:0];
    generate
        for (i=0; i<2; i=i+1) begin : level4
            wallace_full_adder_38 add4 (
                .a({2'b00, sum3[2*i]}),
                .b({1'b0, sum3[2*i+1], 1'b0}),
                .cin({2'b00, carry3[2*i]}),
                .sum(sum4[i]),
                .carry(carry4[i])
            );
        end
    endgenerate

    // Fifth Level
    wire [41:0] sum5;
    wire [41:0] carry5;
    wallace_full_adder_40 add5 (
        .a({2'b00, sum4[0]}),
        .b({1'b0, sum4[1], 1'b0}),
        .cin({2'b00, carry4[0]}),
        .sum(sum5),
        .carry(carry5)
    );

    // Final Addition
    assign product = sum5 + carry5;
endmodule

module wallace_full_adder_32 (
    input  wire [33:0] a,
    input  wire [33:0] b,
    input  wire [33:0] cin,
    output wire [33:0] sum,
    output wire [33:0] carry
);
    assign sum   = a ^ b ^ cin;
    assign carry = ((a & b) | (a & cin) | (b & cin)) << 1;
endmodule

module wallace_full_adder_34 (
    input  wire [35:0] a,
    input  wire [35:0] b,
    input  wire [35:0] cin,
    output wire [35:0] sum,
    output wire [35:0] carry
);
    assign sum   = a ^ b ^ cin;
    assign carry = ((a & b) | (a & cin) | (b & cin)) << 1;
endmodule

module wallace_full_adder_36 (
    input  wire [37:0] a,
    input  wire [37:0] b,
    input  wire [37:0] cin,
    output wire [37:0] sum,
    output wire [37:0] carry
);
    assign sum   = a ^ b ^ cin;
    assign carry = ((a & b) | (a & cin) | (b & cin)) << 1;
endmodule

module wallace_full_adder_38 (
    input  wire [39:0] a,
    input  wire [39:0] b,
    input  wire [39:0] cin,
    output wire [39:0] sum,
    output wire [39:0] carry
);
    assign sum   = a ^ b ^ cin;
    assign carry = ((a & b) | (a & cin) | (b & cin)) << 1;
endmodule

module wallace_full_adder_40 (
    input  wire [41:0] a,
    input  wire [41:0] b,
    input  wire [41:0] cin,
    output wire [41:0] sum,
    output wire [41:0] carry
);
    assign sum   = a ^ b ^ cin;
    assign carry = ((a & b) | (a & cin) | (b & cin)) << 1;
endmodule