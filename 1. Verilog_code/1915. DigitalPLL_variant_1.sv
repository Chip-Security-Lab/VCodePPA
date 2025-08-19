//SystemVerilog
module DigitalPLL #(parameter NCO_WIDTH = 24) (
    input wire clk_ref,
    input wire data_edge,
    output reg recovered_clk
);
    reg [NCO_WIDTH-1:0] phase_accum;
    reg [NCO_WIDTH-1:0] phase_step = 24'h100000;

    // Buffer registers for phase_step to reduce fanout
    reg [NCO_WIDTH-1:0] phase_step_buf1;
    reg [NCO_WIDTH-1:0] phase_step_buf2;

    // Buffer register for phase_accum MSB to balance load for recovered_clk
    reg recovered_clk_buf;

    // Phase step update logic with buffering
    always @(posedge clk_ref) begin
        // Update phase_step on data_edge
        if (data_edge) begin
            phase_step <= phase_step + 1;
        end
    end

    // Buffer stage 1 for phase_step
    always @(posedge clk_ref) begin
        phase_step_buf1 <= phase_step;
    end

    // Buffer stage 2 for phase_step
    always @(posedge clk_ref) begin
        phase_step_buf2 <= phase_step_buf1;
    end

    // NCO and output logic
    always @(posedge clk_ref) begin
        phase_accum <= phase_accum + phase_step_buf2;
        recovered_clk_buf <= phase_accum[NCO_WIDTH-1];
        recovered_clk <= recovered_clk_buf;
    end

endmodule