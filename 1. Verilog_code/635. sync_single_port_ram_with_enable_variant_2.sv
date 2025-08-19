//SystemVerilog
module sync_single_port_ram_with_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire en,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout
);

    wire [DATA_WIDTH-1:0] ram_data_out;
    wire [DATA_WIDTH-1:0] ram_data_in;
    wire ram_write_en;

    ram_controller #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_ram_controller (
        .clk(clk),
        .rst(rst),
        .en(en),
        .we(we),
        .ram_data_in(ram_data_in),
        .ram_data_out(ram_data_out),
        .dout(dout),
        .ram_write_en(ram_write_en)
    );

    ram_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_ram_memory (
        .clk(clk),
        .rst(rst),
        .we(ram_write_en),
        .addr(addr),
        .din(ram_data_in),
        .dout(ram_data_out)
    );

endmodule

module ram_controller #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire en,
    input wire we,
    input wire [DATA_WIDTH-1:0] ram_data_in,
    input wire [DATA_WIDTH-1:0] ram_data_out,
    output reg [DATA_WIDTH-1:0] dout,
    output reg ram_write_en
);

    reg [DATA_WIDTH-1:0] data_stage1;
    reg write_en_stage1;
    reg en_stage1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_stage1 <= 0;
            write_en_stage1 <= 0;
            en_stage1 <= 0;
        end else begin
            data_stage1 <= ram_data_out;
            write_en_stage1 <= we;
            en_stage1 <= en;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
            ram_write_en <= 0;
        end else if (en_stage1) begin
            ram_write_en <= write_en_stage1;
            dout <= data_stage1;
        end else begin
            ram_write_en <= 0;
        end
    end

endmodule

module ram_memory #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg [DATA_WIDTH-1:0] din_stage1;
    reg we_stage1;
    reg [DATA_WIDTH-1:0] ram_data_stage1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_stage1 <= 0;
            din_stage1 <= 0;
            we_stage1 <= 0;
            ram_data_stage1 <= 0;
        end else begin
            addr_stage1 <= addr;
            din_stage1 <= din;
            we_stage1 <= we;
            ram_data_stage1 <= ram[addr];
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else begin
            if (we_stage1) begin
                ram[addr_stage1] <= din_stage1;
            end
            dout <= ram_data_stage1;
        end
    end

endmodule