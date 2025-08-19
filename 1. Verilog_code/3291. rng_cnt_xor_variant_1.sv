//SystemVerilog
module rng_cnt_xor_11_pipeline(
    input            clk,
    input            rst,
    input            en,
    output reg [7:0] rnd,
    output           valid_out
);

    // Stage 1: Counter update
    reg [7:0] cnt_stage1;
    reg       valid_stage1;

    // Stage 2: Prepare for XOR (split rotate and pass)
    reg [7:0] cnt_stage2;
    reg [7:0] cnt_rot_stage2;
    reg       valid_stage2;

    // Stage 3: XOR computation
    reg [7:0] xor_result_stage3;
    reg       valid_stage3;

    // Stage 4: Output register
    reg [7:0] rnd_stage4;
    reg       valid_stage4;

    // Stage 1: Counter
    always @(posedge clk) begin
        if (rst) begin
            cnt_stage1   <= 8'd0;
            valid_stage1 <= 1'b0;
        end else if (en) begin
            cnt_stage1   <= cnt_stage1 + 1'b1;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end

    // Stage 2: Rotate and pass counter, valid
    always @(posedge clk) begin
        if (rst) begin
            cnt_stage2      <= 8'd0;
            cnt_rot_stage2  <= 8'd0;
            valid_stage2    <= 1'b0;
        end else begin
            cnt_stage2      <= cnt_stage1;
            cnt_rot_stage2  <= {cnt_stage1[3:0], cnt_stage1[7:4]};
            valid_stage2    <= valid_stage1;
        end
    end

    // Stage 3: XOR computation
    always @(posedge clk) begin
        if (rst) begin
            xor_result_stage3 <= 8'd0;
            valid_stage3      <= 1'b0;
        end else begin
            xor_result_stage3 <= cnt_stage2 ^ cnt_rot_stage2;
            valid_stage3      <= valid_stage2;
        end
    end

    // Stage 4: Output register
    always @(posedge clk) begin
        if (rst) begin
            rnd_stage4   <= 8'd0;
            valid_stage4 <= 1'b0;
        end else begin
            rnd_stage4   <= xor_result_stage3;
            valid_stage4 <= valid_stage3;
        end
    end

    // Output assignment
    always @(posedge clk) begin
        if (rst) begin
            rnd <= 8'd0;
        end else begin
            rnd <= rnd_stage4;
        end
    end

    assign valid_out = valid_stage4;

endmodule