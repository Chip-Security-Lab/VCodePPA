//SystemVerilog
module binary_to_onehot_demux (
    input wire clk,                      // Clock input
    input wire rst_n,                    // Active low reset
    input wire data_in,                  // Input data
    input wire [2:0] binary_addr,        // Binary address
    output reg [7:0] one_hot_out         // One-hot outputs with data
);
    // Internal pipeline registers for improved timing
    reg [2:0] binary_addr_r1;            // Registered address
    reg data_in_r1;                      // Registered data input
    reg [7:0] decoder_out;               // Decoded address
    
    // Stage 1: Register inputs for timing improvement
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary_addr_r1 <= 3'b000;
            data_in_r1 <= 1'b0;
        end else begin
            binary_addr_r1 <= binary_addr;
            data_in_r1 <= data_in;
        end
    end
    
    // Stage 2: Binary to one-hot decoding with registered inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoder_out <= 8'b0;
        end else begin
            decoder_out <= 8'b0;
            decoder_out[binary_addr_r1] <= 1'b1;
        end
    end
    
    // Stage 3: Apply data to all outputs based on decoded address
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            one_hot_out <= 8'b0;
        end else begin
            one_hot_out <= {8{data_in_r1}} & decoder_out;
        end
    end
endmodule