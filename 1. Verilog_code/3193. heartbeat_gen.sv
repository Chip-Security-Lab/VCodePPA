module heartbeat_gen #(
    parameter IDLE_CYCLES = 1000,
    parameter PULSE_CYCLES = 50
)(
    input clk,
    input rst,
    output reg heartbeat
);
reg [31:0] counter;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        counter <= 0;
        heartbeat <= 0;
    end else begin
        if (counter < IDLE_CYCLES + PULSE_CYCLES) begin
            counter <= counter + 1;
            heartbeat <= (counter >= IDLE_CYCLES);
        end else begin
            counter <= 0;
            heartbeat <= 0;
        end
    end
end
endmodule

