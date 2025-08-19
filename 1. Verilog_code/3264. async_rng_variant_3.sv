//SystemVerilog
module async_rng (
    input  wire        clk_fast,
    input  wire        clk_slow,
    input  wire        rst_n,
    output wire [15:0] random_val
);

    // Stage 1: Fast-running counter (free-running on clk_fast)
    reg [15:0] fast_counter_q;
    always @(posedge clk_fast or negedge rst_n) begin
        if (!rst_n)
            fast_counter_q <= 16'h0000;
        else
            fast_counter_q <= fast_counter_q + 16'h0001;
    end

    // Stage 2: Synchronize fast_counter to clk_slow domain using two-stage synchronizer
    reg [15:0] sync1_q, sync2_q;
    always @(posedge clk_slow or negedge rst_n) begin
        if (!rst_n) begin
            sync1_q <= 16'h0000;
            sync2_q <= 16'h0000;
        end else begin
            sync1_q <= fast_counter_q;
            sync2_q <= sync1_q;
        end
    end

    // Stage 3: Optimized random value generation pipeline
    reg [15:0] rand1_q, rand2_q;

    wire [15:0] xor_shifted;
    assign xor_shifted = sync2_q ^ {rand1_q[14:0], 1'b0};

    always @(posedge clk_slow or negedge rst_n) begin
        if (!rst_n)
            rand1_q <= 16'h0001;
        else if (sync2_q >= 16'h8000)
            rand1_q <= xor_shifted;
        else if (sync2_q >= 16'h4000)
            rand1_q <= xor_shifted;
        else if (sync2_q >= 16'h2000 && sync2_q < 16'h4000)
            rand1_q <= xor_shifted;
        else if (sync2_q >= 16'h1000 && sync2_q < 16'h2000)
            rand1_q <= xor_shifted;
        else
            rand1_q <= xor_shifted;
    end

    always @(posedge clk_slow or negedge rst_n) begin
        if (!rst_n)
            rand2_q <= 16'h0001;
        else
            rand2_q <= rand1_q;
    end

    assign random_val = rand2_q;

endmodule