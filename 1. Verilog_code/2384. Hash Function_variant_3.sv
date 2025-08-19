//SystemVerilog
// Top Module: hash_function
module hash_function #(
    parameter DATA_WIDTH = 32,
    parameter HASH_WIDTH = 16
) (
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    enable,
    input  wire [DATA_WIDTH-1:0]   data_in,
    input  wire                    last_block,
    output wire [HASH_WIDTH-1:0]   hash_out,
    output wire                    hash_valid
);
    // Internal signals between submodules
    wire [HASH_WIDTH-1:0]  xor_result_s1;
    wire                   last_block_s1;
    wire                   valid_s1;
    
    wire [HASH_WIDTH-1:0]  hash_state_s2;
    wire                   last_block_s2;
    wire                   valid_s2;
    
    // Submodule instantiations
    input_processor #(
        .DATA_WIDTH(DATA_WIDTH),
        .HASH_WIDTH(HASH_WIDTH)
    ) u_input_processor (
        .clk           (clk),
        .rst_n         (rst_n),
        .enable        (enable),
        .data_in       (data_in),
        .last_block    (last_block),
        .xor_result    (xor_result_s1),
        .last_block_out(last_block_s1),
        .valid_out     (valid_s1)
    );
    
    hash_updater #(
        .HASH_WIDTH(HASH_WIDTH)
    ) u_hash_updater (
        .clk             (clk),
        .rst_n           (rst_n),
        .xor_result      (xor_result_s1),
        .last_block_in   (last_block_s1),
        .valid_in        (valid_s1),
        .hash_state      (hash_state_s2),
        .last_block_out  (last_block_s2),
        .valid_out       (valid_s2)
    );
    
    output_generator #(
        .HASH_WIDTH(HASH_WIDTH)
    ) u_output_generator (
        .clk           (clk),
        .rst_n         (rst_n),
        .hash_state    (hash_state_s2),
        .last_block    (last_block_s2),
        .valid_in      (valid_s2),
        .hash_out      (hash_out),
        .hash_valid    (hash_valid)
    );
    
endmodule

// Stage 1: Input processor module - Handles data preprocessing
module input_processor #(
    parameter DATA_WIDTH = 32,
    parameter HASH_WIDTH = 16
) (
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    enable,
    input  wire [DATA_WIDTH-1:0]   data_in,
    input  wire                    last_block,
    output reg  [HASH_WIDTH-1:0]   xor_result,
    output reg                     last_block_out,
    output reg                     valid_out
);
    // Compute XOR between the two halves of the input data
    always @(posedge clk) begin
        if (!rst_n) begin
            xor_result     <= '0;
            last_block_out <= 1'b0;
            valid_out      <= 1'b0;
        end else if (enable) begin
            xor_result     <= data_in[HASH_WIDTH-1:0] ^ data_in[DATA_WIDTH-1:HASH_WIDTH];
            last_block_out <= last_block;
            valid_out      <= enable;
        end else begin
            valid_out      <= 1'b0;
        end
    end
endmodule

// Stage 2: Hash updater module - Updates the hash state
module hash_updater #(
    parameter HASH_WIDTH = 16
) (
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [HASH_WIDTH-1:0]   xor_result,
    input  wire                    last_block_in,
    input  wire                    valid_in,
    output reg  [HASH_WIDTH-1:0]   hash_state,
    output reg                     last_block_out,
    output reg                     valid_out
);
    // Update the hash state based on input result
    always @(posedge clk) begin
        if (!rst_n) begin
            hash_state     <= {HASH_WIDTH{1'b1}}; // Initial value
            last_block_out <= 1'b0;
            valid_out      <= 1'b0;
        end else begin
            if (valid_in) begin
                hash_state     <= hash_state ^ xor_result;
                last_block_out <= last_block_in;
                valid_out      <= valid_in;
            end else begin
                valid_out      <= 1'b0;
            end
        end
    end
endmodule

// Stage 3: Output generator module - Controls the final output
module output_generator #(
    parameter HASH_WIDTH = 16
) (
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [HASH_WIDTH-1:0]   hash_state,
    input  wire                    last_block,
    input  wire                    valid_in,
    output reg  [HASH_WIDTH-1:0]   hash_out,
    output reg                     hash_valid
);
    // Generate final output when the last block is processed
    always @(posedge clk) begin
        if (!rst_n) begin
            hash_out   <= '0;
            hash_valid <= 1'b0;
        end else begin
            hash_valid <= valid_in && last_block;
            if (valid_in && last_block) begin
                hash_out <= hash_state;
            end
        end
    end
endmodule