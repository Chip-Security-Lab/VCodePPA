module QoSBridge #(
    parameter PRIO_LEVELS=4
)(
    input clk, rst_n,
    input [3:0] prio_in,
    input [31:0] data_in,
    output reg [31:0] data_out
);
    reg [31:0] prio_queues [0:PRIO_LEVELS-1];
    reg [1:0] current_prio;

    always @(posedge clk) begin
        if (prio_in > current_prio) begin
            current_prio <= prio_in;
            data_out <= prio_queues[prio_in];
        end else if (current_prio > 0) begin
            current_prio <= current_prio - 1;
            data_out <= prio_queues[current_prio];
        end
        prio_queues[prio_in] <= data_in;
    end
endmodule