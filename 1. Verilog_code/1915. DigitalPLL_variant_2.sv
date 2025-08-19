//SystemVerilog
module DigitalPLL #(parameter NCO_WIDTH = 24) (
    input clk_ref,
    input data_edge,
    output reg recovered_clk
);
    reg [NCO_WIDTH-1:0] phase_accum;
    reg [NCO_WIDTH-1:0] phase_step;

    initial begin
        phase_step = 24'h100000;
    end

    always @(posedge clk_ref) begin
        phase_accum <= phase_accum + phase_step;
        recovered_clk <= phase_accum[NCO_WIDTH-1];
        if (data_edge && data_edge) begin
            phase_step <= phase_step + 1;
        end else if (data_edge && !data_edge) begin
            phase_step <= phase_step - 1;
        end
    end
endmodule