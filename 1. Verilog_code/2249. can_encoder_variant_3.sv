//SystemVerilog
//IEEE 1364-2005 Verilog
module can_encoder (
    input clk, tx_req,
    input [10:0] id,
    input [7:0] data,
    output reg tx,
    output tx_ack
);
    // 状态编码优化
    localparam IDLE        = 4'd0,
               TX_ID       = 4'd1,
               TX_RTR      = 4'd2,
               TX_LEN      = 4'd3,
               TX_DATA     = 4'd4,
               TX_CRC      = 4'd5;
               
    // 增加流水线级数，将CRC计算和状态逻辑分离
    reg [14:0] crc_stage1, crc_stage2;
    reg [3:0] state_stage1, state_stage2, next_state;
    reg [3:0] bit_counter_stage1, bit_counter_stage2, next_bit_counter;
    reg tx_stage1, next_tx;
    reg [14:0] next_crc;
    
    // 流水线第一级 - CRC因子计算
    reg tx_factor_stage1;
    wire crc_factor_stage1 = (crc_stage1[14] ^ tx_factor_stage1) ? 1'b1 : 1'b0;
    reg crc_factor_stage2;
    
    // 流水线第二级 - CRC多项式选择
    wire [14:0] crc_poly = 15'h4599;
    reg [14:0] crc_term_stage2;
    
    // 流水线第三级 - CRC更新计算
    wire [14:0] crc_update = (crc_stage2 << 1) ^ crc_term_stage2;
    
    // ID寄存器缓存，避免跨时钟周期读取
    reg [10:0] id_reg;
    reg [7:0] data_reg;
    
    // 计算下一状态逻辑
    always @(*) begin
        next_state = state_stage2;
        next_bit_counter = bit_counter_stage2;
        next_tx = tx_stage1;
        next_crc = crc_stage2;
        
        case(state_stage2)
            IDLE: begin
                if(tx_req) begin
                    next_tx = 1'b0; // Start bit
                    next_crc = 15'h7FF;
                    next_state = TX_ID;
                    next_bit_counter = 4'd0;
                end
            end
            
            TX_ID: begin
                next_tx = id_reg[10 - bit_counter_stage2];
                next_crc = crc_update;
                
                if(bit_counter_stage2 == 4'd10) begin
                    next_state = TX_RTR;
                    next_bit_counter = 4'd0;
                end else begin
                    next_bit_counter = bit_counter_stage2 + 4'd1;
                end
            end
            
            TX_RTR: begin
                next_tx = 1'b0; // 数据帧
                next_crc = crc_update;
                next_state = TX_LEN;
                next_bit_counter = 4'd0;
            end
            
            TX_LEN: begin
                next_tx = (bit_counter_stage2 >= 4'd4); // 优化比较逻辑
                next_crc = crc_update;
                
                if(bit_counter_stage2 == 4'd3) begin
                    next_state = TX_DATA;
                    next_bit_counter = 4'd0;
                end else begin
                    next_bit_counter = bit_counter_stage2 + 4'd1;
                end
            end
            
            TX_DATA: begin
                next_tx = data_reg[7 - bit_counter_stage2];
                next_crc = crc_update;
                
                if(bit_counter_stage2 == 4'd7) begin
                    next_state = TX_CRC;
                    next_bit_counter = 4'd0;
                end else begin
                    next_bit_counter = bit_counter_stage2 + 4'd1;
                end
            end
            
            TX_CRC: begin
                next_tx = crc_stage2[14 - bit_counter_stage2];
                
                if(bit_counter_stage2 == 4'd14) begin
                    next_state = IDLE;
                end else begin
                    next_bit_counter = bit_counter_stage2 + 4'd1;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // 流水线第一级 - 保存输入和初始状态
    always @(posedge clk) begin
        // 输入数据缓存
        id_reg <= id;
        data_reg <= data;
        
        // 第一流水线级寄存器更新
        state_stage1 <= next_state;
        bit_counter_stage1 <= next_bit_counter;
        tx_stage1 <= next_tx;
        crc_stage1 <= next_crc;
        
        // CRC因子预计算
        tx_factor_stage1 <= tx_stage1;
    end
    
    // 流水线第二级 - CRC计算中间结果
    always @(posedge clk) begin
        // 第二流水线级寄存器更新
        state_stage2 <= state_stage1;
        bit_counter_stage2 <= bit_counter_stage1;
        crc_stage2 <= crc_stage1;
        
        // CRC因子寄存
        crc_factor_stage2 <= crc_factor_stage1;
        
        // CRC项计算
        crc_term_stage2 <= crc_factor_stage2 ? crc_poly : 15'h0;
    end
    
    // 流水线第三级 - 最终输出寄存器
    always @(posedge clk) begin
        // 输出寄存器
        tx <= tx_stage1;
    end
    
    // 输出逻辑
    assign tx_ack = (state_stage2 == IDLE);
endmodule