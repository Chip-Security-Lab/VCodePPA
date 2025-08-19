//SystemVerilog
module multi_io_ctrl (
    input  wire       clk,
    input  wire       mode_sel,
    input  wire [7:0] data_in,
    output wire       scl,
    output wire       sda,
    output wire       spi_cs
);
    // 内部连线
    wire i2c_mode;
    
    // 模式选择子模块
    mode_selector mode_sel_inst (
        .clk      (clk),
        .mode_sel (mode_sel),
        .i2c_mode (i2c_mode)
    );
    
    // I2C控制子模块
    i2c_controller i2c_ctrl_inst (
        .clk      (clk),
        .i2c_mode (i2c_mode),
        .data_in  (data_in),
        .scl      (scl),
        .sda      (sda)
    );
    
    // SPI控制子模块
    spi_controller spi_ctrl_inst (
        .clk      (clk),
        .i2c_mode (i2c_mode),
        .data_in  (data_in),
        .spi_cs   (spi_cs)
    );
    
endmodule

// 模式选择子模块 - 管理操作模式
module mode_selector (
    input  wire  clk,
    input  wire  mode_sel,
    output reg   i2c_mode
);
    // 对模式选择进行预处理以减少关键路径
    always @(posedge clk) begin
        i2c_mode <= mode_sel;
    end
endmodule

// I2C控制子模块 - 管理I2C接口信号
module i2c_controller (
    input  wire       clk,
    input  wire       i2c_mode,
    input  wire [7:0] data_in,
    output reg        scl,
    output reg        sda
);
    // I2C信号生成逻辑
    always @(posedge clk) begin
        if (i2c_mode) begin
            scl <= ~scl;
            sda <= data_in[7];
        end
    end
endmodule

// SPI控制子模块 - 管理SPI接口信号
module spi_controller (
    input  wire       clk,
    input  wire       i2c_mode,
    input  wire [7:0] data_in,
    output reg        spi_cs
);
    // SPI信号生成逻辑
    always @(posedge clk) begin
        if (!i2c_mode) begin
            spi_cs <= data_in[0];
        end
    end
endmodule