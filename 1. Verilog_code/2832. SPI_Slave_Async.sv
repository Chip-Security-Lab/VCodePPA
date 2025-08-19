module SPI_Slave_Async #(
    parameter ADDR_WIDTH = 3,
    parameter REG_DEPTH = 8
)(
    input sck, cs_n,
    input mosi,
    output reg miso,
    input [7:0] reg_file [0:REG_DEPTH-1],
    input [ADDR_WIDTH-1:0] addr,
    input cpha    // 添加CPHA模式配置输入
);
    
reg [2:0] bit_cnt;
reg [7:0] shift_reg; // 添加移位寄存器
wire sample_edge = (cpha == 0) ? ~sck : sck;

always @(posedge sample_edge or posedge cs_n) begin
    if(cs_n) begin
        bit_cnt <= 0;
        miso <= 1'b0; // 改为默认值而非高阻抗
    end else begin
        shift_reg <= {shift_reg[6:0], mosi};
        miso <= reg_file[addr][bit_cnt];
        bit_cnt <= bit_cnt + 1;
    end
end
endmodule