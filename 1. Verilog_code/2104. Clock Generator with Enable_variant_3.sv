//SystemVerilog
module clk_gen_with_enable(
    input  wire i_ref_clk,    // Reference clock input
    input  wire i_rst,        // Active high reset
    input  wire i_enable,     // Module enable
    output wire o_clk         // Clock output
);

    // Buffer stage for i_ref_clk to reduce fanout
    reg ref_clk_buf1;
    reg ref_clk_buf2;
    always @(posedge i_ref_clk or posedge i_rst) begin
        if (i_rst) begin
            ref_clk_buf1 <= 1'b0;
            ref_clk_buf2 <= 1'b0;
        end else begin
            ref_clk_buf1 <= 1'b1;
            ref_clk_buf2 <= ref_clk_buf1;
        end
    end

    wire buffered_ref_clk = ref_clk_buf2;

    // Stage 1: Sample enable signal with reset synchronization
    reg enable_stage1;
    always @(posedge buffered_ref_clk or posedge i_rst) begin
        if (i_rst)
            enable_stage1 <= 1'b0;
        else
            enable_stage1 <= i_enable;
    end

    // Stage 2: Pipeline clock gating control
    reg enable_stage2;
    always @(posedge buffered_ref_clk or posedge i_rst) begin
        if (i_rst)
            enable_stage2 <= 1'b0;
        else
            enable_stage2 <= enable_stage1;
    end

    // Buffer stage for enable_stage2 (high fanout)
    reg enable_stage2_buf1;
    reg enable_stage2_buf2;
    always @(posedge buffered_ref_clk or posedge i_rst) begin
        if (i_rst) begin
            enable_stage2_buf1 <= 1'b0;
            enable_stage2_buf2 <= 1'b0;
        end else begin
            enable_stage2_buf1 <= enable_stage2;
            enable_stage2_buf2 <= enable_stage2_buf1;
        end
    end

    wire buffered_enable_stage2 = enable_stage2_buf2;

    // Stage 3: Output clock gating (registered output)
    reg gated_clk;
    always @(posedge buffered_ref_clk or posedge i_rst) begin
        if (i_rst)
            gated_clk <= 1'b0;
        else if (buffered_enable_stage2)
            gated_clk <= ~gated_clk;
        else
            gated_clk <= 1'b0;
    end

    // Output assignment: Pass through gated clock when enabled, else zero
    assign o_clk = buffered_enable_stage2 ? gated_clk : 1'b0;

endmodule