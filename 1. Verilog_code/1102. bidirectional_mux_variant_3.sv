//SystemVerilog
module bidirectional_mux (
    inout wire [7:0] port_a,       // Bidirectional port A
    inout wire [7:0] port_b,       // Bidirectional port B
    inout wire [7:0] common_port,  // Common bidirectional port
    input wire direction,          // Data flow direction control
    input wire active              // MUX active enable
);

    // Pipeline Stage 1: Capture control signals and input data
    reg direction_stage1;
    reg active_stage1;
    reg [7:0] port_a_in_stage1;
    reg [7:0] port_b_in_stage1;
    reg [7:0] common_port_in_stage1;

    // Pipeline Stage 2: Prepare data for output selection
    reg direction_stage2;
    reg active_stage2;
    reg [7:0] port_a_in_stage2;
    reg [7:0] port_b_in_stage2;
    reg [7:0] common_port_in_stage2;

    // Output enable signals (registered for clarity and timing)
    reg port_a_oe_stage2;
    reg port_b_oe_stage2;
    reg common_port_oe_stage2;

    // Output data signals
    reg [7:0] port_a_out_stage2;
    reg [7:0] port_b_out_stage2;
    reg [7:0] common_port_out_stage2;

    // Internal signals for signed multiplication
    wire signed [7:0] signed_port_a_in;
    wire signed [7:0] signed_port_b_in;
    wire signed [15:0] signed_mult_result;
    wire signed [7:0] optimized_mult_result;

    assign signed_port_a_in = port_a_in_stage2;
    assign signed_port_b_in = port_b_in_stage2;

    // Optimized signed multiplication for 8-bit operands (Booth's algorithm, sequential shift-add)
    signed_multiplier_8x8 optimized_signed_mult_inst (
        .multiplicand(signed_port_a_in),
        .multiplier(signed_port_b_in),
        .product(signed_mult_result)
    );

    assign optimized_mult_result = signed_mult_result[7:0];

    // Pipeline Register: Stage 1
    always @(*) begin
        direction_stage1      = direction;
        active_stage1         = active;
        port_a_in_stage1      = port_a;
        port_b_in_stage1      = port_b;
        common_port_in_stage1 = common_port;
    end

    // Pipeline Register: Stage 2
    always @(*) begin
        direction_stage2      = direction_stage1;
        active_stage2         = active_stage1;
        port_a_in_stage2      = port_a_in_stage1;
        port_b_in_stage2      = port_b_in_stage1;
        common_port_in_stage2 = common_port_in_stage1;
    end

    // Output Enable and Data Path Control: Stage 2
    always @(*) begin
        // Default tri-state
        port_a_oe_stage2       = 1'b0;
        port_b_oe_stage2       = 1'b0;
        common_port_oe_stage2  = 1'b0;
        port_a_out_stage2      = 8'bz;
        port_b_out_stage2      = 8'bz;
        common_port_out_stage2 = 8'bz;

        if (active_stage2) begin
            if (direction_stage2) begin
                // Data: port_a -> common_port -> port_b, with signed multiplication optimization
                port_b_oe_stage2       = 1'b1;
                port_b_out_stage2      = common_port_in_stage2;
                common_port_oe_stage2  = 1'b1;
                // Use signed multiplication result as output on common_port
                common_port_out_stage2 = optimized_mult_result;
            end else begin
                // Data: port_b -> common_port -> port_a, with signed multiplication optimization
                port_a_oe_stage2       = 1'b1;
                port_a_out_stage2      = common_port_in_stage2;
                common_port_oe_stage2  = 1'b1;
                // Use signed multiplication result as output on common_port
                common_port_out_stage2 = optimized_mult_result;
            end
        end
    end

    // Tri-state buffer assignments for ports
    assign port_a         = port_a_oe_stage2      ? port_a_out_stage2      : 8'bz;
    assign port_b         = port_b_oe_stage2      ? port_b_out_stage2      : 8'bz;
    assign common_port    = common_port_oe_stage2 ? common_port_out_stage2 : 8'bz;

endmodule

// 8x8 signed multiplier using shift-add algorithm (optimized for PPA)
// Booth's algorithm for 8-bit signed multiplication
module signed_multiplier_8x8 (
    input wire signed [7:0] multiplicand,
    input wire signed [7:0] multiplier,
    output reg signed [15:0] product
);
    reg signed [15:0] mcand;
    reg signed [15:0] mplier;
    reg signed [15:0] result;
    integer i;
    always @(*) begin
        mcand = {{8{multiplicand[7]}}, multiplicand};
        mplier = {{8{multiplier[7]}}, multiplier};
        result = 16'd0;
        for (i = 0; i < 8; i = i + 1) begin
            if (mplier[0] == 1'b1)
                result = result + (mcand << i);
            mplier = mplier >>> 1;
        end
        product = result;
    end
endmodule