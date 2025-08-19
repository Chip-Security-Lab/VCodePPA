//SystemVerilog
module crc_adaptive #(
    parameter MAX_WIDTH = 64
)(
    input                  clk,
    input  [MAX_WIDTH-1:0] data,
    input  [5:0]           width_sel,
    output [31:0]          crc
);
    wire [31:0] crc_current;
    wire [31:0] crc_next;
    
    crc_calculator #(
        .MAX_WIDTH(MAX_WIDTH)
    ) u_crc_calculator (
        .data       (data),
        .width_sel  (width_sel),
        .crc_in     (crc_current),
        .crc_out    (crc_next)
    );
    
    crc_register u_crc_register (
        .clk        (clk),
        .crc_next   (crc_next),
        .crc_current(crc_current)
    );
    
    assign crc = crc_current;
endmodule

module crc_calculator #(
    parameter MAX_WIDTH = 64
)(
    input  [MAX_WIDTH-1:0] data,
    input  [5:0]           width_sel,
    input  [31:0]          crc_in,
    output [31:0]          crc_out
);
    localparam CRC32_POLY = 32'h04C11DB7;
    
    reg [31:0] crc_next;
    reg [5:0]  i;
    wire [31:0] crc_shifted;
    wire [31:0] crc_xor;
    
    assign crc_shifted = {crc_in[30:0], 1'b0};
    assign crc_xor = crc_shifted ^ CRC32_POLY;
    
    always @(*) begin
        crc_next = crc_in;
        for (i = 0; i < width_sel; i = i + 1) begin
            crc_next = (crc_next[31] ^ data[i]) ? crc_xor : crc_shifted;
        end
    end
    
    assign crc_out = crc_next;
endmodule

module crc_register (
    input         clk,
    input  [31:0] crc_next,
    output [31:0] crc_current
);
    reg [31:0] crc_reg;
    
    always @(posedge clk) begin
        crc_reg <= crc_next;
    end
    
    assign crc_current = crc_reg;
endmodule