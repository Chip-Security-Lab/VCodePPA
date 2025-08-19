//SystemVerilog
module preload_shift_reg (
    input clk, 
    input req,           // Request signal (formerly load)
    input [3:0] shift,
    input [15:0] load_data,
    output reg ack,      // Acknowledge signal (formerly ready)
    output reg [15:0] shifted
);

reg [15:0] storage;
reg processing;         // Flag to track processing state

always @(posedge clk) begin
    if (req && !processing) begin
        // On request, store data and enter processing state
        storage <= load_data;
        processing <= 1'b1;
        ack <= 1'b0;    // Clear acknowledge during processing
    end 
    else if (processing) begin
        // Perform shift operation
        shifted <= (storage << shift) | (storage >> (16 - shift));
        processing <= 1'b0;
        ack <= 1'b1;    // Set acknowledge when operation completes
    end
    else begin
        ack <= 1'b0;    // Clear acknowledge when idle
    end
end

endmodule