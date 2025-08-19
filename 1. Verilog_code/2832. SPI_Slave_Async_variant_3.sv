//SystemVerilog
module SPI_Slave_Async #(
    parameter ADDR_WIDTH = 3,
    parameter REG_DEPTH = 8
)(
    input wire sck,
    input wire cs_n,
    input wire mosi,
    output reg miso,
    input wire [7:0] reg_file [0:REG_DEPTH-1],
    input wire [ADDR_WIDTH-1:0] addr,
    input wire cpha
);

reg [2:0] bit_counter;
reg [7:0] shift_register;

// 优化后的采样边沿表达式，提前计算常量路径
wire cpha_sck    = cpha & sck;
wire ncpha_nsck  = (~cpha) & (~sck);
wire sample_edge = cpha_sck | ncpha_nsck;

// 优化后的MISO数据准备，提前读取目标寄存器
wire [7:0] selected_reg_data = reg_file[addr];

always @(posedge sample_edge or posedge cs_n) begin
    if (cs_n) begin
        bit_counter    <= 3'b000;
        shift_register <= 8'b0;
        miso           <= 1'b0;
    end else begin
        // 先更新移位寄存器
        shift_register <= {shift_register[6:0], mosi};
        // 提前计算的寄存器数据，减少组合深度
        miso           <= selected_reg_data[bit_counter];
        bit_counter    <= bit_counter + 3'b001;
    end
end

endmodule