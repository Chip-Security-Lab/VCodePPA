//SystemVerilog
// Top-level module with structured pipeline
module async_block_cipher #(
    parameter BLOCK_SIZE = 16
) (
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   data_valid_in,
    input  wire [BLOCK_SIZE-1:0]  plaintext, 
    input  wire [BLOCK_SIZE-1:0]  key,
    output wire                   data_valid_out,
    output wire [BLOCK_SIZE-1:0]  ciphertext
);
    // Pipeline stage signals
    wire [BLOCK_SIZE-1:0] xor_stage_data;
    wire                  xor_stage_valid;
    
    // Control signals for pipeline flow
    reg                   pipeline_ready;
    
    // Instantiate XOR layer module - First pipeline stage
    xor_layer #(
        .DATA_WIDTH(BLOCK_SIZE)
    ) u_xor_layer (
        .clk         (clk),
        .rst_n       (rst_n),
        .data_valid_in(data_valid_in),
        .data_in     (plaintext),
        .key         (key),
        .data_valid_out(xor_stage_valid),
        .data_out    (xor_stage_data),
        .downstream_ready(pipeline_ready)
    );
    
    // Instantiate substitution layer module - Second pipeline stage
    substitution_layer #(
        .BLOCK_SIZE(BLOCK_SIZE)
    ) u_substitution_layer (
        .clk         (clk),
        .rst_n       (rst_n),
        .data_valid_in(xor_stage_valid),
        .data_in     (xor_stage_data),
        .data_valid_out(data_valid_out),
        .data_out    (ciphertext)
    );
    
    // Pipeline flow control
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipeline_ready <= 1'b1;
        end else begin
            pipeline_ready <= data_valid_out || !xor_stage_valid;
        end
    end
    
endmodule

// Module for the XOR encryption layer with pipelined structure
module xor_layer #(
    parameter DATA_WIDTH = 16
) (
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    data_valid_in,
    input  wire [DATA_WIDTH-1:0]   data_in,
    input  wire [DATA_WIDTH-1:0]   key,
    input  wire                    downstream_ready,
    output reg                     data_valid_out,
    output reg  [DATA_WIDTH-1:0]   data_out
);
    // XOR operation with key
    // Split the XOR operation to improve timing with pipeline registers
    reg [DATA_WIDTH/2-1:0] xor_low_part;
    reg [DATA_WIDTH/2-1:0] xor_high_part;
    reg                    valid_internal;
    
    // First stage: Compute XOR for low and high parts separately
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_low_part  <= {(DATA_WIDTH/2){1'b0}};
            xor_high_part <= {(DATA_WIDTH/2){1'b0}};
            valid_internal <= 1'b0;
        end else if (downstream_ready) begin
            xor_low_part  <= data_in[DATA_WIDTH/2-1:0] ^ key[DATA_WIDTH/2-1:0];
            xor_high_part <= data_in[DATA_WIDTH-1:DATA_WIDTH/2] ^ key[DATA_WIDTH-1:DATA_WIDTH/2];
            valid_internal <= data_valid_in;
        end
    end
    
    // Second stage: Combine the results
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {DATA_WIDTH{1'b0}};
            data_valid_out <= 1'b0;
        end else if (downstream_ready) begin
            data_out <= {xor_high_part, xor_low_part};
            data_valid_out <= valid_internal;
        end
    end
    
endmodule

// Module for the substitution layer with optimized data path
module substitution_layer #(
    parameter BLOCK_SIZE = 16
) (
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   data_valid_in,
    input  wire [BLOCK_SIZE-1:0]  data_in,
    output reg                    data_valid_out,
    output reg  [BLOCK_SIZE-1:0]  data_out
);
    // Intermediate signals for staged substitution
    wire [BLOCK_SIZE-1:0] sub_results;
    reg  [BLOCK_SIZE-1:0] data_in_reg;
    reg                   valid_stage1;
    
    // Register input data
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= {BLOCK_SIZE{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            data_in_reg <= data_in;
            valid_stage1 <= data_valid_in;
        end
    end
    
    // Non-linear substitution operation with reduced logic depth
    genvar i;
    generate
        for (i = 0; i < BLOCK_SIZE/4; i = i + 1) begin : sub_blocks
            // Using more localized references to reduce long paths
            wire [3:0] current_nibble = data_in_reg[i*4+:4];
            wire [3:0] next_nibble = data_in_reg[((i+1)%(BLOCK_SIZE/4))*4+:4];
            
            // Compute substitution
            assign sub_results[i*4+:4] = current_nibble + next_nibble;
        end
    endgenerate
    
    // Register the substitution results
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {BLOCK_SIZE{1'b0}};
            data_valid_out <= 1'b0;
        end else begin
            data_out <= sub_results;
            data_valid_out <= valid_stage1;
        end
    end
    
endmodule