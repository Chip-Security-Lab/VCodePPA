//SystemVerilog
module ring_osc_rng (
    input wire system_clk,
    input wire reset_n,
    output reg [7:0] random_byte
);
    // Buffered oscillator counters
    reg [3:0] osc_counters [3:0];
    reg [3:0] osc_counters_buf [3:0];

    // Buffered loop indices
    reg [1:0] index_i_buf;
    reg [1:0] index_j_buf;

    // Buffered adder inputs
    reg [7:0] adder_a_buf;
    reg [7:0] adder_b_buf;

    wire [3:0] osc_bits;
    reg [3:0] osc_bits_buf;

    integer idx_i;
    always @(posedge system_clk or negedge reset_n) begin
        if (!reset_n) begin
            for (idx_i = 0; idx_i < 4; idx_i = idx_i + 1)
                osc_counters[idx_i] <= idx_i + 1;
        end else begin
            for (idx_i = 0; idx_i < 4; idx_i = idx_i + 1)
                osc_counters[idx_i] <= osc_counters[idx_i] + (idx_i + 1);
        end
    end

    // Buffer osc_counters to reduce fanout
    integer idx_buf;
    always @(posedge system_clk or negedge reset_n) begin
        if (!reset_n) begin
            for (idx_buf = 0; idx_buf < 4; idx_buf = idx_buf + 1)
                osc_counters_buf[idx_buf] <= idx_buf + 1;
        end else begin
            for (idx_buf = 0; idx_buf < 4; idx_buf = idx_buf + 1)
                osc_counters_buf[idx_buf] <= osc_counters[idx_buf];
        end
    end

    // Buffer loop index i for downstream usage if needed
    always @(posedge system_clk or negedge reset_n) begin
        if (!reset_n)
            index_i_buf <= 2'd0;
        else
            index_i_buf <= idx_i[1:0];
    end

    // Derive oscillator outputs using buffered osc_counters
    genvar j;
    generate
        for (j = 0; j < 4; j = j + 1) begin : osc_gen
            assign osc_bits[j] = osc_counters_buf[j][3];
        end
    endgenerate

    // Buffer osc_bits to reduce fanout
    always @(posedge system_clk or negedge reset_n) begin
        if (!reset_n)
            osc_bits_buf <= 4'd0;
        else
            osc_bits_buf <= osc_bits;
    end

    // Random byte register update using 8-bit carry lookahead adder
    wire [7:0] adder_a_wire;
    wire [7:0] adder_b_wire;
    wire [7:0] adder_sum;

    assign adder_a_wire = {random_byte[3:0], osc_bits_buf};
    assign adder_b_wire = 8'hA5;

    // Buffer adder inputs to reduce fanout
    always @(posedge system_clk or negedge reset_n) begin
        if (!reset_n) begin
            adder_a_buf <= 8'd0;
            adder_b_buf <= 8'd0;
        end else begin
            adder_a_buf <= adder_a_wire;
            adder_b_buf <= adder_b_wire;
        end
    end

    wire [7:0] carry_generate;
    wire [7:0] carry_propagate;
    wire [8:0] carry;

    assign carry[0] = 1'b0;

    genvar k;
    generate
        for (k = 0; k < 8; k = k + 1) begin : cla_gen
            assign carry_generate[k] = adder_a_buf[k] & adder_b_buf[k];
            assign carry_propagate[k] = adder_a_buf[k] ^ adder_b_buf[k];
            assign carry[k+1] = carry_generate[k] | (carry_propagate[k] & carry[k]);
            assign adder_sum[k] = carry_propagate[k] ^ carry[k];
        end
    endgenerate

    always @(posedge system_clk or negedge reset_n) begin
        if (!reset_n)
            random_byte <= 8'h42;
        else
            random_byte <= adder_sum;
    end
endmodule