//SystemVerilog
module async_peak_detector #(
    parameter W = 12
)(
    input [W-1:0] signal_in,
    input [W-1:0] current_peak,
    input reset_peak,
    output reg [W-1:0] peak_out
);

    wire [W-1:0] peak_candidate;
    wire peak_sel;

    assign peak_sel = reset_peak | (signal_in > current_peak);
    assign peak_candidate = peak_sel ? signal_in : current_peak;

    always @(*) begin
        peak_out = peak_candidate;
    end

endmodule