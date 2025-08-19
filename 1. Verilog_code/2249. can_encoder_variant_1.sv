//SystemVerilog
// 顶层模块
module can_encoder (
    input wire clk,
    input wire tx_req,
    input wire [10:0] id,
    input wire [7:0] data,
    output wire tx,
    output wire tx_ack
);
    // 内部连线
    wire tx_bit;
    wire state_reset;
    wire [3:0] state;
    wire [3:0] bit_counter;
    wire [14:0] crc;
    wire crc_update_en;
    wire crc_input_bit;
    
    // 寄存输入信号以优化时序
    reg [10:0] id_reg;
    reg [7:0] data_reg;
    reg tx_req_reg;
    
    always @(posedge clk) begin
        id_reg <= id;
        data_reg <= data;
        tx_req_reg <= tx_req;
    end

    // 控制状态模块实例
    can_fsm u_can_fsm (
        .clk(clk),
        .tx_req(tx_req_reg),
        .bit_counter(bit_counter),
        .state(state),
        .state_reset(state_reset),
        .tx_ack(tx_ack)
    );

    // 位计数器模块实例
    bit_counter u_bit_counter (
        .clk(clk),
        .state(state),
        .state_reset(state_reset),
        .bit_counter(bit_counter)
    );

    // CRC生成器模块实例
    crc_generator u_crc_generator (
        .clk(clk),
        .state_reset(state_reset),
        .crc_update_en(crc_update_en),
        .crc_input_bit(crc_input_bit),
        .crc(crc)
    );

    // 数据选择器模块实例
    data_selector u_data_selector (
        .state(state),
        .bit_counter(bit_counter),
        .id(id_reg),
        .data(data_reg),
        .crc(crc),
        .tx_bit(tx_bit),
        .crc_update_en(crc_update_en),
        .crc_input_bit(crc_input_bit)
    );

    // 发送器模块实例
    transmitter u_transmitter (
        .clk(clk),
        .tx_bit(tx_bit),
        .tx(tx)
    );

endmodule

// 有限状态机控制模块
module can_fsm (
    input wire clk,
    input wire tx_req,
    input wire [3:0] bit_counter,
    output reg [3:0] state,
    output wire state_reset,
    output wire tx_ack
);
    // 状态定义
    localparam IDLE = 4'd0;
    localparam ID_TRANSMISSION = 4'd1;
    localparam RTR_BIT = 4'd2;
    localparam DATA_LENGTH = 4'd3;
    localparam DATA_TRANSMISSION = 4'd4;
    localparam CRC_TRANSMISSION = 4'd5;
    
    // 寄存bit_counter信号
    reg [3:0] bit_counter_reg;
    
    always @(posedge clk) begin
        bit_counter_reg <= bit_counter;
    end

    // 状态转换逻辑
    always @(posedge clk) begin
        case(state)
            IDLE: 
                if(tx_req) state <= ID_TRANSMISSION;
            
            ID_TRANSMISSION: 
                if(bit_counter_reg == 4'd10) state <= RTR_BIT;
            
            RTR_BIT: 
                state <= DATA_LENGTH;
            
            DATA_LENGTH: 
                if(bit_counter_reg == 4'd3) state <= DATA_TRANSMISSION;
            
            DATA_TRANSMISSION: 
                if(bit_counter_reg == 4'd7) state <= CRC_TRANSMISSION;
            
            CRC_TRANSMISSION: 
                if(bit_counter_reg == 4'd14) state <= IDLE;
            
            default: 
                state <= IDLE;
        endcase
    end

    // 状态重置信号
    assign state_reset = (state == IDLE && tx_req);
    
    // 应答信号
    assign tx_ack = (state == IDLE);

endmodule

// 位计数器模块
module bit_counter (
    input wire clk,
    input wire [3:0] state,
    input wire state_reset,
    output reg [3:0] bit_counter
);
    // 状态定义
    localparam IDLE = 4'd0;
    localparam ID_TRANSMISSION = 4'd1;
    localparam RTR_BIT = 4'd2;
    localparam DATA_LENGTH = 4'd3;
    localparam DATA_TRANSMISSION = 4'd4;
    localparam CRC_TRANSMISSION = 4'd5;
    
    // 寄存状态信号以优化时序
    reg [3:0] state_reg;
    reg state_reset_reg;
    
    always @(posedge clk) begin
        state_reg <= state;
        state_reset_reg <= state_reset;
    end

    // 计数器逻辑
    always @(posedge clk) begin
        if(state_reset_reg) begin
            bit_counter <= 4'd0;
        end
        else begin
            case(state_reg)
                ID_TRANSMISSION: 
                    if(bit_counter < 4'd10) bit_counter <= bit_counter + 4'd1;
                
                DATA_LENGTH: 
                    if(bit_counter < 4'd3) bit_counter <= bit_counter + 4'd1;
                
                DATA_TRANSMISSION: 
                    if(bit_counter < 4'd7) bit_counter <= bit_counter + 4'd1;
                
                CRC_TRANSMISSION: 
                    if(bit_counter < 4'd14) bit_counter <= bit_counter + 4'd1;
                
                RTR_BIT: 
                    bit_counter <= 4'd0;
                
                default: 
                    bit_counter <= bit_counter;
            endcase
        end
    end
endmodule

// CRC生成器模块
module crc_generator (
    input wire clk,
    input wire state_reset,
    input wire crc_update_en,
    input wire crc_input_bit,
    output reg [14:0] crc
);
    // CRC多项式常量
    localparam CRC_POLY = 15'h4599;
    
    // 寄存输入信号以优化时序
    reg state_reset_reg;
    reg crc_update_en_reg;
    reg crc_input_bit_reg;
    
    always @(posedge clk) begin
        state_reset_reg <= state_reset;
        crc_update_en_reg <= crc_update_en;
        crc_input_bit_reg <= crc_input_bit;
    end

    // CRC计算逻辑
    always @(posedge clk) begin
        if(state_reset_reg) begin
            crc <= 15'h7FF; // 初始值
        end
        else if(crc_update_en_reg) begin
            crc <= (crc << 1) ^ ((crc[14] ^ crc_input_bit_reg) ? CRC_POLY : 15'h0000);
        end
    end
endmodule

// 数据选择器模块
module data_selector (
    input wire [3:0] state,
    input wire [3:0] bit_counter,
    input wire [10:0] id,
    input wire [7:0] data,
    input wire [14:0] crc,
    output reg tx_bit,
    output reg crc_update_en,
    output reg crc_input_bit
);
    // 状态定义
    localparam IDLE = 4'd0;
    localparam ID_TRANSMISSION = 4'd1;
    localparam RTR_BIT = 4'd2;
    localparam DATA_LENGTH = 4'd3;
    localparam DATA_TRANSMISSION = 4'd4;
    localparam CRC_TRANSMISSION = 4'd5;
    
    // 预计算组合逻辑结果用于流水线
    reg [10:0] id_shifted;
    reg [7:0] data_shifted;
    reg [14:0] crc_shifted;
    
    always @(*) begin
        id_shifted = id >> (10 - bit_counter);
        data_shifted = data >> (7 - bit_counter);
        crc_shifted = crc >> (14 - bit_counter);
    end

    // 数据选择逻辑
    always @(*) begin
        crc_update_en = 1'b0;
        crc_input_bit = 1'b0;
        
        case(state)
            IDLE: begin
                tx_bit = 1'b1; // 空闲状态为高电平
                crc_update_en = 1'b0;
            end
            
            ID_TRANSMISSION: begin
                tx_bit = id_shifted[0];
                crc_update_en = 1'b1;
                crc_input_bit = id_shifted[0];
            end
            
            RTR_BIT: begin
                tx_bit = 1'b0; // 数据帧
                crc_update_en = 1'b1;
                crc_input_bit = 1'b0;
            end
            
            DATA_LENGTH: begin
                tx_bit = (bit_counter < 4) ? 1'b0 : 1'b1; // 8字节数据
                crc_update_en = 1'b1;
                crc_input_bit = (bit_counter < 4) ? 1'b0 : 1'b1;
            end
            
            DATA_TRANSMISSION: begin
                tx_bit = data_shifted[0];
                crc_update_en = 1'b1;
                crc_input_bit = data_shifted[0];
            end
            
            CRC_TRANSMISSION: begin
                tx_bit = crc_shifted[0];
                crc_update_en = 1'b0;
            end
            
            default: begin
                tx_bit = 1'b1;
                crc_update_en = 1'b0;
            end
        endcase
    end
endmodule

// 发送器模块
module transmitter (
    input wire clk,
    input wire tx_bit,
    output reg tx
);
    // 将tx_bit寄存以减少发送延迟
    reg tx_bit_reg;
    
    always @(posedge clk) begin
        tx_bit_reg <= tx_bit;
        tx <= tx_bit_reg;
    end
endmodule