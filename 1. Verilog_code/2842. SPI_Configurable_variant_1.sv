//SystemVerilog
module SPI_Configurable #(
    parameter REG_FILE_SIZE = 8
)(
    input               clk,
    input               rst_n,
    // SPI接口
    output              sclk,
    output              mosi,
    output              cs_n,
    input               miso,
    // 配置接口
    input       [7:0]   config_addr,
    input       [15:0]  config_data,
    input               config_wr
);

    // 配置寄存器实例
    wire [15:0] config_reg_array [0:REG_FILE_SIZE-1];
    SPI_ConfigRegFile #(
        .REG_FILE_SIZE(REG_FILE_SIZE)
    ) u_config_regfile (
        .clk            (clk),
        .rst_n          (rst_n),
        .config_addr    (config_addr),
        .config_data    (config_data),
        .config_wr      (config_wr),
        .config_reg_out (config_reg_array)
    );

    // 组合逻辑参数提取
    wire [7:0] clk_div_value;
    wire [3:0] spi_data_width;
    wire [1:0] spi_cpol_cpha;

    assign clk_div_value   = config_reg_array[0][7:0];
    assign spi_data_width  = config_reg_array[1][3:0];
    assign spi_cpol_cpha   = config_reg_array[2][1:0];

    // SPI时钟发生器
    wire sclk_int_signal;
    SPI_ClockGen u_clockgen (
        .clk            (clk),
        .rst_n          (rst_n),
        .clk_div        (clk_div_value),
        .cpol           (spi_cpol_cpha[1]),
        .sclk_out       (sclk),
        .sclk_int_debug (sclk_int_signal)
    );

    // 其它SPI信号（占位，需根据功能完善）
    assign mosi = 1'b0;
    assign cs_n = 1'b1;

endmodule

//======================= 配置寄存器文件模块 ===========================
module SPI_ConfigRegFile #(
    parameter REG_FILE_SIZE = 8
)(
    input               clk,
    input               rst_n,
    input       [7:0]   config_addr,
    input       [15:0]  config_data,
    input               config_wr,
    output  reg [15:0]  config_reg_out [0:REG_FILE_SIZE-1]
);

    integer reg_idx;
    reg [15:0] config_reg_array [0:REG_FILE_SIZE-1];

    // 优化后的同步初始化与写入，减少关键路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (reg_idx = 0; reg_idx < REG_FILE_SIZE; reg_idx = reg_idx + 1)
                config_reg_array[reg_idx] <= 16'b0;
        end else if (config_wr) begin
            config_reg_array[config_addr] <= config_data;
        end
    end

    // 输出寄存器单独赋值，减少多端口驱动，均衡路径
    genvar out_idx;
    generate
        for (out_idx = 0; out_idx < REG_FILE_SIZE; out_idx = out_idx + 1) begin: OUT_ASSIGN
            always @(*) begin
                config_reg_out[out_idx] = config_reg_array[out_idx];
            end
        end
    endgenerate

endmodule

//======================= SPI时钟发生器模块 ===========================
module SPI_ClockGen (
    input           clk,
    input           rst_n,
    input   [7:0]   clk_div,
    input           cpol,
    output          sclk_out,
    output          sclk_int_debug
);

    reg [7:0] clk_counter;
    reg       sclk_internal;

    // 路径平衡: 将分频判断和计数拆分为中间信号，减少关键路径
    wire clk_counter_reach_limit;
    assign clk_counter_reach_limit = (clk_counter >= clk_div);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_counter   <= 8'd0;
            sclk_internal <= 1'b0;
        end else begin
            if (clk_counter_reach_limit) begin
                sclk_internal <= ~sclk_internal;
                clk_counter   <= 8'd0;
            end else begin
                clk_counter   <= clk_counter + 8'd1;
            end
        end
    end

    // 路径平衡: 预计算CPOL极性的选择
    wire sclk_cpol_mux;
    assign sclk_cpol_mux = cpol ^ sclk_internal;

    assign sclk_out       = sclk_cpol_mux;
    assign sclk_int_debug = sclk_internal;

endmodule