//SystemVerilog
// Top level module
module ICMU_ECCProtect #(
    parameter DATA_WIDTH = 64,
    parameter ECC_WIDTH = 8
)(
    input clk,
    input rst_sync,
    input [DATA_WIDTH-1:0] data_in,
    input ctx_write,
    output [DATA_WIDTH-1:0] data_out,
    output reg ecc_error
);

    // Internal signals
    wire [ECC_WIDTH-1:0] ecc_gen;
    wire [ECC_WIDTH-1:0] ecc_check;
    wire [DATA_WIDTH+ECC_WIDTH-1:0] mem_data;

    // ECC generation module
    ECC_Generator #(
        .DATA_WIDTH(DATA_WIDTH),
        .ECC_WIDTH(ECC_WIDTH)
    ) ecc_gen_inst (
        .data(data_in),
        .ecc(ecc_gen)
    );

    // Memory control module
    Memory_Controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .ECC_WIDTH(ECC_WIDTH)
    ) mem_ctrl_inst (
        .clk(clk),
        .rst_sync(rst_sync),
        .data_in(data_in),
        .ecc_in(ecc_gen),
        .ctx_write(ctx_write),
        .mem_data(mem_data)
    );

    // ECC checking module
    ECC_Checker #(
        .DATA_WIDTH(DATA_WIDTH),
        .ECC_WIDTH(ECC_WIDTH)
    ) ecc_check_inst (
        .data(mem_data[DATA_WIDTH-1:0]),
        .stored_ecc(mem_data[DATA_WIDTH+ECC_WIDTH-1:DATA_WIDTH]),
        .ecc_error(ecc_error)
    );

    assign data_out = mem_data[DATA_WIDTH-1:0];

endmodule

// ECC generation module
module ECC_Generator #(
    parameter DATA_WIDTH = 64,
    parameter ECC_WIDTH = 8
)(
    input [DATA_WIDTH-1:0] data,
    output [ECC_WIDTH-1:0] ecc
);
    assign ecc = ^{data[63:0], 8'h00};
endmodule

// Memory control module
module Memory_Controller #(
    parameter DATA_WIDTH = 64,
    parameter ECC_WIDTH = 8
)(
    input clk,
    input rst_sync,
    input [DATA_WIDTH-1:0] data_in,
    input [ECC_WIDTH-1:0] ecc_in,
    input ctx_write,
    output reg [DATA_WIDTH+ECC_WIDTH-1:0] mem_data
);
    always @(posedge clk) begin
        if (rst_sync) begin
            mem_data <= 0;
        end else if (ctx_write) begin
            mem_data <= {ecc_in, data_in};
        end
    end
endmodule

// ECC checking module
module ECC_Checker #(
    parameter DATA_WIDTH = 64,
    parameter ECC_WIDTH = 8
)(
    input [DATA_WIDTH-1:0] data,
    input [ECC_WIDTH-1:0] stored_ecc,
    output reg ecc_error
);
    wire [ECC_WIDTH-1:0] calc_ecc;
    assign calc_ecc = ^{data[63:0], 8'h00};
    
    always @(*) begin
        ecc_error = (calc_ecc != stored_ecc);
    end
endmodule