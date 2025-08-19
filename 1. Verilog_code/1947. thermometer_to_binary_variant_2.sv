//SystemVerilog

module thermometer_to_binary #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] thermo_in,
    output reg [$clog2(WIDTH):0] binary_out
);
    wire [$clog2(WIDTH):0] sum_out;

    brent_kung_adder_8bit u_brent_kung_adder_8bit (
        .a(thermo_in),
        .b(8'b0),
        .sum(sum_out),
        .carry_out()
    );

    always @(*) begin
        binary_out = sum_out;
    end

endmodule

module brent_kung_adder_8bit(
    input  [7:0] a,
    input  [7:0] b,
    output [8:0] sum,
    output       carry_out
);
    wire [7:0] generate_0, propagate_0;
    wire [7:0] generate_1, propagate_1;
    wire [7:0] generate_2, propagate_2;
    wire [7:0] generate_3, propagate_3;
    wire [7:0] carry_chain;
    wire [7:0] local_sum;
    wire       local_carry_out;

    // Stage 0: Initial propagate/generate
    assign generate_0 = a & b;
    assign propagate_0 = a ^ b;

    // Stage 1 Generate
    assign generate_1[0] = generate_0[0];
    assign generate_1[1] = generate_0[1] | (propagate_0[1] & generate_0[0]);
    assign generate_1[2] = generate_0[2];
    assign generate_1[3] = generate_0[3] | (propagate_0[3] & generate_0[2]);
    assign generate_1[4] = generate_0[4];
    assign generate_1[5] = generate_0[5] | (propagate_0[5] & generate_0[4]);
    assign generate_1[6] = generate_0[6];
    assign generate_1[7] = generate_0[7] | (propagate_0[7] & generate_0[6]);

    // Stage 1 Propagate
    assign propagate_1[0] = propagate_0[0];
    assign propagate_1[1] = propagate_0[1] & propagate_0[0];
    assign propagate_1[2] = propagate_0[2];
    assign propagate_1[3] = propagate_0[3] & propagate_0[2];
    assign propagate_1[4] = propagate_0[4];
    assign propagate_1[5] = propagate_0[5] & propagate_0[4];
    assign propagate_1[6] = propagate_0[6];
    assign propagate_1[7] = propagate_0[7] & propagate_0[6];

    // Stage 2 Generate
    assign generate_2[0] = generate_1[0];
    assign generate_2[1] = generate_1[1];
    assign generate_2[2] = generate_1[2] | (propagate_1[2] & generate_1[0]);
    assign generate_2[3] = generate_1[3] | (propagate_1[3] & generate_1[1]);
    assign generate_2[4] = generate_1[4];
    assign generate_2[5] = generate_1[5];
    assign generate_2[6] = generate_1[6] | (propagate_1[6] & generate_1[4]);
    assign generate_2[7] = generate_1[7] | (propagate_1[7] & generate_1[5]);

    // Stage 2 Propagate
    assign propagate_2[0] = propagate_1[0];
    assign propagate_2[1] = propagate_1[1];
    assign propagate_2[2] = propagate_1[2] & propagate_1[0];
    assign propagate_2[3] = propagate_1[3] & propagate_1[1];
    assign propagate_2[4] = propagate_1[4];
    assign propagate_2[5] = propagate_1[5];
    assign propagate_2[6] = propagate_1[6] & propagate_1[4];
    assign propagate_2[7] = propagate_1[7] & propagate_1[5];

    // Stage 3 Generate
    assign generate_3[0] = generate_2[0];
    assign generate_3[1] = generate_2[1];
    assign generate_3[2] = generate_2[2];
    assign generate_3[3] = generate_2[3];
    assign generate_3[4] = generate_2[4] | (propagate_2[4] & generate_2[0]);
    assign generate_3[5] = generate_2[5] | (propagate_2[5] & generate_2[1]);
    assign generate_3[6] = generate_2[6] | (propagate_2[6] & generate_2[2]);
    assign generate_3[7] = generate_2[7] | (propagate_2[7] & generate_2[3]);

    // Stage 3 Propagate
    assign propagate_3[0] = propagate_2[0];
    assign propagate_3[1] = propagate_2[1];
    assign propagate_3[2] = propagate_2[2];
    assign propagate_3[3] = propagate_2[3];
    assign propagate_3[4] = propagate_2[4] & propagate_2[0];
    assign propagate_3[5] = propagate_2[5] & propagate_2[1];
    assign propagate_3[6] = propagate_2[6] & propagate_2[2];
    assign propagate_3[7] = propagate_2[7] & propagate_2[3];

    // Carry chain assignments (split into always blocks for modularity)
    reg [7:0] carry_temp;
    always @(*) begin
        carry_temp[0] = 1'b0;
        carry_temp[1] = generate_0[0];
        carry_temp[2] = generate_1[1];
        carry_temp[3] = generate_2[2];
        carry_temp[4] = generate_3[3];
        carry_temp[5] = generate_3[4];
        carry_temp[6] = generate_3[5];
        carry_temp[7] = generate_3[6];
    end
    assign carry_chain = carry_temp;

    reg local_carry;
    always @(*) begin
        local_carry = generate_3[7];
    end
    assign carry_out = local_carry;

    // Sum assignments (split into always blocks for modularity)
    reg [7:0] sum_temp;
    always @(*) begin
        sum_temp[0] = propagate_0[0] ^ carry_chain[0];
        sum_temp[1] = propagate_0[1] ^ carry_chain[1];
        sum_temp[2] = propagate_0[2] ^ carry_chain[2];
        sum_temp[3] = propagate_0[3] ^ carry_chain[3];
        sum_temp[4] = propagate_0[4] ^ carry_chain[4];
        sum_temp[5] = propagate_0[5] ^ carry_chain[5];
        sum_temp[6] = propagate_0[6] ^ carry_chain[6];
        sum_temp[7] = propagate_0[7] ^ carry_chain[7];
    end
    assign local_sum = sum_temp;

    reg sum_carry;
    always @(*) begin
        sum_carry = carry_out;
    end

    assign sum = {sum_carry, local_sum};

endmodule