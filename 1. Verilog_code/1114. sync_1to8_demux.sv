module sync_1to8_demux (
    input wire clock,                   // System clock
    input wire data,                    // Input data
    input wire [2:0] address,           // 3-bit address
    output reg [7:0] outputs            // 8 registered outputs
);
    always @(posedge clock) begin
        outputs <= 8'b0;                // Clear all outputs
        outputs[address] <= data;       // Set selected output
    end
endmodule
