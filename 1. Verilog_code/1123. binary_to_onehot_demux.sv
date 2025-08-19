module binary_to_onehot_demux (
    input wire data_in,                  // Input data
    input wire [2:0] binary_addr,        // Binary address
    output reg [7:0] one_hot_out         // One-hot outputs with data
);
    reg [7:0] decoder_out;               // Decoded address
    
    always @(*) begin
        // Binary to one-hot decoding
        decoder_out = 8'b0;
        decoder_out[binary_addr] = 1'b1;
        
        // Apply data to all outputs, but only the selected one will be active
        one_hot_out = {8{data_in}} & decoder_out;
    end
endmodule