//SystemVerilog
module QoSBridge #(
    parameter PRIO_LEVELS = 4
)(
    input clk, rst_n,
    input [3:0] prio_in,
    input [31:0] data_in,
    output reg [31:0] data_out
);
    reg [31:0] prio_queues [0:PRIO_LEVELS-1];
    reg [1:0] current_prio;
    reg [1:0] next_prio;
    reg [31:0] next_data_out;

    // Reset logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_prio <= 0;
            data_out <= 0;
        end else begin
            current_prio <= next_prio;
            data_out <= next_data_out;
        end
    end

    // Priority queue update
    always @(posedge clk) begin
        if (rst_n) begin
            prio_queues[prio_in] <= data_in;
        end
    end

    // Priority selection logic
    always @(*) begin
        if (prio_in >= current_prio) begin
            next_prio = prio_in;
            next_data_out = prio_queues[prio_in];
        end else if (current_prio > 0) begin
            next_prio = current_prio - 1;
            next_data_out = prio_queues[current_prio];
        end else begin
            next_prio = current_prio;
            next_data_out = data_out;
        end
    end
endmodule