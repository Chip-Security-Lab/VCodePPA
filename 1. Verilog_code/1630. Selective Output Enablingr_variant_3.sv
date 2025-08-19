//SystemVerilog
// Address decoder submodule
module addr_decoder #(
    parameter ADDR_WIDTH = 4,
    parameter OUT_WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input [ADDR_WIDTH-1:0] addr,
    input enable,
    output reg [OUT_WIDTH-1:0] decode_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decode_out <= {OUT_WIDTH{1'b0}};
        end else begin
            decode_out <= enable ? (1 << addr) : {OUT_WIDTH{1'b0}};
        end
    end

endmodule

// Mask application submodule
module mask_applier #(
    parameter OUT_WIDTH = 16,
    parameter ENABLE_MASK = 16'hFFFF
)(
    input wire clk,
    input wire rst_n,
    input [OUT_WIDTH-1:0] mask_in,
    output reg [OUT_WIDTH-1:0] mask_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mask_out <= {OUT_WIDTH{1'b0}};
        end else begin
            mask_out <= mask_in & ENABLE_MASK;
        end
    end

endmodule

// Top-level selective decoder module
module selective_decoder #(
    parameter ADDR_WIDTH = 4,
    parameter OUT_WIDTH = 16,
    parameter ENABLE_MASK = 16'hFFFF
)(
    input wire clk,
    input wire rst_n,
    input [ADDR_WIDTH-1:0] addr,
    input enable,
    output wire [OUT_WIDTH-1:0] select
);

    wire [OUT_WIDTH-1:0] decode_stage;

    // Instantiate address decoder submodule
    addr_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) addr_decoder_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .enable(enable),
        .decode_out(decode_stage)
    );

    // Instantiate mask applier submodule
    mask_applier #(
        .OUT_WIDTH(OUT_WIDTH),
        .ENABLE_MASK(ENABLE_MASK)
    ) mask_applier_inst (
        .clk(clk),
        .rst_n(rst_n),
        .mask_in(decode_stage),
        .mask_out(select)
    );

endmodule