module serial_to_parallel_demux (
    input wire clk,                      // Clock signal
    input wire rst,                      // Reset signal
    input wire serial_in,                // Serial data input
    input wire load_enable,              // Load control
    output reg [7:0] parallel_out        // Parallel output channels
);
    reg [2:0] bit_counter;               // Bit position counter
    
    always @(posedge clk) begin
        if (rst) begin
            bit_counter <= 3'b0;
            parallel_out <= 8'b0;
        end else if (load_enable) begin
            parallel_out[bit_counter] <= serial_in;
            bit_counter <= bit_counter + 1'b1;
        end
    end
endmodule