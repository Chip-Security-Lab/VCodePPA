//SystemVerilog
// Address register module
module addr_reg #(
    parameter ADDR_WIDTH = 3
)(
    input wire clk,
    input wire rst_n,
    input wire [ADDR_WIDTH-1:0] addr_in,
    output reg [ADDR_WIDTH-1:0] addr_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_out <= {ADDR_WIDTH{1'b0}};
        end else begin
            addr_out <= addr_in;
        end
    end

endmodule

// Decoder core module
module decoder_core #(
    parameter ADDR_WIDTH = 3,
    parameter DECODED_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_in,
    output wire [DECODED_WIDTH-1:0] decoded_out
);

    assign decoded_out = (1'b1 << addr_in);

endmodule

// Output register module
module out_reg #(
    parameter DECODED_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [DECODED_WIDTH-1:0] data_in,
    output reg [DECODED_WIDTH-1:0] data_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {DECODED_WIDTH{1'b0}};
        end else begin
            data_out <= data_in;
        end
    end

endmodule

// Top level decoder module
module decoder_async #(
    parameter ADDR_WIDTH = 3,
    parameter DECODED_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [ADDR_WIDTH-1:0] addr_in,
    output wire [DECODED_WIDTH-1:0] decoded_out
);

    wire [ADDR_WIDTH-1:0] addr_reg_out;
    wire [DECODED_WIDTH-1:0] decoded_pre;

    addr_reg #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) addr_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr_in(addr_in),
        .addr_out(addr_reg_out)
    );

    decoder_core #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DECODED_WIDTH(DECODED_WIDTH)
    ) decoder_core_inst (
        .addr_in(addr_reg_out),
        .decoded_out(decoded_pre)
    );

    out_reg #(
        .DECODED_WIDTH(DECODED_WIDTH)
    ) out_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(decoded_pre),
        .data_out(decoded_out)
    );

endmodule