//SystemVerilog
// Stage 1: Input sampling and initial decode module
module onehot_sync_decoder_stage1 (
    input wire clock,
    input wire reset_n,
    input wire enable,
    input wire [2:0] addr_in,
    output reg [2:0] addr_out,
    output reg enable_out,
    output reg valid_out,
    output reg [7:0] decode_out
);

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            addr_out <= 3'b0;
            enable_out <= 1'b0;
            valid_out <= 1'b0;
            decode_out <= 8'b0;
        end else begin
            addr_out <= addr_in;
            enable_out <= enable;
            valid_out <= enable;
            decode_out <= (8'b1 << addr_in);
        end
    end

endmodule

// Stage 2: Final decode and output module
module onehot_sync_decoder_stage2 (
    input wire clock,
    input wire reset_n,
    input wire valid_in,
    input wire enable_in,
    input wire [7:0] decode_in,
    output reg [7:0] decode_out
);

    reg valid_stage2;
    reg [7:0] decode_stage2;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            valid_stage2 <= 1'b0;
            decode_stage2 <= 8'b0;
            decode_out <= 8'b0;
        end else begin
            valid_stage2 <= valid_in;
            decode_stage2 <= enable_in ? decode_in : 8'b0;
            decode_out <= valid_stage2 ? decode_stage2 : 8'b0;
        end
    end

endmodule

// Top level module
module onehot_sync_decoder_pipelined (
    input wire clock,
    input wire reset_n,
    input wire enable,
    input wire [2:0] addr_in,
    output wire [7:0] decode_out
);

    // Inter-stage signals
    wire [2:0] addr_stage1;
    wire enable_stage1;
    wire valid_stage1;
    wire [7:0] decode_stage1;

    // Instantiate stage 1
    onehot_sync_decoder_stage1 stage1 (
        .clock(clock),
        .reset_n(reset_n),
        .enable(enable),
        .addr_in(addr_in),
        .addr_out(addr_stage1),
        .enable_out(enable_stage1),
        .valid_out(valid_stage1),
        .decode_out(decode_stage1)
    );

    // Instantiate stage 2
    onehot_sync_decoder_stage2 stage2 (
        .clock(clock),
        .reset_n(reset_n),
        .valid_in(valid_stage1),
        .enable_in(enable_stage1),
        .decode_in(decode_stage1),
        .decode_out(decode_out)
    );

endmodule