//SystemVerilog
module sync_single_port_ram_variable_depth #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter RAM_DEPTH = 256
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [0:RAM_DEPTH-1];
    reg [1:0] state;
    reg [DATA_WIDTH-1:0] ram_data_reg;
    reg [DATA_WIDTH-1:0] din_reg;
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg we_reg;

    // 输入寄存器缓冲
    always @(posedge clk) begin
        addr_reg <= addr;
        din_reg <= din;
        we_reg <= we;
    end

    // RAM访问和状态机
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 2'b00;
            dout <= 0;
            ram_data_reg <= 0;
        end else begin
            case (state)
                2'b00: begin
                    if (we_reg) begin
                        ram[addr_reg] <= din_reg;
                        ram_data_reg <= din_reg;
                        state <= 2'b01;
                    end else begin
                        ram_data_reg <= ram[addr_reg];
                        state <= 2'b10;
                    end
                end
                2'b01: begin
                    dout <= din_reg;
                    state <= 2'b10;
                end
                2'b10: begin
                    dout <= ram_data_reg;
                    state <= 2'b00;
                end
                default: begin
                    state <= 2'b00;
                    dout <= ram_data_reg;
                end
            endcase
        end
    end
endmodule