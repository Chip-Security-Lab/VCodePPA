//SystemVerilog
module normalizer #(
    parameter WIDTH = 16
)(
    input wire [WIDTH-1:0] in_data,
    output reg [WIDTH-1:0] normalized_data,
    output reg [$clog2(WIDTH)-1:0] shift_count
);

    wire [WIDTH-1:0] two_comp;
    wire [WIDTH-1:0] subtract_b;
    wire [WIDTH:0] carry; // extra bit for carry-out
    wire [WIDTH-1:0] diff;

    // Parallel Prefix Subtractor (8-bit version shown, parameterized for WIDTH)
    parallel_prefix_subtractor #(
        .WIDTH(WIDTH)
    ) u_parallel_prefix_subtractor (
        .a({{WIDTH-1{1'b0}}, 1'b1}), // 1
        .b(in_data),
        .diff(two_comp)
    );

    // Find Leading One using parallel priority encoder
    wire [$clog2(WIDTH)-1:0] lead_one_pos;
    priority_encoder #(
        .WIDTH(WIDTH)
    ) u_priority_encoder (
        .data_in(in_data),
        .pos_out(lead_one_pos)
    );

    always @* begin
        shift_count = WIDTH - 1 - lead_one_pos;
        normalized_data = in_data << shift_count;
    end

endmodule

// Parallel Prefix Subtractor (Kogge-Stone style, parameterized)
module parallel_prefix_subtractor #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] diff
);

    wire [WIDTH-1:0] b_inv;
    wire             c_in;
    wire [WIDTH:0]   carry;
    wire [WIDTH-1:0] p, g;

    assign b_inv = ~b;
    assign c_in = 1'b1; // For two's complement subtraction (a - b = a + ~b + 1)
    assign carry[0] = c_in;

    assign p = a ^ b_inv;
    assign g = a & b_inv;

    genvar i, j, stage;
    generate
        // Kogge-Stone prefix computation
        wire [WIDTH-1:0] gp [0:$clog2(WIDTH)]; // stage, bit
        for (i = 0; i < WIDTH; i = i + 1) begin : init
            assign gp[0][i] = g[i];
        end

        for (stage = 1; stage <= $clog2(WIDTH); stage = stage + 1) begin : stages
            for (i = 0; i < WIDTH; i = i + 1) begin : loop
                if (i >= (1 << (stage - 1)))
                    assign gp[stage][i] = gp[stage-1][i] | (p[i] & gp[stage-1][i - (1 << (stage - 1))]);
                else
                    assign gp[stage][i] = gp[stage-1][i];
            end
        end

        // Carry generation
        for (i = 0; i < WIDTH; i = i + 1) begin : carry_gen
            if (i == 0)
                assign carry[i+1] = g[i] | (p[i] & c_in);
            else
                assign carry[i+1] = gp[$clog2(WIDTH)][i-1] | (p[i] & carry[i]);
        end
    endgenerate

    // Difference computation
    assign diff = p ^ carry[WIDTH-1:0];

endmodule

// Parallel Priority Encoder (leading 1 detector)
module priority_encoder #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] data_in,
    output reg  [$clog2(WIDTH)-1:0] pos_out
);
    integer i;
    always @* begin
        pos_out = 0;
        for (i = WIDTH-1; i >= 0; i = i - 1) begin
            if (data_in[i])
                pos_out = i[$clog2(WIDTH)-1:0];
        end
    end
endmodule