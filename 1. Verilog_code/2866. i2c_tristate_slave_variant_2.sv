//SystemVerilog
module i2c_tristate_slave(
    input clk_i, rst_i,
    input [6:0] addr_i,
    output reg [7:0] data_o,
    output reg valid_o,
    inout sda_io, scl_io
);
    // 状态定义常量
    localparam IDLE = 3'b000;
    localparam ADDR = 3'b001;
    localparam ACK  = 3'b010;
    localparam DATA = 3'b011;
    localparam DONE = 3'b100;
    
    // 三态信号寄存器
    reg sda_oe, sda_o, scl_oe, scl_o;
    reg [2:0] state_r, next_state;
    reg [7:0] shift_r;
    reg [2:0] bit_cnt, bit_cnt_next;
    
    // 检测信号
    reg start_detected;
    reg scl_rise;
    reg addr_match;
    
    // 输入采样寄存器
    reg sda_i_ff, scl_i_ff;
    
    // 组合逻辑信号
    wire sda_i, scl_i;
    
    // 时序控制信号
    reg shift_en;
    reg bit_cnt_en;
    reg bit_cnt_rst;
    reg valid_set;
    reg data_update;
    
    // 三态控制 - 组合逻辑
    assign sda_io = sda_oe ? 1'bz : sda_o;
    assign scl_io = scl_oe ? 1'bz : scl_o;
    
    // 输入采样 - 组合逻辑
    assign sda_i = sda_io;
    assign scl_i = scl_io;

    //===== 组合逻辑部分 =====
    
    // 下一状态逻辑 - 纯组合逻辑
    always @(*) begin
        // 默认状态保持
        next_state = state_r;
        
        case(state_r)
            IDLE: begin
                if (start_detected)
                    next_state = ADDR;
            end
            
            ADDR: begin
                if (bit_cnt == 3'b111)
                    next_state = ACK;
            end
            
            ACK: begin
                next_state = DATA;
            end
            
            DATA: begin
                if (bit_cnt == 3'b111)
                    next_state = DONE;
            end
            
            DONE: begin
                next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // 控制信号组合逻辑
    always @(*) begin
        // 默认值
        shift_en = 1'b0;
        bit_cnt_en = 1'b0;
        bit_cnt_rst = 1'b0;
        valid_set = 1'b0;
        data_update = 1'b0;
        bit_cnt_next = bit_cnt;
        
        case(state_r)
            IDLE: begin
                if (start_detected)
                    bit_cnt_rst = 1'b1;
            end
            
            ADDR: begin
                if (scl_rise) begin
                    shift_en = 1'b1;
                    bit_cnt_en = 1'b1;
                end
            end
            
            DATA: begin
                if (scl_rise) begin
                    shift_en = 1'b1;
                    bit_cnt_en = 1'b1;
                end
                if (next_state == DONE) begin
                    data_update = 1'b1;
                    valid_set = 1'b1;
                end
            end
            
            DONE: begin
                bit_cnt_rst = 1'b1;
            end
        endcase
        
        if (bit_cnt_rst)
            bit_cnt_next = 3'b000;
        else if (bit_cnt_en)
            bit_cnt_next = bit_cnt + 1'b1;
    end

    //===== 时序逻辑部分 =====
    
    // 状态寄存器更新
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            state_r <= IDLE;
        end else begin
            state_r <= next_state;
        end
    end
    
    // 输入采样，使用时序逻辑捕获
    always @(posedge clk_i) begin
        if (rst_i) begin
            sda_i_ff <= 1'b1;
            scl_i_ff <= 1'b1;
        end else begin
            sda_i_ff <= sda_i;
            scl_i_ff <= scl_i;
        end
    end
    
    // 时钟上升沿检测 - 时序逻辑
    always @(posedge clk_i) begin
        if (rst_i)
            scl_rise <= 1'b0;
        else
            scl_rise <= !scl_i_ff && scl_i;
    end
    
    // 地址匹配检测 - 时序逻辑
    always @(posedge clk_i) begin
        if (rst_i)
            addr_match <= 1'b0;
        else if (state_r == ADDR && bit_cnt == 3'b111)
            addr_match <= (shift_r[7:1] == addr_i);
    end
    
    // 起始条件检测 - 时序逻辑
    always @(posedge clk_i) begin
        if (rst_i)
            start_detected <= 1'b0;
        else
            start_detected <= scl_i && sda_i_ff && !sda_i;
    end
    
    // 位计数器 - 时序逻辑
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            bit_cnt <= 3'b000;
        end else begin
            bit_cnt <= bit_cnt_next;
        end
    end
    
    // 移位寄存器 - 时序逻辑
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            shift_r <= 8'h00;
        end else if (shift_en) begin
            shift_r <= {shift_r[6:0], sda_i};
        end
    end
    
    // 输出寄存器和三态控制 - 时序逻辑
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            sda_oe <= 1'b1;
            scl_oe <= 1'b1;
            sda_o <= 1'b1;
            scl_o <= 1'b1;
            data_o <= 8'h00;
            valid_o <= 1'b0;
        end else begin
            // 默认复位有效信号
            valid_o <= 1'b0;
            
            // 特定状态下的控制
            case(state_r)
                IDLE: begin
                    sda_oe <= 1'b1;
                    scl_oe <= 1'b1;
                end
                
                ACK: begin
                    sda_oe <= !addr_match;
                    sda_o <= 1'b0; // ACK
                end
                
                DATA: begin
                    sda_oe <= 1'b1; // 释放SDA线
                end
            endcase
            
            // 数据更新和有效标志设置
            if (data_update) begin
                data_o <= {shift_r[6:0], sda_i};
            end
            
            if (valid_set) begin
                valid_o <= 1'b1;
            end
        end
    end
endmodule