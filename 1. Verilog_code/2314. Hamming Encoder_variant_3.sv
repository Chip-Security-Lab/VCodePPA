//SystemVerilog
module hamming_encoder (
    input  wire        clk,         // Clock input
    input  wire        rst_n,       // Active-low reset
    input  wire        data_valid,  // Input data valid signal
    input  wire [3:0]  data_in,     // 4-bit input data
    output reg  [6:0]  encoded,     // 7-bit encoded output
    output reg         encoded_valid // Output data valid signal
);

    // Pipeline registers for input data
    reg [3:0] data_stage1;
    reg       valid_stage1;
    
    // Intermediate parity calculation registers
    reg parity0_stage1, parity1_stage1, parity2_stage1;
    
    // Pipeline process - Stage 1: Register inputs and compute parities
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 4'b0000;
            valid_stage1 <= 1'b0;
            parity0_stage1 <= 1'b0;
            parity1_stage1 <= 1'b0;
            parity2_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data_in;
            valid_stage1 <= data_valid;
            
            // Pre-compute parity bits in first stage to reduce logic depth
            parity0_stage1 <= data_in[0] ^ data_in[1] ^ data_in[3];
            parity1_stage1 <= data_in[0] ^ data_in[2] ^ data_in[3];
            parity2_stage1 <= data_in[1] ^ data_in[2] ^ data_in[3];
        end
    end
    
    // Pipeline process - Stage 2: Assemble encoded output with calculated parities
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded <= 7'b0000000;
            encoded_valid <= 1'b0;
        end else begin
            encoded_valid <= valid_stage1;
            
            // Encode data using pre-computed parity bits
            encoded[0] <= parity0_stage1;                // p0
            encoded[1] <= parity1_stage1;                // p1
            encoded[2] <= data_stage1[0];                // d0
            encoded[3] <= parity2_stage1;                // p2
            encoded[4] <= data_stage1[1];                // d1
            encoded[5] <= data_stage1[2];                // d2
            encoded[6] <= data_stage1[3];                // d3
        end
    end

endmodule