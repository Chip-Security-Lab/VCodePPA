//SystemVerilog
// Top-level XOR Cryptography Module with Structured Pipelined Dataflow

module xor_crypt_pipelined #(parameter KEY=8'hA5) (
    input         clk,
    input         rst_n,
    input  [7:0]  data_in,
    input         data_in_valid,
    output        data_out_valid,
    output [7:0]  data_out
);

    // Stage 1: Key Generation & Input Registering
    wire [7:0] key_stage1;
    reg  [7:0] data_stage1;
    reg        valid_stage1;

    key_gen #(.KEY(KEY)) u_key_gen (
        .key_out(key_stage1)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1  <= 8'd0;
            valid_stage1 <= 1'b0;
        end else begin
            data_stage1  <= data_in;
            valid_stage1 <= data_in_valid;
        end
    end

    // Stage 2: XOR Operation (Pipelined)
    reg  [7:0] key_stage2;
    reg  [7:0] data_stage2;
    reg        valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_stage2   <= 8'd0;
            data_stage2  <= 8'd0;
            valid_stage2 <= 1'b0;
        end else begin
            key_stage2   <= key_stage1;
            data_stage2  <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Output Registering
    reg  [7:0] xor_result_stage3;
    reg        valid_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_result_stage3 <= 8'd0;
            valid_stage3      <= 1'b0;
        end else begin
            xor_result_stage3 <= data_stage2 ^ key_stage2;
            valid_stage3      <= valid_stage2;
        end
    end

    assign data_out      = xor_result_stage3;
    assign data_out_valid = valid_stage3;

endmodule

// -----------------------------------------------------------------------------
// Key Generation Submodule
// Generates the key value for XOR operation, parameterizable for reuse.
// -----------------------------------------------------------------------------
module key_gen #(parameter KEY=8'hA5) (
    output [7:0] key_out
);
    assign key_out = KEY;
endmodule