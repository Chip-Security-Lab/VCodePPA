//SystemVerilog
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

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_prio <= 0;
            data_out <= 0;
        end else begin
            // Update the priority queue with the incoming data
            prio_queues[prio_in] <= data_in;

            // Optimize the comparison logic using two's complement addition
            if (prio_in > current_prio) begin
                current_prio <= prio_in;
            end else if (current_prio > 0) begin
                current_prio <= current_prio + 2'b11; // current_prio - 1 using two's complement
            end
            
            // Output the data from the current priority queue
            data_out <= prio_queues[current_prio];
        end
    end
endmodule