//SystemVerilog
// Top-level module: Multi-channel reset filter and detector
module multi_filter_reset_detector(
    input  wire             clock,
    input  wire             reset_n,
    input  wire [3:0]       reset_sources,
    input  wire [3:0]       filter_enable,
    output wire [3:0]       filtered_resets
);

    // Internal wires for each filter channel
    wire [3:0] filtered_resets_internal;

    // Instantiate four filter channels
    genvar idx;
    generate
        for (idx = 0; idx < 4; idx = idx + 1) begin : filter_channels
            // Single reset filter for channel idx
            reset_filter_channel #(
                .COUNTER_WIDTH(3),
                .COUNTER_MAX (3'b111)
            ) u_reset_filter_channel (
                .clk            (clock),
                .rst_n          (reset_n),
                .reset_source   (reset_sources[idx]),
                .filter_enable  (filter_enable[idx]),
                .filtered_reset (filtered_resets_internal[idx])
            );
        end
    endgenerate

    // Output assignment
    assign filtered_resets = filtered_resets_internal;

endmodule

// ---------------------------------------------------------------------------
// Submodule: Single reset filter channel
// Description: Performs glitch filtering and detection for a single reset source.
// ---------------------------------------------------------------------------
module reset_filter_channel #(
    parameter COUNTER_WIDTH = 3,
    parameter [COUNTER_WIDTH-1:0] COUNTER_MAX = {COUNTER_WIDTH{1'b1}}
)(
    input  wire                      clk,
    input  wire                      rst_n,
    input  wire                      reset_source,
    input  wire                      filter_enable,
    output reg                       filtered_reset
);

    reg [COUNTER_WIDTH-1:0] filter_counter;

    // 4-bit carry lookahead adder signals
    wire [COUNTER_WIDTH-1:0] adder_a;
    wire [COUNTER_WIDTH-1:0] adder_b;
    wire                     adder_cin;
    wire [COUNTER_WIDTH-1:0] adder_sum;
    wire                     adder_cout;

    assign adder_a   = filter_counter;
    assign adder_b   = 3'b001;
    assign adder_cin = 1'b0;

    cla_3bit adder_unit (
        .a    (adder_a),
        .b    (adder_b),
        .cin  (adder_cin),
        .sum  (adder_sum),
        .cout (adder_cout)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            filter_counter  <= {COUNTER_WIDTH{1'b0}};
            filtered_reset  <= 1'b0;
        end else begin
            if (reset_source && filter_enable) begin
                if (filter_counter < COUNTER_MAX)
                    filter_counter <= adder_sum;
            end else begin
                filter_counter <= {COUNTER_WIDTH{1'b0}};
            end
            filtered_reset <= (filter_counter == COUNTER_MAX);
        end
    end

endmodule

// ---------------------------------------------------------------------------
// 3-bit Carry Lookahead Adder (CLA) for fast counter increment
// ---------------------------------------------------------------------------
module cla_3bit (
    input  wire [2:0] a,
    input  wire [2:0] b,
    input  wire       cin,
    output wire [2:0] sum,
    output wire       cout
);

    wire [2:0] generate_term;
    wire [2:0] propagate_term;
    wire [2:0] carry;

    assign generate_term[0] = a[0] & b[0];
    assign propagate_term[0] = a[0] ^ b[0];
    assign carry[0] = generate_term[0] | (propagate_term[0] & cin);

    assign generate_term[1] = a[1] & b[1];
    assign propagate_term[1] = a[1] ^ b[1];
    assign carry[1] = generate_term[1] | (propagate_term[1] & carry[0]);

    assign generate_term[2] = a[2] & b[2];
    assign propagate_term[2] = a[2] ^ b[2];
    assign carry[2] = generate_term[2] | (propagate_term[2] & carry[1]);

    assign sum[0] = propagate_term[0] ^ cin;
    assign sum[1] = propagate_term[1] ^ carry[0];
    assign sum[2] = propagate_term[2] ^ carry[1];

    assign cout = carry[2];

endmodule