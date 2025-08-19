module sync_fir_filter #(
    parameter DATA_W = 12,
    parameter TAP_W = 8,
    parameter TAPS = 4
)(
    input clk, rst,
    input [DATA_W-1:0] sample_in,
    input [TAP_W-1:0] coeffs [TAPS-1:0],
    output reg [DATA_W+TAP_W-1:0] filtered_out
);
    reg [DATA_W-1:0] delay_line [TAPS-1:0];
    reg [DATA_W+TAP_W-1:0] acc;
    integer i;
    
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAPS; i = i + 1)
                delay_line[i] <= 0;
            filtered_out <= 0;
        end else begin
            // Shift samples through delay line
            for (i = TAPS-1; i > 0; i = i - 1)
                delay_line[i] <= delay_line[i-1];
            delay_line[0] <= sample_in;
            
            // Compute output (dot product)
            acc = 0;
            for (i = 0; i < TAPS; i = i + 1)
                acc = acc + (delay_line[i] * coeffs[i]);
            
            filtered_out <= acc;
        end
    end
endmodule