//SystemVerilog
// Input pipeline stage module
module input_pipeline (
    input wire clock,
    input wire reset_n,
    input wire enable,
    input wire [2:0] addr_in,
    output reg [2:0] addr_out,
    output reg enable_out,
    output reg valid_out
);

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            addr_out <= 3'b0;
            enable_out <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            addr_out <= addr_in;
            enable_out <= enable;
            valid_out <= enable;
        end
    end

endmodule

// Decode computation module
module decode_compute (
    input wire clock,
    input wire reset_n,
    input wire enable,
    input wire [2:0] addr,
    output reg [7:0] decode_out,
    output reg valid_out
);

    wire [7:0] decode_next = enable ? (8'b1 << addr) : 8'b0;
    
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            decode_out <= 8'b0;
            valid_out <= 1'b0;
        end else begin
            decode_out <= decode_next;
            valid_out <= enable;
        end
    end

endmodule

// Output pipeline stage module
module output_pipeline (
    input wire clock,
    input wire reset_n,
    input wire [7:0] decode_in,
    input wire valid_in,
    output reg [7:0] decode_out,
    output reg valid_out
);

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            decode_out <= 8'b0;
            valid_out <= 1'b0;
        end else begin
            decode_out <= decode_in;
            valid_out <= valid_in;
        end
    end

endmodule

// Top level module
module onehot_sync_decoder (
    input wire clock,
    input wire reset_n,
    input wire enable,
    input wire [2:0] addr_in,
    output wire [7:0] decode_out,
    output wire valid_out
);

    // Interconnect signals
    wire [2:0] addr_stage1;
    wire enable_stage1;
    wire valid_stage1;
    wire [7:0] decode_stage2;
    wire valid_stage2;

    // Module instantiations
    input_pipeline u_input_pipeline (
        .clock(clock),
        .reset_n(reset_n),
        .enable(enable),
        .addr_in(addr_in),
        .addr_out(addr_stage1),
        .enable_out(enable_stage1),
        .valid_out(valid_stage1)
    );

    decode_compute u_decode_compute (
        .clock(clock),
        .reset_n(reset_n),
        .enable(enable_stage1),
        .addr(addr_stage1),
        .decode_out(decode_stage2),
        .valid_out(valid_stage2)
    );

    output_pipeline u_output_pipeline (
        .clock(clock),
        .reset_n(reset_n),
        .decode_in(decode_stage2),
        .valid_in(valid_stage2),
        .decode_out(decode_out),
        .valid_out(valid_out)
    );

endmodule