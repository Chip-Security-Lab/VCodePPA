//SystemVerilog
// Top-level module
module lfsr_div #(parameter POLY=8'hB4) (
    input  logic clk,
    input  logic rst,
    output logic clk_out
);
    // Inter-module signals
    logic       feedback;
    logic [7:0] lfsr;
    logic [7:0] next_lfsr;
    logic       next_clk_out;

    // LFSR feedback generation submodule
    lfsr_feedback_gen #(
        .POLY(POLY)
    ) feedback_gen_inst (
        .lfsr       (lfsr),
        .feedback   (feedback),
        .next_lfsr  (next_lfsr)
    );

    // Clock output detection submodule
    lfsr_detector detector_inst (
        .next_lfsr    (next_lfsr),
        .next_clk_out (next_clk_out)
    );

    // Sequential logic submodule
    lfsr_seq_logic seq_logic_inst (
        .clk          (clk),
        .rst          (rst),
        .next_lfsr    (next_lfsr),
        .next_clk_out (next_clk_out),
        .lfsr         (lfsr),
        .clk_out      (clk_out)
    );
endmodule

// Submodule for LFSR feedback generation
module lfsr_feedback_gen #(parameter POLY=8'hB4) (
    input  logic [7:0] lfsr,
    output logic       feedback,
    output logic [7:0] next_lfsr
);
    assign feedback = lfsr[7];
    assign next_lfsr = {lfsr[6:0], 1'b0} ^ (feedback ? POLY : 8'h00);
endmodule

// Submodule for detecting when to generate clock output
module lfsr_detector (
    input  logic [7:0] next_lfsr,
    output logic       next_clk_out
);
    assign next_clk_out = (next_lfsr == 8'h00);
endmodule

// Submodule for sequential logic
module lfsr_seq_logic (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] next_lfsr,
    input  logic       next_clk_out,
    output logic [7:0] lfsr,
    output logic       clk_out
);
    always_ff @(posedge clk) begin
        if(rst) begin
            lfsr <= 8'hFF;
            clk_out <= 1'b0;
        end else begin
            lfsr <= next_lfsr;
            clk_out <= next_clk_out;
        end
    end
endmodule