//SystemVerilog
module glitch_free_clk_mux(
    input  wire clk_a,
    input  wire clk_b,
    input  wire select,   // 0 for clk_a, 1 for clk_b
    input  wire rst,
    output wire clk_out
);

    // Stage 1: Synchronize select signal for both clock domains
    reg select_a_sync_stage1, select_a_sync_stage2;
    reg select_b_sync_stage1, select_b_sync_stage2;

    // Synchronize select to clk_a domain
    always @(posedge clk_a or posedge rst) begin
        if (rst) begin
            select_a_sync_stage1 <= 1'b0;
            select_a_sync_stage2 <= 1'b0;
        end else begin
            select_a_sync_stage1 <= ~select;
            select_a_sync_stage2 <= select_a_sync_stage1;
        end
    end

    // Synchronize select to clk_b domain
    always @(posedge clk_b or posedge rst) begin
        if (rst) begin
            select_b_sync_stage1 <= 1'b0;
            select_b_sync_stage2 <= 1'b0;
        end else begin
            select_b_sync_stage1 <= select;
            select_b_sync_stage2 <= select_b_sync_stage1;
        end
    end

    // Stage 2: Registered select flags for clock domains
    reg select_a_flag;
    reg select_b_flag;

    // Control for clk_a domain
    always @(negedge clk_a or posedge rst) begin
        if (rst)
            select_a_flag <= 1'b0;
        else
            select_a_flag <= select_a_sync_stage2 & ~select_b_flag;
    end

    // Control for clk_b domain
    always @(negedge clk_b or posedge rst) begin
        if (rst)
            select_b_flag <= 1'b0;
        else
            select_b_flag <= select_b_sync_stage2 & ~select_a_flag;
    end

    // Stage 3: Pipeline registered output select signals
    reg select_a_out_stage;
    reg select_b_out_stage;

    always @(posedge clk_a or posedge rst) begin
        if (rst)
            select_a_out_stage <= 1'b0;
        else
            select_a_out_stage <= select_a_flag;
    end

    always @(posedge clk_b or posedge rst) begin
        if (rst)
            select_b_out_stage <= 1'b0;
        else
            select_b_out_stage <= select_b_flag;
    end

    // Stage 4: Output clock MUX logic
    // Clear and structured data path with pipelining
    assign clk_out = (select_b_out_stage & ~select_a_out_stage) ? clk_b :
                     (select_a_out_stage & ~select_b_out_stage) ? clk_a :
                     1'b0;

endmodule