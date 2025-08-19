//SystemVerilog
module sync_single_port_ram_with_byte_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    input wire [DATA_WIDTH/8-1:0] byte_en,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] ram_data;
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg [DATA_WIDTH/8-1:0] byte_en_reg;
    reg [DATA_WIDTH-1:0] din_reg;
    reg we_reg;
    integer i;

    // First pipeline stage - Register inputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_reg <= 0;
            byte_en_reg <= 0;
            din_reg <= 0;
            we_reg <= 0;
        end else begin
            addr_reg <= addr;
            byte_en_reg <= byte_en;
            din_reg <= din;
            we_reg <= we;
        end
    end

    // Second pipeline stage - RAM access
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_data <= 0;
        end else begin
            if (we_reg) begin
                for (i = 0; i < DATA_WIDTH / 8; i = i + 1) begin
                    if (byte_en_reg[i]) begin
                        ram[addr_reg][i*8 +: 8] <= din_reg[i*8 +: 8];
                    end
                end
            end
            ram_data <= ram[addr_reg];
        end
    end

    // Third pipeline stage - Output register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else begin
            dout <= ram_data;
        end
    end

endmodule