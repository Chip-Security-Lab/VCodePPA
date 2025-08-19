//SystemVerilog
// Top-level module: Hierarchical data encryption wrapper (Pipelined, optimized with pipeline register insertion)
module data_encrypt #(parameter DW=16) (
    input                  clk,
    input                  rst_n,
    input                  en,
    input  [DW-1:0]        din,
    input  [DW-1:0]        key,
    output reg [DW-1:0]    dout,
    output reg             dout_valid
);

    // Stage 1: Input register & valid
    reg  [DW-1:0] din_stage1;
    reg  [DW-1:0] key_stage1;
    reg           valid_stage1;

    // Stage 2a: Permutation register (splitting permutation into two pipeline stages)
    reg  [7:0]    permute_upper_stage2a;
    reg  [7:0]    permute_lower_stage2a;
    reg  [DW-1:0] key_stage2a;
    reg           valid_stage2a;

    // Stage 2b: Permutation combine (new pipeline stage)
    reg  [DW-1:0] permuted_data_stage2b;
    reg  [DW-1:0] key_stage2b;
    reg           valid_stage2b;

    // Stage 3a: XOR register (splitting XOR into two pipeline stages)
    reg  [DW-1:0] xor_input_stage3a;
    reg  [DW-1:0] key_stage3a;
    reg           valid_stage3a;

    // Stage 3b: XOR output register
    reg  [DW-1:0] encrypted_data_stage3b;
    reg           valid_stage3b;

    // Flush pipeline logic
    wire flush;
    assign flush = !rst_n;

    // Stage 1: Latch input when enabled
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_stage1    <= {DW{1'b0}};
            key_stage1    <= {DW{1'b0}};
            valid_stage1  <= 1'b0;
        end else if (en) begin
            din_stage1    <= din;
            key_stage1    <= key;
            valid_stage1  <= 1'b1;
        end else begin
            valid_stage1  <= 1'b0;
        end
    end

    // Stage 2a: Permutation split - register upper/lower halves separately
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            permute_lower_stage2a <= 8'b0;
            permute_upper_stage2a <= 8'b0;
            key_stage2a           <= {DW{1'b0}};
            valid_stage2a         <= 1'b0;
        end else if (flush) begin
            valid_stage2a         <= 1'b0;
        end else begin
            permute_lower_stage2a <= din_stage1[7:0];
            permute_upper_stage2a <= din_stage1[15:8];
            key_stage2a           <= key_stage1;
            valid_stage2a         <= valid_stage1;
        end
    end

    // Stage 2b: Permutation combine (pipeline cut here)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            permuted_data_stage2b <= {DW{1'b0}};
            key_stage2b           <= {DW{1'b0}};
            valid_stage2b         <= 1'b0;
        end else if (flush) begin
            valid_stage2b         <= 1'b0;
        end else begin
            permuted_data_stage2b <= {permute_lower_stage2a, permute_upper_stage2a};
            key_stage2b           <= key_stage2a;
            valid_stage2b         <= valid_stage2a;
        end
    end

    // Stage 3a: XOR input register (pipeline cut before XOR)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_input_stage3a <= {DW{1'b0}};
            key_stage3a       <= {DW{1'b0}};
            valid_stage3a     <= 1'b0;
        end else if (flush) begin
            valid_stage3a     <= 1'b0;
        end else begin
            xor_input_stage3a <= permuted_data_stage2b;
            key_stage3a       <= key_stage2b;
            valid_stage3a     <= valid_stage2b;
        end
    end

    // Stage 3b: XOR output register (final result)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encrypted_data_stage3b <= {DW{1'b0}};
            valid_stage3b          <= 1'b0;
        end else if (flush) begin
            valid_stage3b          <= 1'b0;
        end else begin
            encrypted_data_stage3b <= xor_input_stage3a ^ key_stage3a;
            valid_stage3b          <= valid_stage3a;
        end
    end

    // Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout       <= {DW{1'b0}};
            dout_valid <= 1'b0;
        end else if (flush) begin
            dout_valid <= 1'b0;
        end else begin
            dout       <= encrypted_data_stage3b;
            dout_valid <= valid_stage3b;
        end
    end

endmodule

//------------------------------------------------------------------------------
// permute_unit
// Swaps the lower and upper 8 bits of the input data
//------------------------------------------------------------------------------
module permute_unit #(parameter DW=16) (
    input  [DW-1:0] data_in,
    output [DW-1:0] data_out
);
    assign data_out = {data_in[7:0], data_in[15:8]};
endmodule

//------------------------------------------------------------------------------
// xor_unit
// Performs bitwise XOR between permuted data and key
//------------------------------------------------------------------------------
module xor_unit #(parameter DW=16) (
    input  [DW-1:0] data_in,
    input  [DW-1:0] key_in,
    output [DW-1:0] data_out
);
    assign data_out = data_in ^ key_in;
endmodule