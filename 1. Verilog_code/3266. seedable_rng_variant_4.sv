//SystemVerilog
module seedable_rng_pipeline (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        load_seed,
    input  wire [31:0] seed_value,
    input  wire        start,
    input  wire        flush,
    output wire [31:0] random_data,
    output wire        valid
);

    // Pipeline valid chain
    reg  valid_stage1;
    reg  valid_stage2;
    reg  valid_stage3;
    reg  valid_stage4;

    // Pipeline seed control chain
    reg  load_seed_stage1;
    reg  load_seed_stage2;
    reg  load_seed_stage3;
    reg  load_seed_stage4;

    reg [31:0] seed_value_stage1;
    reg [31:0] seed_value_stage2;
    reg [31:0] seed_value_stage3;
    reg [31:0] seed_value_stage4;

    // Pipeline state registers
    reg [31:0] state_stage1;
    reg [31:0] xor_result_stage2;
    reg [31:0] next_state_stage3;
    reg [31:0] state_stage4;

    // Pipeline enable logic
    wire stage1_enable = start | valid_stage1;

    // --- Stage 1: Latch input/state, propagate seed control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1        <= 32'h1;
            valid_stage1        <= 1'b0;
            load_seed_stage1    <= 1'b0;
            seed_value_stage1   <= 32'b0;
        end else if (flush) begin
            state_stage1        <= 32'h1;
            valid_stage1        <= 1'b0;
            load_seed_stage1    <= 1'b0;
            seed_value_stage1   <= 32'b0;
        end else if (stage1_enable) begin
            if (load_seed) begin
                state_stage1        <= seed_value;
                load_seed_stage1    <= 1'b1;
                seed_value_stage1   <= seed_value;
            end else begin
                state_stage1        <= state_stage1;
                load_seed_stage1    <= 1'b0;
                seed_value_stage1   <= 32'b0;
            end
            valid_stage1 <= start | valid_stage1;
        end
    end

    // --- Stage 2: XOR computation
    // (Breaks up the calculation for better balancing)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_result_stage2   <= 32'h1;
            valid_stage2        <= 1'b0;
            load_seed_stage2    <= 1'b0;
            seed_value_stage2   <= 32'b0;
        end else if (flush) begin
            xor_result_stage2   <= 32'h1;
            valid_stage2        <= 1'b0;
            load_seed_stage2    <= 1'b0;
            seed_value_stage2   <= 32'b0;
        end else if (valid_stage1) begin
            if (load_seed_stage1) begin
                xor_result_stage2   <= seed_value_stage1;
                load_seed_stage2    <= 1'b1;
                seed_value_stage2   <= seed_value_stage1;
            end else begin
                xor_result_stage2   <= {31'b0, state_stage1[31] ^ state_stage1[21] ^ state_stage1[1] ^ state_stage1[0]};
                load_seed_stage2    <= 1'b0;
                seed_value_stage2   <= 32'b0;
            end
            valid_stage2 <= valid_stage1;
        end
    end

    // --- Stage 3: Next-state construction
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_state_stage3   <= 32'h1;
            valid_stage3        <= 1'b0;
            load_seed_stage3    <= 1'b0;
            seed_value_stage3   <= 32'b0;
        end else if (flush) begin
            next_state_stage3   <= 32'h1;
            valid_stage3        <= 1'b0;
            load_seed_stage3    <= 1'b0;
            seed_value_stage3   <= 32'b0;
        end else if (valid_stage2) begin
            if (load_seed_stage2) begin
                next_state_stage3   <= seed_value_stage2;
                load_seed_stage3    <= 1'b1;
                seed_value_stage3   <= seed_value_stage2;
            end else begin
                next_state_stage3   <= {state_stage1[30:0], xor_result_stage2[0]};
                load_seed_stage3    <= 1'b0;
                seed_value_stage3   <= 32'b0;
            end
            valid_stage3 <= valid_stage2;
        end
    end

    // --- Stage 4: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage4        <= 32'h1;
            valid_stage4        <= 1'b0;
            load_seed_stage4    <= 1'b0;
            seed_value_stage4   <= 32'b0;
        end else if (flush) begin
            state_stage4        <= 32'h1;
            valid_stage4        <= 1'b0;
            load_seed_stage4    <= 1'b0;
            seed_value_stage4   <= 32'b0;
        end else if (valid_stage3) begin
            if (load_seed_stage3) begin
                state_stage4        <= seed_value_stage3;
                load_seed_stage4    <= 1'b1;
                seed_value_stage4   <= seed_value_stage3;
            end else begin
                state_stage4        <= next_state_stage3;
                load_seed_stage4    <= 1'b0;
                seed_value_stage4   <= 32'b0;
            end
            valid_stage4 <= valid_stage3;
        end
    end

    assign random_data = state_stage4;
    assign valid = valid_stage4;

endmodule