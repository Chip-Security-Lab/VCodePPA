//SystemVerilog
module mwc_random_gen (
    input  logic        clock,
    input  logic        reset,
    output logic [31:0] random_data
);
    // Stage 1: Register the state
    logic [31:0] m_w_stage1, m_z_stage1;
    logic        valid_stage1;

    // Stage 2: Split high/low, multiply
    logic [15:0] m_z_low16_stage2, m_z_high16_stage2;
    logic [15:0] m_w_low16_stage2, m_w_high16_stage2;
    logic [31:0] mz_mult_stage2, mw_mult_stage2;
    logic        valid_stage2;

    // Stage 3: Add high part, get next state
    logic [31:0] mz_sum_stage3, mw_sum_stage3;
    logic [31:0] mz_next_stage3, mw_next_stage3;
    logic        valid_stage3;

    // Stage 4: Shift, add, output
    logic [31:0] mz_shifted_stage4;
    logic [31:0] random_sum_stage4;
    logic        valid_stage4;

    // State registers (pipeline input)
    logic [31:0] m_w_reg, m_z_reg;

    // Pipeline flush logic
    logic flush_pipeline;
    assign flush_pipeline = reset;

    // Pipeline Stage 1: State input
    always_ff @(posedge clock) begin
        if (reset) begin
            m_w_reg      <= 32'h12345678;
            m_z_reg      <= 32'h87654321;
            m_w_stage1   <= 32'h12345678;
            m_z_stage1   <= 32'h87654321;
            valid_stage1 <= 1'b0;
        end else begin
            m_w_stage1   <= m_w_reg;
            m_z_stage1   <= m_z_reg;
            valid_stage1 <= 1'b1;
        end
    end

    // Pipeline Stage 2: Split and multiply
    always_ff @(posedge clock) begin
        if (flush_pipeline) begin
            m_z_low16_stage2  <= 16'b0;
            m_z_high16_stage2 <= 16'b0;
            m_w_low16_stage2  <= 16'b0;
            m_w_high16_stage2 <= 16'b0;
            mz_mult_stage2    <= 32'b0;
            mw_mult_stage2    <= 32'b0;
            valid_stage2      <= 1'b0;
        end else begin
            m_z_low16_stage2  <= m_z_stage1[15:0];
            m_z_high16_stage2 <= m_z_stage1[31:16];
            m_w_low16_stage2  <= m_w_stage1[15:0];
            m_w_high16_stage2 <= m_w_stage1[31:16];
            mz_mult_stage2    <= 32'd36969  * m_z_stage1[15:0];
            mw_mult_stage2    <= 32'd18000  * m_w_stage1[15:0];
            valid_stage2      <= valid_stage1;
        end
    end

    // Pipeline Stage 3: Adder (next state)
    wire [31:0] mz_sum_adder, mw_sum_adder;
    carry_lookahead_adder_32 mz_adder_stage3 (
        .a   (mz_mult_stage2),
        .b   ({16'b0, m_z_high16_stage2}),
        .cin (1'b0),
        .sum (mz_sum_adder),
        .cout()
    );
    carry_lookahead_adder_32 mw_adder_stage3 (
        .a   (mw_mult_stage2),
        .b   ({16'b0, m_w_high16_stage2}),
        .cin (1'b0),
        .sum (mw_sum_adder),
        .cout()
    );

    always_ff @(posedge clock) begin
        if (flush_pipeline) begin
            mz_sum_stage3   <= 32'b0;
            mw_sum_stage3   <= 32'b0;
            mz_next_stage3  <= 32'b0;
            mw_next_stage3  <= 32'b0;
            valid_stage3    <= 1'b0;
        end else begin
            mz_sum_stage3   <= mz_sum_adder;
            mw_sum_stage3   <= mw_sum_adder;
            mz_next_stage3  <= mz_sum_adder;
            mw_next_stage3  <= mw_sum_adder;
            valid_stage3    <= valid_stage2;
        end
    end

    // Pipeline Stage 4: Output calculation
    wire [31:0] mz_shifted_wire;
    assign mz_shifted_wire = mz_next_stage3 << 16;

    wire [31:0] random_sum_wire;
    carry_lookahead_adder_32 random_adder_stage4 (
        .a   (mz_shifted_wire),
        .b   (mw_next_stage3),
        .cin (1'b0),
        .sum (random_sum_wire),
        .cout()
    );

    always_ff @(posedge clock) begin
        if (flush_pipeline) begin
            mz_shifted_stage4  <= 32'b0;
            random_sum_stage4  <= 32'b0;
            valid_stage4       <= 1'b0;
        end else begin
            mz_shifted_stage4  <= mz_shifted_wire;
            random_sum_stage4  <= random_sum_wire;
            valid_stage4       <= valid_stage3;
        end
    end

    // State update for next cycle
    always_ff @(posedge clock) begin
        if (reset) begin
            m_z_reg <= 32'h87654321;
            m_w_reg <= 32'h12345678;
        end else begin
            m_z_reg <= mz_next_stage3;
            m_w_reg <= mw_next_stage3;
        end
    end

    // Output assignment
    assign random_data = valid_stage4 ? random_sum_stage4 : 32'b0;

endmodule

// 32位先行进位加法器
module carry_lookahead_adder_32 (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic        cin,
    output logic [31:0] sum,
    output logic        cout
);
    logic [31:0] p, g;
    logic [32:0] c;

    assign p = a ^ b; // 传递
    assign g = a & b; // 产生

    assign c[0] = cin;
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : cla_loop
            assign c[i+1] = g[i] | (p[i] & c[i]);
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate

    assign cout = c[32];
endmodule