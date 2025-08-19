module ptp_timestamp #(
    parameter CLOCK_PERIOD_NS = 4
)(
    input clk,
    input rst,
    input pps,
    input [63:0] ptp_delay,
    output reg [95:0] tx_timestamp,
    output reg ts_valid
);
    reg [63:0] ns_counter;
    reg [31:0] sub_ns;
    reg pps_sync;

    always @(posedge clk) begin
        if (rst) begin
            ns_counter <= 0;
            sub_ns <= 0;
            ts_valid <= 0;
        end else begin
            sub_ns <= sub_ns + CLOCK_PERIOD_NS;
            if (sub_ns >= 1000) begin
                ns_counter <= ns_counter + 1;
                sub_ns <= sub_ns - 1000;
            end
            
            if (pps) begin
                ns_counter <= ptp_delay;
                pps_sync <= 1;
            end
            
            if (pps_sync) begin
                tx_timestamp <= {ns_counter, sub_ns};
                ts_valid <= 1;
                pps_sync <= 0;
            end else begin
                ts_valid <= 0;
            end
        end
    end
endmodule
