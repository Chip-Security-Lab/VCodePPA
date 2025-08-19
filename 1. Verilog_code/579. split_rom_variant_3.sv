//SystemVerilog
// 顶层模块
module split_rom_top (
    input clk,
    input [3:0] addr,
    output [15:0] data
);

    wire clk_buf;
    wire [3:0] addr_buf;
    wire [7:0] rom0_data;
    wire [7:0] rom1_data;
    wire [15:0] data_buf;

    // 时钟缓冲
    clk_buf_inst clk_buf_inst (
        .clk_in(clk),
        .clk_out(clk_buf)
    );

    // 地址缓冲
    addr_buf_inst addr_buf_inst (
        .clk(clk_buf),
        .addr_in(addr),
        .addr_out(addr_buf)
    );

    // 实例化ROM0子模块
    rom_8x16 rom0_inst (
        .clk(clk_buf),
        .addr(addr_buf),
        .data(rom0_data)
    );

    // 实例化ROM1子模块  
    rom_8x16_1 rom1_inst (
        .clk(clk_buf),
        .addr(addr_buf),
        .data(rom1_data)
    );

    // 数据拼接模块
    data_merge merge_inst (
        .clk(clk_buf),
        .rom0_data(rom0_data),
        .rom1_data(rom1_data),
        .data(data_buf)
    );

    // 输出缓冲
    output_buf_inst output_buf_inst (
        .clk(clk_buf),
        .data_in(data_buf),
        .data_out(data)
    );

endmodule

// 时钟缓冲模块
module clk_buf_inst (
    input clk_in,
    output clk_out
);
    assign clk_out = clk_in;
endmodule

// 地址缓冲模块
module addr_buf_inst (
    input clk,
    input [3:0] addr_in,
    output reg [3:0] addr_out
);
    always @(posedge clk) begin
        addr_out <= addr_in;
    end
endmodule

// ROM存储器子模块
module rom_8x16 (
    input clk,
    input [3:0] addr,
    output reg [7:0] data
);

    reg [7:0] rom [0:15];

    initial begin
        rom[0] = 8'h12;
        rom[1] = 8'h34;
        rom[2] = 8'h00;
        rom[3] = 8'h00;
        rom[4] = 8'h00;
        rom[5] = 8'h00;
        rom[6] = 8'h00;
        rom[7] = 8'h00;
        rom[8] = 8'h00;
        rom[9] = 8'h00;
        rom[10] = 8'h00;
        rom[11] = 8'h00;
        rom[12] = 8'h00;
        rom[13] = 8'h00;
        rom[14] = 8'h00;
        rom[15] = 8'h00;
    end

    always @(posedge clk) begin
        data <= rom[addr];
    end

endmodule

// ROM1存储器子模块
module rom_8x16_1 (
    input clk,
    input [3:0] addr,
    output reg [7:0] data
);

    reg [7:0] rom [0:15];

    initial begin
        rom[0] = 8'hAB;
        rom[1] = 8'hCD;
        rom[2] = 8'h00;
        rom[3] = 8'h00;
        rom[4] = 8'h00;
        rom[5] = 8'h00;
        rom[6] = 8'h00;
        rom[7] = 8'h00;
        rom[8] = 8'h00;
        rom[9] = 8'h00;
        rom[10] = 8'h00;
        rom[11] = 8'h00;
        rom[12] = 8'h00;
        rom[13] = 8'h00;
        rom[14] = 8'h00;
        rom[15] = 8'h00;
    end

    always @(posedge clk) begin
        data <= rom[addr];
    end

endmodule

// 数据拼接子模块
module data_merge (
    input clk,
    input [7:0] rom0_data,
    input [7:0] rom1_data,
    output reg [15:0] data
);

    always @(posedge clk) begin
        data <= {rom1_data, rom0_data};
    end

endmodule

// 输出缓冲模块
module output_buf_inst (
    input clk,
    input [15:0] data_in,
    output reg [15:0] data_out
);
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule