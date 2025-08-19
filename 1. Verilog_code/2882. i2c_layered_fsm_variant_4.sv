//SystemVerilog - IEEE 1364-2005
`timescale 1ns / 1ps
module i2c_layered_fsm #(
    parameter FSM_LAYERS = 2
)(
    input clk,
    input rst_n,
    inout sda,
    inout scl,
    output reg [7:0] debug_state
);
    // 分层状态机控制 - 替换枚举类型
    localparam LAYER0_IDLE = 2'b00;
    localparam LAYER0_ADDR = 2'b01;
    localparam LAYER0_DATA = 2'b10;

    localparam LAYER1_WRITE = 2'b00;
    localparam LAYER1_READ = 2'b01;
    localparam LAYER1_ACK = 2'b10;

    // 主状态寄存器
    reg [1:0] layer0_state_stage1, layer0_state_stage2, layer0_state_stage3;
    reg [1:0] layer1_state_stage1, layer1_state_stage2, layer1_state_stage3;
    reg layer_activate_stage1, layer_activate_stage2, layer_activate_stage3;
    
    // 添加缺失的信号并拆分成多级流水线
    reg start_cond_stage1, start_cond_stage2, start_cond_stage3;
    reg addr_done_stage1, addr_done_stage2, addr_done_stage3;
    
    // 为高扇出信号添加多级缓冲寄存器
    reg [1:0] layer0_state_buf1_stage1, layer0_state_buf2_stage1;
    reg [1:0] layer0_state_buf1_stage2, layer0_state_buf2_stage2;
    reg [1:0] layer0_state_buf1_stage3, layer0_state_buf2_stage3;
    
    reg [1:0] layer1_state_buf1_stage1, layer1_state_buf2_stage1;
    reg [1:0] layer1_state_buf1_stage2, layer1_state_buf2_stage2;
    reg [1:0] layer1_state_buf1_stage3, layer1_state_buf2_stage3;
    
    reg LAYER0_IDLE_buf1_stage1, LAYER0_IDLE_buf2_stage1;
    reg LAYER0_IDLE_buf1_stage2, LAYER0_IDLE_buf2_stage2;
    
    reg LAYER1_WRITE_buf1_stage1, LAYER1_WRITE_buf2_stage1;
    reg LAYER1_WRITE_buf1_stage2, LAYER1_WRITE_buf2_stage2;
    
    // SDA/SCL 信号流水线缓冲
    reg sda_stage1, sda_stage2;
    reg scl_stage1, scl_stage2;
    
    // 初始化状态
    initial begin
        layer0_state_stage1 = LAYER0_IDLE;
        layer0_state_stage2 = LAYER0_IDLE;
        layer0_state_stage3 = LAYER0_IDLE;
        
        layer1_state_stage1 = LAYER1_WRITE;
        layer1_state_stage2 = LAYER1_WRITE;
        layer1_state_stage3 = LAYER1_WRITE;
        
        layer_activate_stage1 = 1'b0;
        layer_activate_stage2 = 1'b0;
        layer_activate_stage3 = 1'b0;
        
        debug_state = 8'h00;
        
        // 初始化缓冲寄存器 - 第一级
        layer0_state_buf1_stage1 = LAYER0_IDLE;
        layer0_state_buf2_stage1 = LAYER0_IDLE;
        layer1_state_buf1_stage1 = LAYER1_WRITE;
        layer1_state_buf2_stage1 = LAYER1_WRITE;
        LAYER0_IDLE_buf1_stage1 = 1'b1;
        LAYER0_IDLE_buf2_stage1 = 1'b1;
        LAYER1_WRITE_buf1_stage1 = 1'b1;
        LAYER1_WRITE_buf2_stage1 = 1'b1;
        
        // 初始化缓冲寄存器 - 第二级
        layer0_state_buf1_stage2 = LAYER0_IDLE;
        layer0_state_buf2_stage2 = LAYER0_IDLE;
        layer1_state_buf1_stage2 = LAYER1_WRITE;
        layer1_state_buf2_stage2 = LAYER1_WRITE;
        LAYER0_IDLE_buf1_stage2 = 1'b1;
        LAYER0_IDLE_buf2_stage2 = 1'b1;
        LAYER1_WRITE_buf1_stage2 = 1'b1;
        LAYER1_WRITE_buf2_stage2 = 1'b1;
        
        // 初始化第三级
        layer0_state_buf1_stage3 = LAYER0_IDLE;
        layer0_state_buf2_stage3 = LAYER0_IDLE;
        layer1_state_buf1_stage3 = LAYER1_WRITE;
        layer1_state_buf2_stage3 = LAYER1_WRITE;
        
        // 信号状态初始化
        start_cond_stage1 = 1'b0;
        start_cond_stage2 = 1'b0;
        start_cond_stage3 = 1'b0;
        addr_done_stage1 = 1'b0;
        addr_done_stage2 = 1'b0;
        addr_done_stage3 = 1'b0;
        
        // 初始化I2C信号流水线
        sda_stage1 = 1'b1;
        sda_stage2 = 1'b1;
        scl_stage1 = 1'b1;
        scl_stage2 = 1'b1;
    end

    // 第一级流水线 - 输入信号采样和初始缓冲
    always @(posedge clk) begin
        // I2C信号采样
        sda_stage1 <= sda;
        scl_stage1 <= scl;
        
        // 状态缓存初级更新
        layer0_state_buf1_stage1 <= layer0_state_stage3;
        layer1_state_buf1_stage1 <= layer1_state_stage3;
        
        // 常量缓冲
        LAYER0_IDLE_buf1_stage1 <= (LAYER0_IDLE == 2'b00);
        LAYER1_WRITE_buf1_stage1 <= (LAYER1_WRITE == 2'b00);
    end

    // 第二级流水线 - 缓冲信号继续传播
    always @(posedge clk) begin
        // I2C信号继续传播
        sda_stage2 <= sda_stage1;
        scl_stage2 <= scl_stage1;
        
        // 状态缓冲继续传播
        layer0_state_buf1_stage2 <= layer0_state_buf1_stage1;
        layer0_state_buf2_stage1 <= layer0_state_buf1_stage1;
        layer1_state_buf1_stage2 <= layer1_state_buf1_stage1;
        layer1_state_buf2_stage1 <= layer1_state_buf1_stage1;
        
        // 常量缓冲继续传播
        LAYER0_IDLE_buf1_stage2 <= LAYER0_IDLE_buf1_stage1;
        LAYER0_IDLE_buf2_stage1 <= LAYER0_IDLE_buf1_stage1;
        LAYER1_WRITE_buf1_stage2 <= LAYER1_WRITE_buf1_stage1;
        LAYER1_WRITE_buf2_stage1 <= LAYER1_WRITE_buf1_stage1;
    end
    
    // 第三级流水线 - 缓冲信号最终传播
    always @(posedge clk) begin
        // 状态缓冲最终阶段
        layer0_state_buf2_stage2 <= layer0_state_buf1_stage2;
        layer0_state_buf1_stage3 <= layer0_state_buf1_stage2;
        layer0_state_buf2_stage3 <= layer0_state_buf2_stage2;
        
        layer1_state_buf2_stage2 <= layer1_state_buf1_stage2;
        layer1_state_buf1_stage3 <= layer1_state_buf1_stage2;
        layer1_state_buf2_stage3 <= layer1_state_buf2_stage2;
        
        // 常量缓冲最终阶段
        LAYER0_IDLE_buf2_stage2 <= LAYER0_IDLE_buf1_stage2;
        LAYER1_WRITE_buf2_stage2 <= LAYER1_WRITE_buf1_stage2;
    end

    // I2C条件信号检测 - 分布在多个流水线阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_cond_stage1 <= 1'b0;
        end else begin
            // 第一阶段 - SDA下降沿检测
            start_cond_stage1 <= (scl_stage2 && !sda_stage2);
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_cond_stage2 <= 1'b0;
            start_cond_stage3 <= 1'b0;
        end else begin
            // 第二、三阶段 - 起始条件传播
            start_cond_stage2 <= start_cond_stage1;
            start_cond_stage3 <= start_cond_stage2;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_done_stage1 <= 1'b0;
        end else begin
            // 第一阶段 - 地址完成检测
            addr_done_stage1 <= (layer0_state_buf1_stage3 == LAYER0_ADDR && 
                                 layer1_state_buf1_stage3 == LAYER1_ACK);
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_done_stage2 <= 1'b0;
            addr_done_stage3 <= 1'b0;
        end else begin
            // 第二、三阶段 - 地址完成传播
            addr_done_stage2 <= addr_done_stage1;
            addr_done_stage3 <= addr_done_stage2;
        end
    end

    // 状态转换中间寄存器 - 将状态转换逻辑分散到多级流水线
    reg layer0_next_state_en_stage1, layer0_next_state_en_stage2;
    reg [1:0] layer0_next_state_stage1, layer0_next_state_stage2;
    reg layer1_next_state_en_stage1, layer1_next_state_en_stage2;
    reg [1:0] layer1_next_state_stage1, layer1_next_state_stage2;
    reg next_layer_activate_stage1, next_layer_activate_stage2;
    
    // 流水线第一阶段 - 条件检测
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            layer0_next_state_en_stage1 <= 1'b0;
            layer0_next_state_stage1 <= LAYER0_IDLE;
            next_layer_activate_stage1 <= 1'b0;
        end else begin
            // Layer0 检测部分
            if (layer0_state_buf2_stage3 == LAYER0_IDLE && start_cond_stage3) begin
                layer0_next_state_en_stage1 <= 1'b1;
                layer0_next_state_stage1 <= LAYER0_ADDR;
                next_layer_activate_stage1 <= 1'b1;
            end else if (layer0_state_buf2_stage3 == LAYER0_ADDR && addr_done_stage3) begin
                layer0_next_state_en_stage1 <= 1'b1;
                layer0_next_state_stage1 <= LAYER0_DATA;
                next_layer_activate_stage1 <= 1'b0;
            end else if (layer0_state_buf2_stage3 == 2'b11) begin  // 非法状态处理
                layer0_next_state_en_stage1 <= 1'b1;
                layer0_next_state_stage1 <= LAYER0_IDLE;
                next_layer_activate_stage1 <= 1'b0;
            end else begin
                layer0_next_state_en_stage1 <= 1'b0;
                layer0_next_state_stage1 <= layer0_state_stage3;
                next_layer_activate_stage1 <= layer_activate_stage3;
            end
        end
    end
    
    // 流水线第二阶段 - Layer1状态机逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            layer1_next_state_en_stage1 <= 1'b0;
            layer1_next_state_stage1 <= LAYER1_WRITE;
        end else begin
            // Layer1 逻辑判断
            if (layer_activate_stage3) begin
                if (layer1_state_buf2_stage3 == LAYER1_WRITE) begin
                    layer1_next_state_en_stage1 <= 1'b1;
                    layer1_next_state_stage1 <= LAYER1_ACK;
                end else if (layer1_state_buf2_stage3 == LAYER1_ACK) begin
                    layer1_next_state_en_stage1 <= 1'b1;
                    layer1_next_state_stage1 <= LAYER1_WRITE;
                end else if (layer1_state_buf2_stage3 == LAYER1_READ) begin
                    // 读取逻辑 - 保持当前状态
                    layer1_next_state_en_stage1 <= 1'b0;
                    layer1_next_state_stage1 <= layer1_state_stage3;
                end else begin  // 未知状态处理
                    layer1_next_state_en_stage1 <= 1'b1;
                    layer1_next_state_stage1 <= LAYER1_WRITE;
                end
            end else begin
                layer1_next_state_en_stage1 <= 1'b0;
                layer1_next_state_stage1 <= layer1_state_stage3;
            end
        end
    end
    
    // 流水线状态和控制信号传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            layer0_next_state_en_stage2 <= 1'b0;
            layer0_next_state_stage2 <= LAYER0_IDLE;
            layer1_next_state_en_stage2 <= 1'b0;
            layer1_next_state_stage2 <= LAYER1_WRITE;
            next_layer_activate_stage2 <= 1'b0;
        end else begin
            // 将状态信息传递到下一级流水线
            layer0_next_state_en_stage2 <= layer0_next_state_en_stage1;
            layer0_next_state_stage2 <= layer0_next_state_stage1;
            layer1_next_state_en_stage2 <= layer1_next_state_en_stage1;
            layer1_next_state_stage2 <= layer1_next_state_stage1;
            next_layer_activate_stage2 <= next_layer_activate_stage1;
        end
    end
    
    // 最终状态更新 - 流水线最后阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            layer0_state_stage1 <= LAYER0_IDLE;
            layer0_state_stage2 <= LAYER0_IDLE;
            layer0_state_stage3 <= LAYER0_IDLE;
            
            layer1_state_stage1 <= LAYER1_WRITE;
            layer1_state_stage2 <= LAYER1_WRITE;
            layer1_state_stage3 <= LAYER1_WRITE;
            
            layer_activate_stage1 <= 1'b0;
            layer_activate_stage2 <= 1'b0;
            layer_activate_stage3 <= 1'b0;
            
            debug_state <= 8'h00;
        end else begin
            // 流水线状态传递
            layer0_state_stage1 <= layer0_state_stage2;
            layer0_state_stage2 <= layer0_state_stage3;
            
            layer1_state_stage1 <= layer1_state_stage2;
            layer1_state_stage2 <= layer1_state_stage3;
            
            layer_activate_stage1 <= layer_activate_stage2;
            layer_activate_stage2 <= layer_activate_stage3;
            
            // 基于流水线最后阶段的状态更新
            if (layer0_next_state_en_stage2) begin
                layer0_state_stage3 <= layer0_next_state_stage2;
            end
            
            if (layer1_next_state_en_stage2) begin
                layer1_state_stage3 <= layer1_next_state_stage2;
            end
            
            layer_activate_stage3 <= next_layer_activate_stage2;
            
            // 更新调试状态
            debug_state <= {layer0_state_stage3, layer1_state_stage3, 2'b00, sda_stage2, scl_stage2};
        end
    end
endmodule