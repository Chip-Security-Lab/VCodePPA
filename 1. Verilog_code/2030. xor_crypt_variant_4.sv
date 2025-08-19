//SystemVerilog
// -----------------------------------------------------------------------------
// Top-level module: xor_crypt_pipeline
// Hierarchical, pipelined XOR-based encryption/decryption module
// Structured data flow with pipeline stages for timing and clarity
// -----------------------------------------------------------------------------
module xor_crypt_pipeline #(
    parameter [7:0] KEY = 8'hA5
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_in,
    input  wire        data_in_valid,
    output wire [7:0]  data_out,
    output wire        data_out_valid
);

    // Stage 1: Key Generation
    wire [7:0] key_stage1;
    key_gen #(
        .KEY_VALUE(KEY)
    ) u_key_gen (
        .key(key_stage1)
    );

    // Stage 1: Input Registering
    reg [7:0]  data_stage1;
    reg        valid_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1  <= 8'd0;
            valid_stage1 <= 1'b0;
        end else begin
            data_stage1  <= data_in;
            valid_stage1 <= data_in_valid;
        end
    end

    // Stage 2: XOR Operation (Registered)
    reg [7:0]  xor_stage2;
    reg        valid_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_stage2   <= 8'd0;
            valid_stage2 <= 1'b0;
        end else begin
            xor_stage2   <= data_stage1 ^ key_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Output Registering (optional for timing closure)
    reg [7:0]  data_stage3;
    reg        valid_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage3  <= 8'd0;
            valid_stage3 <= 1'b0;
        end else begin
            data_stage3  <= xor_stage2;
            valid_stage3 <= valid_stage2;
        end
    end

    assign data_out      = data_stage3;
    assign data_out_valid = valid_stage3;

endmodule

// -----------------------------------------------------------------------------
// key_gen
// Purpose: Output a fixed KEY value parameter for cryptographic operations.
// Interface: Single output port for key.
// -----------------------------------------------------------------------------
module key_gen #(
    parameter [7:0] KEY_VALUE = 8'hA5
)(
    output wire [7:0] key
);
    assign key = KEY_VALUE;
endmodule