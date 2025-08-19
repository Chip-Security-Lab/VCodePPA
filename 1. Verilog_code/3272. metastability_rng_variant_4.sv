//SystemVerilog
module metastability_rng_valid_ready (
    input  wire        clk_sys,
    input  wire        rst_n,
    input  wire        meta_clk,
    input  wire        rng_ready,
    output reg  [7:0]  rng_data,
    output reg         rng_valid
);

    reg meta_stage1, meta_stage2;
    reg [7:0] random_value;

    // Metastable input using clock domain crossing
    always @(posedge meta_clk or negedge rst_n) begin
        if (!rst_n)
            meta_stage1 <= 1'b0;
        else
            meta_stage1 <= ~meta_stage1;
    end

    // Capture metastable signal
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n)
            meta_stage2 <= 1'b0;
        else 
            meta_stage2 <= meta_stage1;
    end

    // Optimized valid-ready handshake and random value update
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            random_value <= 8'h42;
            rng_data     <= 8'h42;
            rng_valid    <= 1'b0;
        end else begin
            // 优化后的比较链
            if (!rng_valid || (rng_valid && rng_ready)) begin
                random_value <= {random_value[6:0], meta_stage2 ^ random_value[7]};
                rng_data     <= {random_value[6:0], meta_stage2 ^ random_value[7]};
                rng_valid    <= 1'b1;
            end
            // 保持当前状态，无需else分支赋值
        end
    end

endmodule