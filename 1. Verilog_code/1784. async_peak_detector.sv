module async_peak_detector #(
    parameter W = 12
)(
    input [W-1:0] signal_in,
    input [W-1:0] current_peak,
    input reset_peak,
    output [W-1:0] peak_out
);
    // Find peak value
    assign peak_out = reset_peak ? signal_in :
                     (signal_in > current_peak) ? signal_in : current_peak;
endmodule