//SystemVerilog
module debug_rom (
    input clk,
    input [3:0] addr,
    input debug_en,
    output reg [7:0] data,
    output reg [3:0] debug_addr,
    input req,           // 请求信号
    output reg ack       // 应答信号
);
    reg [7:0] rom [0:15];
    reg [7:0] rom_data_buf;
    reg [3:0] addr_buf;
    reg req_dly;         // 请求延迟寄存器

    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34;
    end

    always @(posedge clk) begin
        req_dly <= req;
        if (req && !req_dly) begin  // 检测请求上升沿
            addr_buf <= addr;
            rom_data_buf <= rom[addr_buf];
            if (debug_en)
                debug_addr <= addr_buf;
            data <= rom_data_buf;
            ack <= 1'b1;
        end else if (!req) begin
            ack <= 1'b0;
        end
    end
endmodule