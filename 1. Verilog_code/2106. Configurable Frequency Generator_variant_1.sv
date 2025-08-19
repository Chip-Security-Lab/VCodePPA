//SystemVerilog
module config_freq_gen(
    input  wire        master_clk,
    input  wire        rstn,
    input  wire [7:0]  freq_sel,
    output reg         out_clk
);

    // Pipeline registers for deeper pipeline (4 stages)
    reg [7:0] counter_stage1;
    reg [7:0] counter_stage2;
    reg [7:0] counter_stage3;
    reg [7:0] counter_stage4;

    reg [7:0] freq_sel_stage1;
    reg [7:0] freq_sel_stage2;
    reg [7:0] freq_sel_stage3;
    reg [7:0] freq_sel_stage4;

    reg       cmp_result_stage1;
    reg       cmp_result_stage2;
    reg       cmp_result_stage3;
    reg       cmp_result_stage4;

    reg       out_clk_stage1;
    reg       out_clk_stage2;
    reg       out_clk_stage3;
    reg       out_clk_stage4;

    // Stage 1: Register input freq_sel and out_clk
    always @(posedge master_clk or negedge rstn) begin
        if (!rstn) begin
            freq_sel_stage1      <= 8'd0;
            counter_stage1       <= 8'd0;
            out_clk_stage1       <= 1'b0;
        end else begin
            freq_sel_stage1      <= freq_sel;
            out_clk_stage1       <= out_clk_stage4;
            if (cmp_result_stage4) begin
                counter_stage1   <= 8'd0;
            end else begin
                counter_stage1   <= counter_stage1 + 8'd1;
            end
        end
    end

    // Stage 2: Register counter and freq_sel, pre-calculate compare
    always @(posedge master_clk or negedge rstn) begin
        if (!rstn) begin
            counter_stage2       <= 8'd0;
            freq_sel_stage2      <= 8'd0;
            cmp_result_stage1    <= 1'b0;
            out_clk_stage2       <= 1'b0;
        end else begin
            counter_stage2       <= counter_stage1;
            freq_sel_stage2      <= freq_sel_stage1;
            cmp_result_stage1    <= (counter_stage1 >= freq_sel_stage1);
            out_clk_stage2       <= out_clk_stage1;
        end
    end

    // Stage 3: Register counter/freq_sel and compare result
    always @(posedge master_clk or negedge rstn) begin
        if (!rstn) begin
            counter_stage3       <= 8'd0;
            freq_sel_stage3      <= 8'd0;
            cmp_result_stage2    <= 1'b0;
            out_clk_stage3       <= 1'b0;
        end else begin
            counter_stage3       <= counter_stage2;
            freq_sel_stage3      <= freq_sel_stage2;
            cmp_result_stage2    <= cmp_result_stage1;
            out_clk_stage3       <= out_clk_stage2;
        end
    end

    // Stage 4: Register counter/freq_sel and compare, update out_clk
    always @(posedge master_clk or negedge rstn) begin
        if (!rstn) begin
            counter_stage4       <= 8'd0;
            freq_sel_stage4      <= 8'd0;
            cmp_result_stage3    <= 1'b0;
            out_clk_stage4       <= 1'b0;
        end else begin
            counter_stage4       <= counter_stage3;
            freq_sel_stage4      <= freq_sel_stage3;
            cmp_result_stage3    <= cmp_result_stage2;
            if (cmp_result_stage2) begin
                out_clk_stage4   <= ~out_clk_stage3;
            end else begin
                out_clk_stage4   <= out_clk_stage3;
            end
        end
    end

    // Final stage: Output register
    always @(posedge master_clk or negedge rstn) begin
        if (!rstn) begin
            cmp_result_stage4    <= 1'b0;
            out_clk              <= 1'b0;
        end else begin
            cmp_result_stage4    <= cmp_result_stage3;
            out_clk              <= out_clk_stage4;
        end
    end

endmodule