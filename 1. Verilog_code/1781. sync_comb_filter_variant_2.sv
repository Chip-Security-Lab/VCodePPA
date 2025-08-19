//SystemVerilog
module sync_comb_filter #(
    parameter W = 12,
    parameter DELAY = 8
)(
    input clk, rst_n, enable,
    input [W-1:0] din,
    output reg [W-1:0] dout
);

    // Pipeline stage 1: Input and delay line shift
    reg [W-1:0] delay_line_stage1 [DELAY-1:0];
    reg [W-1:0] din_stage1;
    reg enable_stage1;
    integer i;

    // Pipeline stage 2: Comb filter calculation
    reg [W-1:0] din_stage2;
    reg [W-1:0] delayed_stage2;
    reg enable_stage2;

    // Pipeline stage 1 logic
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < DELAY; i = i + 1)
                delay_line_stage1[i] <= 0;
            din_stage1 <= 0;
            enable_stage1 <= 0;
        end else begin
            // Shift values in delay line
            for (i = DELAY-1; i > 0; i = i - 1)
                delay_line_stage1[i] <= delay_line_stage1[i-1];
            delay_line_stage1[0] <= din;
            
            // Register input and control signals
            din_stage1 <= din;
            enable_stage1 <= enable;
        end
    end

    // Pipeline stage 2 logic
    always @(posedge clk) begin
        if (!rst_n) begin
            din_stage2 <= 0;
            delayed_stage2 <= 0;
            enable_stage2 <= 0;
            dout <= 0;
        end else begin
            // Register stage 1 outputs
            din_stage2 <= din_stage1;
            delayed_stage2 <= delay_line_stage1[DELAY-1];
            enable_stage2 <= enable_stage1;
            
            // Comb filter calculation
            if (enable_stage2)
                dout <= din_stage2 - delayed_stage2;
        end
    end

endmodule