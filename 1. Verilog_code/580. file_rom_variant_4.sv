//SystemVerilog
// 顶层模块
module file_rom_top (
    input clk,
    input rst_n,
    input [3:0] addr,
    input addr_valid,
    output reg addr_ready,
    output reg [7:0] data,
    output reg data_valid,
    input data_ready
);

    // 实例化ROM存储子模块
    rom_memory u_rom_memory (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .addr_valid(addr_valid),
        .addr_ready(addr_ready),
        .data(data),
        .data_valid(data_valid),
        .data_ready(data_ready)
    );

endmodule

// ROM存储子模块
module rom_memory (
    input clk,
    input rst_n,
    input [3:0] addr,
    input addr_valid,
    output reg addr_ready,
    output reg [7:0] data,
    output reg data_valid,
    input data_ready
);

    // ROM存储单元
    reg [7:0] rom [0:15];
    reg [7:0] data_reg;
    reg state;
    
    localparam IDLE = 1'b0;
    localparam TRANSFER = 1'b1;

    // 初始化ROM数据
    initial begin
        $readmemh("rom_data.hex", rom);
    end

    // 状态机实现Valid-Ready握手
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            addr_ready <= 1'b1;
            data_valid <= 1'b0;
            data <= 8'h0;
            data_reg <= 8'h0;
        end else begin
            case (state)
                IDLE: begin
                    if (addr_valid && addr_ready) begin
                        data_reg <= rom[addr];
                        addr_ready <= 1'b0;
                        data_valid <= 1'b1;
                        state <= TRANSFER;
                    end
                end
                
                TRANSFER: begin
                    if (data_valid && data_ready) begin
                        data <= data_reg;
                        data_valid <= 1'b0;
                        addr_ready <= 1'b1;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule