//SystemVerilog
module bcd2bin_pipeline (
    input              clk,
    input              rst_n,
    input              enable,
    input      [7:0]   bcd_in,
    output reg [6:0]   bin_out,
    output reg         valid_out
);

    // Stage 1: Split nibbles (combinational), valid propagation
    wire [3:0] bcd_high_comb;
    wire [3:0] bcd_low_comb;
    assign bcd_high_comb = bcd_in[7:4];
    assign bcd_low_comb  = bcd_in[3:0];

    // Stage 2: Multiply high nibble by 10, valid propagation
    wire [7:0] mul10_comb;
    assign mul10_comb = bcd_high_comb * 8'd10;

    // Stage 1 Registers moved after combination logic (forward retiming)
    reg [7:0] mul10_stage1;
    reg [3:0] bcd_low_stage1;
    reg       valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul10_stage1   <= 8'd0;
            bcd_low_stage1 <= 4'd0;
            valid_stage1   <= 1'b0;
        end else begin
            if (enable) begin
                mul10_stage1   <= mul10_comb;
                bcd_low_stage1 <= bcd_low_comb;
                valid_stage1   <= 1'b1;
            end else begin
                valid_stage1   <= 1'b0;
            end
        end
    end

    // Stage 2: Add, output valid propagation
    reg [6:0] bin_out_stage2;
    reg       valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_out_stage2 <= 7'd0;
            valid_stage2   <= 1'b0;
        end else begin
            bin_out_stage2 <= mul10_stage1[6:0] + bcd_low_stage1;
            valid_stage2   <= valid_stage1;
        end
    end

    // Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_out   <= 7'd0;
            valid_out <= 1'b0;
        end else begin
            bin_out   <= bin_out_stage2;
            valid_out <= valid_stage2;
        end
    end

endmodule