//SystemVerilog
module crc_rom_top (
    input clk,
    input rst_n,
    input [3:0] addr,
    input addr_valid,
    output reg addr_ready,
    output reg [7:0] data,
    output reg data_valid,
    input data_ready,
    output reg crc_error,
    output reg error_valid,
    input error_ready
);

    wire [7:0] rom_data;
    wire [3:0] crc_value;
    wire crc_check;
    wire rom_valid;
    wire rom_ready;
    wire crc_valid;
    wire crc_ready;

    // ROM存储子模块
    rom_storage rom_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .addr_valid(addr_valid),
        .addr_ready(addr_ready),
        .data(rom_data),
        .data_valid(rom_valid),
        .data_ready(rom_ready)
    );

    // CRC校验子模块
    crc_checker crc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rom_data(rom_data),
        .rom_valid(rom_valid),
        .rom_ready(rom_ready),
        .crc_value(crc_value),
        .crc_valid(crc_valid),
        .crc_ready(crc_ready),
        .crc_error(crc_check)
    );

    // 输出寄存器子模块
    output_reg out_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rom_data(rom_data),
        .rom_valid(crc_valid),
        .rom_ready(crc_ready),
        .crc_check(crc_check),
        .data(data),
        .data_valid(data_valid),
        .data_ready(data_ready),
        .crc_error(crc_error),
        .error_valid(error_valid),
        .error_ready(error_ready)
    );

endmodule

module rom_storage (
    input clk,
    input rst_n,
    input [3:0] addr,
    input addr_valid,
    output reg addr_ready,
    output reg [7:0] data,
    output reg data_valid,
    input data_ready
);

    reg [7:0] rom [0:15];
    reg [3:0] crc [0:15];

    initial begin
        rom[0] = 8'h99; crc[0] = 4'hF;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_ready <= 1'b1;
            data_valid <= 1'b0;
            data <= 8'h0;
        end else begin
            if (addr_valid && addr_ready) begin
                addr_ready <= 1'b0;
                data <= rom[addr];
                data_valid <= 1'b1;
            end
            if (data_valid && data_ready) begin
                data_valid <= 1'b0;
                addr_ready <= 1'b1;
            end
        end
    end

endmodule

module crc_checker (
    input clk,
    input rst_n,
    input [7:0] rom_data,
    input rom_valid,
    output reg rom_ready,
    output reg [3:0] crc_value,
    output reg crc_valid,
    input crc_ready,
    output reg crc_error
);

    reg [3:0] crc [0:15];

    initial begin
        crc[0] = 4'hF;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rom_ready <= 1'b1;
            crc_valid <= 1'b0;
            crc_value <= 4'h0;
            crc_error <= 1'b0;
        end else begin
            if (rom_valid && rom_ready) begin
                rom_ready <= 1'b0;
                crc_value <= crc[rom_data[3:0]];
                crc_error <= (^rom_data) != crc[rom_data[3:0]];
                crc_valid <= 1'b1;
            end
            if (crc_valid && crc_ready) begin
                crc_valid <= 1'b0;
                rom_ready <= 1'b1;
            end
        end
    end

endmodule

module output_reg (
    input clk,
    input rst_n,
    input [7:0] rom_data,
    input rom_valid,
    output reg rom_ready,
    input crc_check,
    output reg [7:0] data,
    output reg data_valid,
    input data_ready,
    output reg crc_error,
    output reg error_valid,
    input error_ready
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rom_ready <= 1'b1;
            data_valid <= 1'b0;
            error_valid <= 1'b0;
            data <= 8'h0;
            crc_error <= 1'b0;
        end else begin
            if (rom_valid && rom_ready) begin
                rom_ready <= 1'b0;
                data <= rom_data;
                crc_error <= crc_check;
                data_valid <= 1'b1;
                error_valid <= 1'b1;
            end
            if (data_valid && data_ready && error_valid && error_ready) begin
                data_valid <= 1'b0;
                error_valid <= 1'b0;
                rom_ready <= 1'b1;
            end
        end
    end

endmodule