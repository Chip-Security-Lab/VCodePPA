//SystemVerilog
module i2c_dma_controller #(
    parameter DESC_WIDTH = 64,
    parameter BURST_LEN = 4
)(
    input clk_dma,
    input clk_i2c,
    input rst_n,
    // DMA接口
    input [DESC_WIDTH-1:0] desc_in,
    input desc_in_valid,
    output reg desc_ready,
    // I2C物理接口
    inout sda,
    inout scl,
    // 独特特点：描述符控制传输
    output reg [31:0] transfer_count
);
    // 跨时钟域同步器
    (* ASYNC_REG = "TRUE" *) reg [1:0] desc_sync_reg;

    // DMA描述符流水线 - 三级流水线
    // 流水线阶段1: 解析描述符
    reg [31:0] src_addr_stage1;
    reg [31:0] dst_addr_stage1;
    reg [15:0] length_stage1;
    reg mode_stage1;
    reg desc_valid_stage1;
    
    // 流水线阶段2: 处理描述符
    reg [31:0] src_addr_stage2;
    reg [31:0] dst_addr_stage2;
    reg [15:0] length_stage2;
    reg mode_stage2;
    reg desc_valid_stage2;
    
    // 流水线阶段3: 传输准备
    reg [31:0] src_addr_stage3;
    reg [31:0] dst_addr_stage3;
    reg [15:0] length_stage3;
    reg mode_stage3;
    reg desc_valid_stage3;
    
    // 流水线阶段4: 执行传输
    reg [31:0] src_addr_stage4;
    reg [31:0] dst_addr_stage4;
    reg [15:0] length_stage4;
    reg mode_stage4;
    reg [3:0] burst_counter_stage4;

    // 添加流水线控制信号
    reg transfer_active_stage1;
    reg transfer_active_stage2;
    reg transfer_active_stage3;
    reg transfer_active_stage4;
    
    // I2C数据流水线
    reg [7:0] tx_data_stage1;
    reg [7:0] tx_data_stage2;
    reg [7:0] tx_data_stage3;
    wire [7:0] rx_data;
    reg [7:0] rx_data_stage1;
    reg [7:0] rx_data_stage2;

    // 流水线阶段1: 描述符解析
    always @(posedge clk_dma or negedge rst_n) begin
        if (!rst_n) begin
            src_addr_stage1 <= 32'h0;
            dst_addr_stage1 <= 32'h0;
            length_stage1 <= 16'h0;
            mode_stage1 <= 1'b0;
            desc_valid_stage1 <= 1'b0;
            transfer_active_stage1 <= 1'b0;
            desc_ready <= 1'b0;
        end else if (desc_in_valid) begin
            src_addr_stage1 <= desc_in[63:32];
            dst_addr_stage1 <= desc_in[31:0];
            length_stage1 <= desc_in[15:0];
            mode_stage1 <= desc_in[16];
            desc_valid_stage1 <= 1'b1;
            transfer_active_stage1 <= 1'b1;
            desc_ready <= 1'b1;
        end else begin
            desc_valid_stage1 <= 1'b0;
            desc_ready <= 1'b0;
        end
    end
    
    // 流水线阶段2: 描述符处理
    always @(posedge clk_dma or negedge rst_n) begin
        if (!rst_n) begin
            src_addr_stage2 <= 32'h0;
            dst_addr_stage2 <= 32'h0;
            length_stage2 <= 16'h0;
            mode_stage2 <= 1'b0;
            desc_valid_stage2 <= 1'b0;
            transfer_active_stage2 <= 1'b0;
            tx_data_stage1 <= 8'h0;
        end else begin
            src_addr_stage2 <= src_addr_stage1;
            dst_addr_stage2 <= dst_addr_stage1;
            length_stage2 <= length_stage1;
            mode_stage2 <= mode_stage1;
            desc_valid_stage2 <= desc_valid_stage1;
            transfer_active_stage2 <= transfer_active_stage1;
            
            if (transfer_active_stage1) begin
                tx_data_stage1 <= src_addr_stage1[7:0];
            end else begin
                tx_data_stage1 <= 8'h0;
            end
        end
    end
    
    // 流水线阶段3: 传输准备
    always @(posedge clk_dma or negedge rst_n) begin
        if (!rst_n) begin
            src_addr_stage3 <= 32'h0;
            dst_addr_stage3 <= 32'h0;
            length_stage3 <= 16'h0;
            mode_stage3 <= 1'b0;
            desc_valid_stage3 <= 1'b0;
            transfer_active_stage3 <= 1'b0;
            tx_data_stage2 <= 8'h0;
        end else begin
            src_addr_stage3 <= src_addr_stage2;
            dst_addr_stage3 <= dst_addr_stage2;
            length_stage3 <= length_stage2;
            mode_stage3 <= mode_stage2;
            desc_valid_stage3 <= desc_valid_stage2;
            transfer_active_stage3 <= transfer_active_stage2;
            tx_data_stage2 <= tx_data_stage1;
        end
    end
    
    // 流水线阶段4: 执行传输
    always @(posedge clk_dma or negedge rst_n) begin
        if (!rst_n) begin
            src_addr_stage4 <= 32'h0;
            dst_addr_stage4 <= 32'h0;
            length_stage4 <= 16'h0;
            mode_stage4 <= 1'b0;
            burst_counter_stage4 <= 4'h0;
            transfer_active_stage4 <= 1'b0;
            tx_data_stage3 <= 8'h0;
            transfer_count <= 32'h0;
        end else begin
            src_addr_stage4 <= src_addr_stage3;
            dst_addr_stage4 <= dst_addr_stage3;
            length_stage4 <= length_stage3;
            mode_stage4 <= mode_stage3;
            transfer_active_stage4 <= transfer_active_stage3;
            tx_data_stage3 <= tx_data_stage2;
            
            if (desc_valid_stage3) begin
                burst_counter_stage4 <= BURST_LEN;
                transfer_count <= transfer_count + 1;
            end else if (burst_counter_stage4 > 0 && transfer_active_stage4) begin
                burst_counter_stage4 <= burst_counter_stage4 - 1;
            end
        end
    end

    // 跨时钟域数据传输 - I2C接口
    (* ASYNC_REG = "TRUE" *) reg [7:0] tx_data_i2c_sync1;
    (* ASYNC_REG = "TRUE" *) reg [7:0] tx_data_i2c_sync2;
    (* ASYNC_REG = "TRUE" *) reg transfer_active_i2c_sync1;
    (* ASYNC_REG = "TRUE" *) reg transfer_active_i2c_sync2;
    
    // 从DMA时钟域到I2C时钟域的跨时钟域同步
    always @(posedge clk_i2c or negedge rst_n) begin
        if (!rst_n) begin
            tx_data_i2c_sync1 <= 8'h0;
            tx_data_i2c_sync2 <= 8'h0;
            transfer_active_i2c_sync1 <= 1'b0;
            transfer_active_i2c_sync2 <= 1'b0;
        end else begin
            tx_data_i2c_sync1 <= tx_data_stage3;
            tx_data_i2c_sync2 <= tx_data_i2c_sync1;
            transfer_active_i2c_sync1 <= transfer_active_stage4;
            transfer_active_i2c_sync2 <= transfer_active_i2c_sync1;
        end
    end
    
    // I2C接口流水线化
    reg sda_out_stage1, scl_out_stage1;
    reg sda_oe_stage1, scl_oe_stage1;
    reg sda_out, scl_out;
    reg sda_oe, scl_oe;
    
    // I2C时序状态机
    reg [3:0] i2c_state_stage1;
    reg [3:0] i2c_state;
    reg [7:0] i2c_data_stage1;
    reg [7:0] i2c_data;
    reg [2:0] bit_counter_stage1;
    reg [2:0] bit_counter;
    
    // I2C状态定义
    localparam I2C_IDLE = 4'd0;
    localparam I2C_START = 4'd1;
    localparam I2C_ADDR = 4'd2;
    localparam I2C_ADDR_ACK = 4'd3;
    localparam I2C_DATA = 4'd4;
    localparam I2C_DATA_ACK = 4'd5;
    localparam I2C_STOP = 4'd6;
    
    // I2C流水线阶段1 - 状态计算 - 扁平化的if-else结构
    always @(posedge clk_i2c or negedge rst_n) begin
        if (!rst_n) begin
            i2c_state_stage1 <= I2C_IDLE;
            i2c_data_stage1 <= 8'h0;
            bit_counter_stage1 <= 3'h0;
            sda_out_stage1 <= 1'b1;
            scl_out_stage1 <= 1'b1;
            sda_oe_stage1 <= 1'b0;
            scl_oe_stage1 <= 1'b0;
        end else if (i2c_state == I2C_IDLE && transfer_active_i2c_sync2) begin
            i2c_state_stage1 <= I2C_START;
            i2c_data_stage1 <= tx_data_i2c_sync2;
            sda_out_stage1 <= 1'b1;
            scl_out_stage1 <= 1'b1;
            sda_oe_stage1 <= 1'b0;
            scl_oe_stage1 <= 1'b0;
            bit_counter_stage1 <= 3'h7;
        end else if (i2c_state == I2C_IDLE && !transfer_active_i2c_sync2) begin
            i2c_state_stage1 <= I2C_IDLE;
            sda_out_stage1 <= 1'b1;
            scl_out_stage1 <= 1'b1;
            sda_oe_stage1 <= 1'b0;
            scl_oe_stage1 <= 1'b0;
            bit_counter_stage1 <= 3'h7;
        end else if (i2c_state == I2C_START) begin
            i2c_state_stage1 <= I2C_ADDR;
            sda_out_stage1 <= 1'b0;
            scl_out_stage1 <= 1'b1;
            sda_oe_stage1 <= 1'b1;
            scl_oe_stage1 <= 1'b1;
        end else if (i2c_state == I2C_ADDR && bit_counter == 3'h0) begin
            i2c_state_stage1 <= I2C_ADDR_ACK;
            sda_out_stage1 <= i2c_data[bit_counter];
            scl_out_stage1 <= ~scl_out;
            sda_oe_stage1 <= 1'b1;
            scl_oe_stage1 <= 1'b1;
        end else if (i2c_state == I2C_ADDR && bit_counter != 3'h0) begin
            i2c_state_stage1 <= I2C_ADDR;
            bit_counter_stage1 <= bit_counter - 1'b1;
            sda_out_stage1 <= i2c_data[bit_counter];
            scl_out_stage1 <= ~scl_out;
            sda_oe_stage1 <= 1'b1;
            scl_oe_stage1 <= 1'b1;
        end else if (i2c_state == I2C_ADDR_ACK) begin
            i2c_state_stage1 <= I2C_DATA;
            bit_counter_stage1 <= 3'h7;
            sda_out_stage1 <= 1'b1;
            scl_out_stage1 <= ~scl_out;
            sda_oe_stage1 <= 1'b0; // 释放SDA进行ACK
            scl_oe_stage1 <= 1'b1;
        end else if (i2c_state == I2C_DATA && bit_counter == 3'h0) begin
            i2c_state_stage1 <= I2C_DATA_ACK;
            sda_out_stage1 <= i2c_data[bit_counter];
            scl_out_stage1 <= ~scl_out;
            sda_oe_stage1 <= 1'b1;
            scl_oe_stage1 <= 1'b1;
        end else if (i2c_state == I2C_DATA && bit_counter != 3'h0) begin
            i2c_state_stage1 <= I2C_DATA;
            bit_counter_stage1 <= bit_counter - 1'b1;
            sda_out_stage1 <= i2c_data[bit_counter];
            scl_out_stage1 <= ~scl_out;
            sda_oe_stage1 <= 1'b1;
            scl_oe_stage1 <= 1'b1;
        end else if (i2c_state == I2C_DATA_ACK && transfer_active_i2c_sync2) begin
            i2c_state_stage1 <= I2C_DATA;
            i2c_data_stage1 <= tx_data_i2c_sync2;
            bit_counter_stage1 <= 3'h7;
            sda_out_stage1 <= 1'b1;
            scl_out_stage1 <= ~scl_out;
            sda_oe_stage1 <= 1'b0; // 释放SDA进行ACK
            scl_oe_stage1 <= 1'b1;
        end else if (i2c_state == I2C_DATA_ACK && !transfer_active_i2c_sync2) begin
            i2c_state_stage1 <= I2C_STOP;
            sda_out_stage1 <= 1'b1;
            scl_out_stage1 <= ~scl_out;
            sda_oe_stage1 <= 1'b0; // 释放SDA进行ACK
            scl_oe_stage1 <= 1'b1;
        end else if (i2c_state == I2C_STOP) begin
            i2c_state_stage1 <= I2C_IDLE;
            sda_out_stage1 <= 1'b0;
            scl_out_stage1 <= 1'b1;
            sda_oe_stage1 <= 1'b1;
            scl_oe_stage1 <= 1'b1;
        end else begin
            i2c_state_stage1 <= I2C_IDLE;
            sda_out_stage1 <= 1'b1;
            scl_out_stage1 <= 1'b1;
            sda_oe_stage1 <= 1'b0;
            scl_oe_stage1 <= 1'b0;
        end
    end
    
    // I2C流水线阶段2 - 输出控制
    always @(posedge clk_i2c or negedge rst_n) begin
        if (!rst_n) begin
            i2c_state <= I2C_IDLE;
            i2c_data <= 8'h0;
            bit_counter <= 3'h0;
            sda_out <= 1'b1;
            scl_out <= 1'b1;
            sda_oe <= 1'b0;
            scl_oe <= 1'b0;
            rx_data_stage1 <= 8'h0;
        end else begin
            i2c_state <= i2c_state_stage1;
            i2c_data <= i2c_data_stage1;
            bit_counter <= bit_counter_stage1;
            sda_out <= sda_out_stage1;
            scl_out <= scl_out_stage1;
            sda_oe <= sda_oe_stage1;
            scl_oe <= scl_oe_stage1;
            
            // I2C接收数据处理
            if (i2c_state == I2C_DATA && !scl_out && !sda_oe) begin
                rx_data_stage1[bit_counter] <= sda;
            end
        end
    end
    
    // I2C接收数据流水线阶段
    always @(posedge clk_i2c or negedge rst_n) begin
        if (!rst_n) begin
            rx_data_stage2 <= 8'h0;
        end else begin
            rx_data_stage2 <= rx_data_stage1;
        end
    end
    
    // 将I2C接收数据输出
    assign rx_data = rx_data_stage2;
    
    // 连接到物理I2C接口
    assign sda = sda_oe ? sda_out : 1'bz;
    assign scl = scl_oe ? scl_out : 1'bz;
    
endmodule