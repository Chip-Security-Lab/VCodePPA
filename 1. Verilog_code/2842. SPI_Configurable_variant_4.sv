//SystemVerilog
module SPI_Configurable #(
    parameter REG_FILE_SIZE = 8
)(
    input                clk,
    input                rst_n,
    // SPI接口
    output               sclk,
    output               mosi,
    output               cs_n,
    input                miso,
    // 配置接口
    input       [7:0]    config_addr,
    input      [15:0]    config_data,
    input                config_wr
);

// ----------------------
// Stage 1: 配置写入阶段
// ----------------------
reg [15:0] config_reg [0:REG_FILE_SIZE-1];
reg        config_wr_stage1;
reg [7:0]  config_addr_stage1;
reg [15:0] config_data_stage1;
integer    i;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0; i<REG_FILE_SIZE; i=i+1)
            config_reg[i] <= 16'd0;
        config_wr_stage1      <= 1'b0;
        config_addr_stage1    <= 8'd0;
        config_data_stage1    <= 16'd0;
    end else begin
        config_wr_stage1      <= config_wr;
        config_addr_stage1    <= config_addr;
        config_data_stage1    <= config_data;
        if(config_wr_stage1) begin
            config_reg[config_addr_stage1] <= config_data_stage1;
        end
    end
end

// ----------------------
// Stage 2: 配置参数映射阶段
// ----------------------
reg [7:0]  clk_div_stage2;
reg [3:0]  data_width_stage2;
reg [1:0]  cpol_cpha_stage2;
reg        valid_stage2;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        clk_div_stage2      <= 8'd0;
        data_width_stage2   <= 4'd0;
        cpol_cpha_stage2    <= 2'd0;
        valid_stage2        <= 1'b0;
    end else begin
        clk_div_stage2      <= config_reg[0][7:0];
        data_width_stage2   <= config_reg[1][3:0];
        cpol_cpha_stage2    <= config_reg[2][1:0];
        valid_stage2        <= 1'b1;
    end
end

// ----------------------
// Stage 3: 动态时钟分频阶段
// ----------------------
reg [7:0]  clk_counter_stage3;
reg        sclk_int_stage3;
reg [7:0]  clk_div_stage3;
reg        valid_stage3;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        clk_counter_stage3  <= 8'd0;
        sclk_int_stage3     <= 1'b0;
        clk_div_stage3      <= 8'd0;
        valid_stage3        <= 1'b0;
    end else begin
        clk_div_stage3      <= clk_div_stage2;
        valid_stage3        <= valid_stage2;
        if(clk_counter_stage3 >= clk_div_stage3) begin
            sclk_int_stage3 <= ~sclk_int_stage3;
            clk_counter_stage3 <= 8'd0;
        end else begin
            clk_counter_stage3 <= clk_counter_stage3 + 1'b1;
        end
    end
end

// ----------------------
// Stage 4: SPI信号生成阶段
// ----------------------
reg [1:0]  cpol_cpha_stage4;
reg        sclk_int_stage4;
reg        valid_stage4;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cpol_cpha_stage4    <= 2'd0;
        sclk_int_stage4     <= 1'b0;
        valid_stage4        <= 1'b0;
    end else begin
        cpol_cpha_stage4    <= cpol_cpha_stage2;
        sclk_int_stage4     <= sclk_int_stage3;
        valid_stage4        <= valid_stage3;
    end
end

// ----------------------
// 输出信号分配
// ----------------------
assign sclk = cpol_cpha_stage4[1] ? ~sclk_int_stage4 : sclk_int_stage4;
assign mosi = 1'b0; // 实际应用需实现数据通路
assign cs_n = 1'b1; // 默认不选中任何设备

endmodule