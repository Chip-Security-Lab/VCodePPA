//SystemVerilog
module heartbeat_gen #(
    parameter IDLE_CYCLES = 1000,
    parameter PULSE_CYCLES = 50
)(
    input clk,
    input rst,
    output reg heartbeat
);

reg [31:0] counter;
reg [31:0] counter_buf1, counter_buf2;
reg compare_result;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        counter <= 0;
        counter_buf1 <= 0;
        counter_buf2 <= 0;
        compare_result <= 0;
        heartbeat <= 0;
    end else begin
        // Buffer for counter value to reduce fan-out
        counter_buf1 <= counter;
        counter_buf2 <= counter;
        
        // Compute comparison result using buffered counter
        compare_result <= (counter_buf1 >= IDLE_CYCLES);
        
        if (counter_buf2 < IDLE_CYCLES + PULSE_CYCLES) begin
            counter <= counter + 1;
            heartbeat <= compare_result;
        end else begin
            counter <= 0;
            heartbeat <= 0;
        end
    end
end
endmodule