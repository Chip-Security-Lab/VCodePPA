//SystemVerilog
module sync_quadrupole_ram_two_write #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b, we_c, we_d,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b, addr_c, addr_d,
    input wire [DATA_WIDTH-1:0] din_a, din_b, din_c, din_d,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b, dout_c, dout_d
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] ram_buf_a, ram_buf_b, ram_buf_c, ram_buf_d;
    reg [ADDR_WIDTH-1:0] addr_buf_a, addr_buf_b, addr_buf_c, addr_buf_d;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
            dout_c <= 0;
            dout_d <= 0;
            ram_buf_a <= 0;
            ram_buf_b <= 0;
            ram_buf_c <= 0;
            ram_buf_d <= 0;
            addr_buf_a <= 0;
            addr_buf_b <= 0;
            addr_buf_c <= 0;
            addr_buf_d <= 0;
        end else begin
            addr_buf_a <= addr_a;
            addr_buf_b <= addr_b;
            addr_buf_c <= addr_c;
            addr_buf_d <= addr_d;

            if (we_a && !we_b && !we_c && !we_d) ram[addr_a] <= din_a;
            else if (!we_a && we_b && !we_c && !we_d) ram[addr_b] <= din_b;
            else if (!we_a && !we_b && we_c && !we_d) ram[addr_c] <= din_c;
            else if (!we_a && !we_b && !we_c && we_d) ram[addr_d] <= din_d;
            else if (we_a && we_b && !we_c && !we_d) begin
                ram[addr_a] <= din_a;
                ram[addr_b] <= din_b;
            end
            else if (we_a && !we_b && we_c && !we_d) begin
                ram[addr_a] <= din_a;
                ram[addr_c] <= din_c;
            end
            else if (we_a && !we_b && !we_c && we_d) begin
                ram[addr_a] <= din_a;
                ram[addr_d] <= din_d;
            end
            else if (!we_a && we_b && we_c && !we_d) begin
                ram[addr_b] <= din_b;
                ram[addr_c] <= din_c;
            end
            else if (!we_a && we_b && !we_c && we_d) begin
                ram[addr_b] <= din_b;
                ram[addr_d] <= din_d;
            end
            else if (!we_a && !we_b && we_c && we_d) begin
                ram[addr_c] <= din_c;
                ram[addr_d] <= din_d;
            end
            else if (we_a && we_b && we_c && !we_d) begin
                ram[addr_a] <= din_a;
                ram[addr_b] <= din_b;
                ram[addr_c] <= din_c;
            end
            else if (we_a && we_b && !we_c && we_d) begin
                ram[addr_a] <= din_a;
                ram[addr_b] <= din_b;
                ram[addr_d] <= din_d;
            end
            else if (we_a && !we_b && we_c && we_d) begin
                ram[addr_a] <= din_a;
                ram[addr_c] <= din_c;
                ram[addr_d] <= din_d;
            end
            else if (!we_a && we_b && we_c && we_d) begin
                ram[addr_b] <= din_b;
                ram[addr_c] <= din_c;
                ram[addr_d] <= din_d;
            end
            else if (we_a && we_b && we_c && we_d) begin
                ram[addr_a] <= din_a;
                ram[addr_b] <= din_b;
                ram[addr_c] <= din_c;
                ram[addr_d] <= din_d;
            end

            ram_buf_a <= ram[addr_buf_a];
            ram_buf_b <= ram[addr_buf_b];
            ram_buf_c <= ram[addr_buf_c];
            ram_buf_d <= ram[addr_buf_d];

            dout_a <= ram_buf_a;
            dout_b <= ram_buf_b;
            dout_c <= ram_buf_c;
            dout_d <= ram_buf_d;
        end
    end

endmodule