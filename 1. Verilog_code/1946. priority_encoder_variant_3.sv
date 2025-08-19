//SystemVerilog
module priority_encoder #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] request,
    output reg [$clog2(WIDTH)-1:0] grant_id,
    output reg valid
);
    wire [WIDTH-1:0] one_hot;
    wire [$clog2(WIDTH)-1:0] binary_id;
    wire add_carry_out;

    // Han-Carlson 8-bit adder instantiation for binary_id calculation
    han_carlson_adder_8bit han_carlson_inst (
        .a(request),
        .b(8'b0),
        .sum(one_hot),
        .carry_out(add_carry_out)
    );

    // One-hot to binary encoder
    function [$clog2(WIDTH)-1:0] one_hot_to_bin;
        input [WIDTH-1:0] one_hot_val;
        integer j;
        begin
            one_hot_to_bin = 0;
            for (j = 0; j < WIDTH; j = j + 1) begin
                if (one_hot_val[j])
                    one_hot_to_bin = j;
            end
        end
    endfunction

    always @(*) begin
        valid = |request;
        grant_id = one_hot_to_bin(one_hot & {WIDTH{valid}});
    end

endmodule

module han_carlson_adder_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] sum,
    output wire       carry_out
);
    // Generate and Propagate
    wire [7:0] g, p;
    assign g = a & b;
    assign p = a ^ b;

    // Stage 0: initial generate/propagate
    wire [7:0] gnpg_0, pp_0;
    assign gnpg_0 = g;
    assign pp_0   = p;

    // Stage 1
    wire [7:0] gnpg_1, pp_1;
    assign gnpg_1[0] = gnpg_0[0];
    assign pp_1[0]   = pp_0[0];
    genvar i1;
    generate
        for (i1 = 1; i1 < 8; i1 = i1 + 1) begin : STAGE1
            assign gnpg_1[i1] = gnpg_0[i1] | (pp_0[i1] & gnpg_0[i1-1]);
            assign pp_1[i1]   = pp_0[i1] & pp_0[i1-1];
        end
    endgenerate

    // Stage 2
    wire [7:0] gnpg_2, pp_2;
    assign gnpg_2[0] = gnpg_1[0];
    assign gnpg_2[1] = gnpg_1[1];
    assign pp_2[0]   = pp_1[0];
    assign pp_2[1]   = pp_1[1];
    genvar i2;
    generate
        for (i2 = 2; i2 < 8; i2 = i2 + 1) begin : STAGE2
            assign gnpg_2[i2] = gnpg_1[i2] | (pp_1[i2] & gnpg_1[i2-2]);
            assign pp_2[i2]   = pp_1[i2] & pp_1[i2-2];
        end
    endgenerate

    // Stage 3
    wire [7:0] gnpg_3, pp_3;
    assign gnpg_3[0] = gnpg_2[0];
    assign gnpg_3[1] = gnpg_2[1];
    assign gnpg_3[2] = gnpg_2[2];
    assign gnpg_3[3] = gnpg_2[3];
    assign pp_3[0]   = pp_2[0];
    assign pp_3[1]   = pp_2[1];
    assign pp_3[2]   = pp_2[2];
    assign pp_3[3]   = pp_2[3];
    genvar i3;
    generate
        for (i3 = 4; i3 < 8; i3 = i3 + 1) begin : STAGE3
            assign gnpg_3[i3] = gnpg_2[i3] | (pp_2[i3] & gnpg_2[i3-4]);
            assign pp_3[i3]   = pp_2[i3] & pp_2[i3-4];
        end
    endgenerate

    // Pre-carry
    wire [7:0] carry;
    assign carry[0] = 1'b0;
    assign carry[1] = gnpg_0[0];
    assign carry[2] = gnpg_1[1];
    assign carry[3] = gnpg_2[2];
    assign carry[4] = gnpg_3[3];
    assign carry[5] = gnpg_3[4];
    assign carry[6] = gnpg_3[5];
    assign carry[7] = gnpg_3[6];
    assign carry_out = gnpg_3[7];

    // Final sum
    assign sum = p ^ carry;

endmodule