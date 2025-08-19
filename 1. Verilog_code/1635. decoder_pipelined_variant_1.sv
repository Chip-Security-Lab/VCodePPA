//SystemVerilog
module karatsuba_mult_16bit(
    input clk,
    input req,
    output reg ack,
    input [15:0] a,
    input [15:0] b,
    output reg [31:0] result
);

    reg req_reg;
    wire [7:0] a_high = a[15:8];
    wire [7:0] a_low = a[7:0];
    wire [7:0] b_high = b[15:8];
    wire [7:0] b_low = b[7:0];

    wire [15:0] z0, z1, z2;
    reg [15:0] z0_reg, z1_reg, z2_reg;
    
    wire [7:0] a_sum, b_sum;
    
    // Carry-skip adder for a_high + a_low
    carry_skip_adder_8bit add_a(
        .a(a_high),
        .b(a_low),
        .cin(1'b0),
        .sum(a_sum),
        .cout()
    );
    
    // Carry-skip adder for b_high + b_low
    carry_skip_adder_8bit add_b(
        .a(b_high),
        .b(b_low),
        .cin(1'b0),
        .sum(b_sum),
        .cout()
    );
    
    karatsuba_mult_8bit mult_low(
        .clk(clk),
        .req(req_reg),
        .ack(),
        .a(a_low),
        .b(b_low),
        .result(z0)
    );

    karatsuba_mult_8bit mult_mid(
        .clk(clk),
        .req(req_reg),
        .ack(),
        .a(a_sum),
        .b(b_sum),
        .result(z1)
    );

    karatsuba_mult_8bit mult_high(
        .clk(clk),
        .req(req_reg),
        .ack(),
        .a(a_high),
        .b(b_high),
        .result(z2)
    );

    wire [31:0] z2_shifted = {z2_reg, 16'b0};
    wire [31:0] z1_z2_z0_diff = {8'b0, (z1_reg - z2_reg - z0_reg), 8'b0};
    wire [31:0] z0_extended = {16'b0, z0_reg};
    
    always @(posedge clk) begin
        req_reg <= req;
        z0_reg <= z0;
        z1_reg <= z1;
        z2_reg <= z2;
        ack <= req_reg;
    end

    always @(posedge clk) begin
        if (req_reg) begin
            result <= z2_shifted + z1_z2_z0_diff + z0_extended;
        end
    end

endmodule

module karatsuba_mult_8bit(
    input clk,
    input req,
    output reg ack,
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] result
);

    reg req_reg;
    wire [3:0] a_high = a[7:4];
    wire [3:0] a_low = a[3:0];
    wire [3:0] b_high = b[7:4];
    wire [3:0] b_low = b[3:0];

    wire [7:0] z0, z1, z2;
    reg [7:0] z0_reg, z1_reg, z2_reg;
    
    wire [3:0] a_sum, b_sum;
    
    // Carry-skip adder for a_high + a_low
    carry_skip_adder_4bit add_a(
        .a(a_high),
        .b(a_low),
        .cin(1'b0),
        .sum(a_sum),
        .cout()
    );
    
    // Carry-skip adder for b_high + b_low
    carry_skip_adder_4bit add_b(
        .a(b_high),
        .b(b_low),
        .cin(1'b0),
        .sum(b_sum),
        .cout()
    );
    
    karatsuba_mult_4bit mult_low(
        .clk(clk),
        .req(req_reg),
        .ack(),
        .a(a_low),
        .b(b_low),
        .result(z0)
    );

    karatsuba_mult_4bit mult_mid(
        .clk(clk),
        .req(req_reg),
        .ack(),
        .a(a_sum),
        .b(b_sum),
        .result(z1)
    );

    karatsuba_mult_4bit mult_high(
        .clk(clk),
        .req(req_reg),
        .ack(),
        .a(a_high),
        .b(b_high),
        .result(z2)
    );

    wire [15:0] z2_shifted = {z2_reg, 8'b0};
    wire [15:0] z1_z2_z0_diff = {4'b0, (z1_reg - z2_reg - z0_reg), 4'b0};
    wire [15:0] z0_extended = {8'b0, z0_reg};
    
    always @(posedge clk) begin
        req_reg <= req;
        z0_reg <= z0;
        z1_reg <= z1;
        z2_reg <= z2;
        ack <= req_reg;
    end

    always @(posedge clk) begin
        if (req_reg) begin
            result <= z2_shifted + z1_z2_z0_diff + z0_extended;
        end
    end

endmodule

module karatsuba_mult_4bit(
    input clk,
    input req,
    output reg ack,
    input [3:0] a,
    input [3:0] b,
    output reg [7:0] result
);

    reg req_reg;

    always @(posedge clk) begin
        req_reg <= req;
        ack <= req_reg;
        if (req_reg) begin
            result <= a * b;
        end
    end

endmodule

module decoder_pipelined (
    input clk,
    input req,
    output reg ack,
    input [5:0] addr,
    output reg [15:0] sel_reg
);

    reg req_reg;
    reg [15:0] sel_comb;
    wire [31:0] mult_result;
    
    karatsuba_mult_16bit mult_unit(
        .clk(clk),
        .req(req_reg),
        .ack(),
        .a({10'b0, addr}),
        .b(16'b1),
        .result(mult_result)
    );

    always @* begin
        sel_comb = (req_reg) ? mult_result[15:0] : 16'b0;
    end

    always @(posedge clk) begin
        req_reg <= req;
        ack <= req_reg;
        sel_reg <= sel_comb;
    end

endmodule

// Carry-skip adder implementation for 8-bit operands
module carry_skip_adder_8bit(
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire [7:0] p, g;
    wire [1:0] block_carry;
    wire [1:0] block_propagate;
    
    // Generate and propagate signals
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_prop
            assign p[i] = a[i] ^ b[i];
            assign g[i] = a[i] & b[i];
        end
    endgenerate
    
    // Block propagate signals (4-bit blocks)
    assign block_propagate[0] = &p[3:0];
    assign block_propagate[1] = &p[7:4];
    
    // Block carry signals
    assign block_carry[0] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & cin);
    assign block_carry[1] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & block_carry[0]);
    
    // Carry signals
    wire [8:0] carry;
    assign carry[0] = cin;
    assign carry[1] = g[0] | (p[0] & carry[0]);
    assign carry[2] = g[1] | (p[1] & carry[1]);
    assign carry[3] = g[2] | (p[2] & carry[2]);
    assign carry[4] = block_carry[0];
    assign carry[5] = g[4] | (p[4] & carry[4]);
    assign carry[6] = g[5] | (p[5] & carry[5]);
    assign carry[7] = g[6] | (p[6] & carry[6]);
    assign carry[8] = block_carry[1];
    
    // Sum calculation
    assign sum = p ^ carry[7:0];
    assign cout = carry[8];
endmodule

// Carry-skip adder implementation for 4-bit operands
module carry_skip_adder_4bit(
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [3:0] p, g;
    wire block_propagate;
    
    // Generate and propagate signals
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_prop
            assign p[i] = a[i] ^ b[i];
            assign g[i] = a[i] & b[i];
        end
    endgenerate
    
    // Block propagate signal
    assign block_propagate = &p;
    
    // Block carry signal
    wire block_carry;
    assign block_carry = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & cin);
    
    // Carry signals
    wire [4:0] carry;
    assign carry[0] = cin;
    assign carry[1] = g[0] | (p[0] & carry[0]);
    assign carry[2] = g[1] | (p[1] & carry[1]);
    assign carry[3] = g[2] | (p[2] & carry[2]);
    assign carry[4] = block_carry;
    
    // Sum calculation
    assign sum = p ^ carry[3:0];
    assign cout = carry[4];
endmodule