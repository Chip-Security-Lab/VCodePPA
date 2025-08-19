//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Module: xor_stream_cipher
// Description: Enhanced XOR stream cipher with pipelined data path
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////
module xor_stream_cipher #(
    parameter KEY_WIDTH  = 8,
    parameter DATA_WIDTH = 16
) (
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [KEY_WIDTH-1:0]    key,
    input  wire [DATA_WIDTH-1:0]   data_in,
    input  wire                    valid_in,
    output reg  [DATA_WIDTH-1:0]   data_out,
    output reg                     valid_out
);

    // Key processing pipeline - moved deeper into pipeline
    reg [KEY_WIDTH-1:0]  key_reg;
    reg [KEY_WIDTH-1:0]  key_rotated;
    
    // Data pipeline registers
    reg [DATA_WIDTH-1:0] data_pipeline;
    reg                  valid_pipeline;
    reg [DATA_WIDTH-1:0] expanded_key;
    
    // First stage - register inputs only
    // Moving computation to later stages to reduce input-to-register delay
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_reg        <= {KEY_WIDTH{1'b0}};
            data_pipeline  <= {DATA_WIDTH{1'b0}};
            valid_pipeline <= 1'b0;
        end else begin
            if (valid_in) begin
                // Register inputs directly without computation
                key_reg        <= key;
                data_pipeline  <= data_in;
                valid_pipeline <= 1'b1;
            end else begin
                valid_pipeline <= 1'b0;
            end
        end
    end

    // Second stage - perform key processing and encryption
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_rotated   <= {KEY_WIDTH{1'b0}};
            expanded_key  <= {DATA_WIDTH{1'b0}};
            data_out      <= {DATA_WIDTH{1'b0}};
            valid_out     <= 1'b0;
        end else begin
            if (valid_pipeline) begin
                // Generate rotated key
                key_rotated <= {key_reg[0], key_reg[KEY_WIDTH-1:1]};
                
                // Key processing with XOR operation
                // Use immediate result to generate expanded key
                expanded_key <= {DATA_WIDTH/KEY_WIDTH{key_reg ^ {key_reg[0], key_reg[KEY_WIDTH-1:1]}}};
                
                // Perform XOR encryption in the same stage
                data_out  <= data_pipeline ^ {DATA_WIDTH/KEY_WIDTH{key_reg ^ {key_reg[0], key_reg[KEY_WIDTH-1:1]}}};
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule