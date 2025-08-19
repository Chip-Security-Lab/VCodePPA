//SystemVerilog
module debug_rom (
    input clk,
    input [3:0] addr,
    input req,           // 请求信号
    output reg ack,      // 应答信号
    output reg [7:0] data,
    output reg [3:0] debug_addr
);
    reg [7:0] rom [0:15];
    reg req_dly;         // 请求延迟寄存器

    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34;
        ack = 1'b0;
        req_dly = 1'b0;
    end

    always @(posedge clk) begin
        req_dly <= req;
        
        if (req && !req_dly) begin
            debug_addr <= addr;
            data <= rom[addr];
            ack <= 1'b1;
        end else if (!req && req_dly) begin
            ack <= 1'b0;
        end
    end
endmodule