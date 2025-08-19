//SystemVerilog
module multi_domain_reset_controller(
    input  wire        clk,
    input  wire        global_rst_n,
    input  wire        por_n,
    input  wire        ext_n,
    input  wire        wdt_n,
    input  wire        sw_n,
    output wire        core_rst_n,
    output wire        periph_rst_n,
    output wire        mem_rst_n
);

    // Stage 1: Detect any reset
    reg                any_reset_stage1;
    reg                valid_stage1;
    wire               any_reset_next;
    assign any_reset_next = ~por_n | ~ext_n | ~wdt_n | ~sw_n;

    // Stage 2: Reset counter update using 2-bit carry lookahead adder
    reg [1:0]          reset_count_stage2;
    reg                valid_stage2;
    reg                any_reset_stage2;

    // Stage 3: Output logic
    reg                core_rst_n_stage3;
    reg                periph_rst_n_stage3;
    reg                mem_rst_n_stage3;
    reg                valid_stage3;
    reg [1:0]          reset_count_stage3;
    reg                any_reset_stage3;

    // Stage 1: Input sampling and any_reset computation
    always @(posedge clk or negedge global_rst_n) begin
        if (!global_rst_n) begin
            any_reset_stage1 <= 1'b1;
            valid_stage1     <= 1'b0;
        end else begin
            any_reset_stage1 <= any_reset_next;
            valid_stage1     <= 1'b1;
        end
    end

    // Stage 2: Reset counter update using 2-bit carry lookahead adder
    reg [1:0]          adder_a;
    reg [1:0]          adder_b;
    reg                adder_cin;
    wire [1:0]         adder_sum;
    wire               adder_cout;

    // Carry Lookahead signals
    wire               g0, g1;    // Generate
    wire               p0, p1;    // Propagate
    wire               c1, c2;

    always @(*) begin
        adder_a   = reset_count_stage2;
        adder_b   = 2'b01;
        adder_cin = 1'b0;
    end

    // Generate and propagate for each bit
    assign g0 = adder_a[0] & adder_b[0];
    assign p0 = adder_a[0] ^ adder_b[0];

    assign g1 = adder_a[1] & adder_b[1];
    assign p1 = adder_a[1] ^ adder_b[1];

    // Carry lookahead logic
    assign c1 = g0 | (p0 & adder_cin);
    assign c2 = g1 | (p1 & g0) | (p1 & p0 & adder_cin);

    // Sum bits
    assign adder_sum[0] = p0 ^ adder_cin;
    assign adder_sum[1] = p1 ^ c1;

    assign adder_cout = c2;

    always @(posedge clk or negedge global_rst_n) begin
        if (!global_rst_n) begin
            reset_count_stage2 <= 2'b00;
            any_reset_stage2   <= 1'b1;
            valid_stage2       <= 1'b0;
        end else begin
            any_reset_stage2 <= any_reset_stage1;
            valid_stage2     <= valid_stage1;
            if (any_reset_stage1) begin
                reset_count_stage2 <= 2'b00;
            end else if (reset_count_stage2 != 2'b11) begin
                reset_count_stage2 <= adder_sum;
            end else begin
                reset_count_stage2 <= reset_count_stage2;
            end
        end
    end

    // Stage 3: Output logic
    always @(posedge clk or negedge global_rst_n) begin
        if (!global_rst_n) begin
            core_rst_n_stage3   <= 1'b0;
            periph_rst_n_stage3 <= 1'b0;
            mem_rst_n_stage3    <= 1'b0;
            reset_count_stage3  <= 2'b00;
            any_reset_stage3    <= 1'b1;
            valid_stage3        <= 1'b0;
        end else begin
            reset_count_stage3  <= reset_count_stage2;
            any_reset_stage3    <= any_reset_stage2;
            valid_stage3        <= valid_stage2;
            if (any_reset_stage2) begin
                core_rst_n_stage3   <= 1'b0;
                periph_rst_n_stage3 <= 1'b0;
                mem_rst_n_stage3    <= 1'b0;
            end else begin
                core_rst_n_stage3   <= (reset_count_stage2 >= 2'b01);
                periph_rst_n_stage3 <= (reset_count_stage2 >= 2'b10);
                mem_rst_n_stage3    <= (reset_count_stage2 == 2'b11);
            end
        end
    end

    // Output assignments: Only assert outputs when valid
    assign core_rst_n   = valid_stage3 ? core_rst_n_stage3   : 1'b0;
    assign periph_rst_n = valid_stage3 ? periph_rst_n_stage3 : 1'b0;
    assign mem_rst_n    = valid_stage3 ? mem_rst_n_stage3    : 1'b0;

endmodule