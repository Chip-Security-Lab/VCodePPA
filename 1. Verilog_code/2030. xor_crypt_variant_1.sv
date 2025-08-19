//SystemVerilog
// Top-level XOR encryption module with pipelined, structured dataflow

module xor_crypt #(parameter KEY=8'hA5) (
    input         clk,
    input         rst_n,
    input  [7:0]  data_in,
    input         data_in_valid,
    output [7:0]  data_out,
    output        data_out_valid
);

    // Stage 1: Key Generation and Input Registering
    wire  [7:0]  key_stage1;
    wire  [7:0]  data_stage1;
    wire         valid_stage1;

    key_gen #(.KEY(KEY)) u_key_gen (
        .clk(clk),
        .rst_n(rst_n),
        .key_out(key_stage1)
    );

    reg [7:0] data_in_reg;
    reg       data_in_valid_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg       <= 8'd0;
            data_in_valid_reg <= 1'b0;
        end else begin
            data_in_reg       <= data_in;
            data_in_valid_reg <= data_in_valid;
        end
    end

    assign data_stage1  = data_in_reg;
    assign valid_stage1 = data_in_valid_reg;

    // Stage 2: XOR Engine (Pipelined)
    wire [7:0] xor_stage2;
    reg  [7:0] xor_stage2_reg;
    reg        valid_stage2;

    xor_engine_piped u_xor_engine (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_stage1),
        .key_in(key_stage1),
        .data_in_valid(valid_stage1),
        .data_out(xor_stage2),
        .data_out_valid(valid_stage2)
    );

    // Stage 3: Output Registering
    reg [7:0] data_out_reg;
    reg       data_out_valid_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_reg       <= 8'd0;
            data_out_valid_reg <= 1'b0;
        end else begin
            data_out_reg       <= xor_stage2;
            data_out_valid_reg <= valid_stage2;
        end
    end

    assign data_out       = data_out_reg;
    assign data_out_valid = data_out_valid_reg;

endmodule

// -----------------------------------------------------------------------------
// Key Generator Module (Pipelined)
// Provides a constant key for encryption/decryption, registered for pipeline
// -----------------------------------------------------------------------------
module key_gen #(parameter KEY=8'hA5) (
    input        clk,
    input        rst_n,
    output [7:0] key_out
);
    reg [7:0] key_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            key_reg <= 8'd0;
        else
            key_reg <= KEY;
    end
    assign key_out = key_reg;
endmodule

// -----------------------------------------------------------------------------
// XOR Engine Module (Pipelined)
// Performs bitwise XOR between 8-bit input data and 8-bit key, pipelined
// -----------------------------------------------------------------------------
module xor_engine_piped (
    input         clk,
    input         rst_n,
    input  [7:0]  data_in,
    input  [7:0]  key_in,
    input         data_in_valid,
    output [7:0]  data_out,
    output        data_out_valid
);

    reg [7:0] data_in_reg;
    reg [7:0] key_in_reg;
    reg       data_in_valid_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg       <= 8'd0;
            key_in_reg        <= 8'd0;
            data_in_valid_reg <= 1'b0;
        end else begin
            data_in_reg       <= data_in;
            key_in_reg        <= key_in;
            data_in_valid_reg <= data_in_valid;
        end
    end

    reg [7:0] xor_result_reg;
    reg       xor_valid_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_result_reg <= 8'd0;
            xor_valid_reg  <= 1'b0;
        end else begin
            xor_result_reg <= data_in_reg ^ key_in_reg;
            xor_valid_reg  <= data_in_valid_reg;
        end
    end

    assign data_out       = xor_result_reg;
    assign data_out_valid = xor_valid_reg;

endmodule