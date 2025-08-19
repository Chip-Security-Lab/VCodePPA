//SystemVerilog
///////////////////////////////////////////////////////////
// File: counter_mode_cipher.v
// Description: Top module for counter mode cipher implementation
// Version: IEEE 1364-2005
// Features: Pipelined data path with improved structure
///////////////////////////////////////////////////////////

module counter_mode_cipher #(
    parameter CTR_WIDTH = 16,
    parameter DATA_WIDTH = 32
) (
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     enable,
    input  wire                     encrypt,
    input  wire [CTR_WIDTH-1:0]     init_ctr,
    input  wire [DATA_WIDTH-1:0]    data_in,
    input  wire [DATA_WIDTH-1:0]    key,
    output wire [DATA_WIDTH-1:0]    data_out,
    output wire                     data_valid
);

    // Pipeline stage signals - clearly named for data flow tracking
    wire [CTR_WIDTH-1:0]    counter_value;       // Stage 1: Counter value
    reg  [CTR_WIDTH-1:0]    counter_value_r;     // Registered counter value
    
    wire [DATA_WIDTH-1:0]   encrypted_ctr;       // Stage 2: Encrypted counter
    reg  [DATA_WIDTH-1:0]   encrypted_ctr_r;     // Registered encrypted counter
    
    reg  [DATA_WIDTH-1:0]   data_in_r;           // Input data pipeline register
    reg                     enable_r1, enable_r2; // Control signal pipeline
    
    // Stage 1: Counter Generation
    counter_manager #(
        .CTR_WIDTH(CTR_WIDTH)
    ) u_counter_manager (
        .clk           (clk),
        .reset         (reset),
        .enable        (enable),
        .init_ctr      (init_ctr),
        .counter_out   (counter_value)
    );
    
    // Stage 2: Counter Encryption
    ctr_encryptor #(
        .CTR_WIDTH    (CTR_WIDTH),
        .DATA_WIDTH   (DATA_WIDTH)
    ) u_ctr_encryptor (
        .counter      (counter_value_r),
        .key          (key),
        .encrypted_ctr(encrypted_ctr)
    );
    
    // Stage 3: Output Processing
    output_processor #(
        .DATA_WIDTH   (DATA_WIDTH)
    ) u_output_processor (
        .clk          (clk),
        .reset        (reset),
        .enable       (enable_r2),
        .data_in      (data_in_r),
        .encrypted_ctr(encrypted_ctr_r),
        .data_out     (data_out),
        .data_valid   (data_valid)
    );

    // Pipeline registers to improve timing and structure data flow
    always @(posedge clk) begin
        if (reset) begin
            // Reset all pipeline registers
            counter_value_r  <= {CTR_WIDTH{1'b0}};
            encrypted_ctr_r  <= {DATA_WIDTH{1'b0}};
            data_in_r        <= {DATA_WIDTH{1'b0}};
            enable_r1        <= 1'b0;
            enable_r2        <= 1'b0;
        end else begin
            // Pipeline stage registers
            counter_value_r  <= counter_value;
            encrypted_ctr_r  <= encrypted_ctr;
            data_in_r        <= data_in;
            enable_r1        <= enable;
            enable_r2        <= enable_r1;
        end
    end

endmodule

///////////////////////////////////////////////////////////
// Counter Management Module
// Purpose: Generate and manage counter values for CTR mode
///////////////////////////////////////////////////////////
module counter_manager #(
    parameter CTR_WIDTH = 16
) (
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   enable,
    input  wire [CTR_WIDTH-1:0]   init_ctr,
    output reg  [CTR_WIDTH-1:0]   counter_out
);

    // Counter incrementation logic
    always @(posedge clk) begin
        if (reset) begin
            counter_out <= init_ctr;
        end else if (enable) begin
            counter_out <= counter_out + 1'b1;
        end
    end

endmodule

///////////////////////////////////////////////////////////
// Counter Encryption Module
// Purpose: Encrypt counter values with the key
///////////////////////////////////////////////////////////
module ctr_encryptor #(
    parameter CTR_WIDTH = 16,
    parameter DATA_WIDTH = 32
) (
    input  wire [CTR_WIDTH-1:0]    counter,
    input  wire [DATA_WIDTH-1:0]   key,
    output wire [DATA_WIDTH-1:0]   encrypted_ctr
);

    // Intermediate signals for breaking down the encryption logic
    wire [DATA_WIDTH-1:0] extended_counter;
    
    // Counter extension logic
    assign extended_counter = {counter, counter};
    
    // Encryption logic - XORing with key
    // In a real implementation, this would be a more sophisticated algorithm
    assign encrypted_ctr = extended_counter ^ key;

endmodule

///////////////////////////////////////////////////////////
// Output Data Processing Module
// Purpose: Final XOR operation and output control
///////////////////////////////////////////////////////////
module output_processor #(
    parameter DATA_WIDTH = 32
) (
    input  wire                    clk,
    input  wire                    reset,
    input  wire                    enable,
    input  wire [DATA_WIDTH-1:0]   data_in,
    input  wire [DATA_WIDTH-1:0]   encrypted_ctr,
    output reg  [DATA_WIDTH-1:0]   data_out,
    output reg                     data_valid
);

    // Intermediate signals
    wire [DATA_WIDTH-1:0] xor_result;
    
    // Data XOR logic - separated from register logic for clarity
    assign xor_result = data_in ^ encrypted_ctr;

    // Output registration logic
    always @(posedge clk) begin
        if (reset) begin
            data_valid <= 1'b0;
            data_out <= {DATA_WIDTH{1'b0}};
        end else if (enable) begin
            data_out <= xor_result;
            data_valid <= 1'b1;
        end else begin
            data_valid <= 1'b0;
        end
    end

endmodule