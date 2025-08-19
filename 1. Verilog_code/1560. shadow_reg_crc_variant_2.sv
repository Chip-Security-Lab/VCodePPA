//SystemVerilog
// CRC Calculation Module
module crc_calculator #(parameter DW=8) (
    input [DW-1:0] data_in,
    output [3:0] crc_out
);
    assign crc_out = data_in[3:0] ^ data_in[7:4];
endmodule

// Shadow Register Module
module shadow_register #(parameter DW=8) (
    input clk, rst, en,
    input [DW-1:0] data_in,
    output reg [DW+3:0] reg_out  // [DW+3:DW]为CRC
);
    wire [3:0] crc;

    // Instantiate the CRC calculator
    crc_calculator #(DW) crc_inst (
        .data_in(data_in),
        .crc_out(crc)
    );

    always @(posedge clk) begin
        if (rst) 
            reg_out <= 0;
        else if (en) 
            reg_out <= {crc, data_in};
    end
endmodule

// Top Level Module
module top_module #(parameter DW=8) (
    input clk, rst, en,
    input [DW-1:0] data_in,
    output [DW+3:0] reg_out
);
    // Instantiate the shadow register
    shadow_register #(DW) shadow_reg_inst (
        .clk(clk),
        .rst(rst),
        .en(en),
        .data_in(data_in),
        .reg_out(reg_out)
    );
endmodule