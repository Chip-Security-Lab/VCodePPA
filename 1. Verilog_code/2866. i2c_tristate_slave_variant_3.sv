//SystemVerilog
module i2c_tristate_slave(
    input clk_i, rst_i,
    input [6:0] addr_i,
    output reg [7:0] data_o,
    output reg valid_o,
    inout sda_io, scl_io
);
    // 三态缓冲控制信号
    reg sda_oe, sda_o, scl_oe, scl_o;
    wire sda_i, scl_i;
    
    // 前移后的输入寄存器
    reg sda_i_reg, scl_i_reg;
    
    // 流水线阶段状态寄存器
    reg [2:0] state_stage1, state_stage2;
    reg [7:0] shift_stage1, shift_stage2;
    reg [2:0] bit_cnt_stage1, bit_cnt_stage2;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    reg start_detected, start_detected_stage1, start_detected_stage2;
    reg addr_match_stage1, addr_match_stage2;
    
    // 三态控制
    assign sda_io = sda_oe ? 1'bz : sda_o;
    assign scl_io = scl_oe ? 1'bz : scl_o;
    assign sda_i = sda_io;
    assign scl_i = scl_io;
    
    // 输入信号寄存化 - 前向重定时
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            sda_i_reg <= 1'b1;
            scl_i_reg <= 1'b1;
        end else begin
            sda_i_reg <= sda_i;
            scl_i_reg <= scl_i;
        end
    end
    
    // 起始条件检测
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            start_detected <= 1'b0;
        end else begin
            start_detected <= scl_i_reg && sda_i_reg && !sda_i;
        end
    end
    
    // 第一级流水线：起始条件检测传递
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            start_detected_stage1 <= 1'b0;
        end else begin
            start_detected_stage1 <= start_detected;
        end
    end
    
    // 第一级流水线：状态控制
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            state_stage1 <= 3'b000;
        end else begin
            case(state_stage1)
                3'b000: begin
                    if (start_detected)
                        state_stage1 <= 3'b001;
                end
                3'b001: begin // 地址接收阶段
                    if (scl_i_reg && bit_cnt_stage1 == 3'b111)
                        state_stage1 <= 3'b010;
                end
                3'b010: begin // ACK阶段
                    state_stage1 <= 3'b011;
                end
                3'b011: begin // 数据接收阶段
                    if (scl_i_reg && bit_cnt_stage1 == 3'b111)
                        state_stage1 <= 3'b100;
                end
                3'b100: begin // 完成阶段
                    state_stage1 <= 3'b000;
                end
                default: state_stage1 <= 3'b000;
            endcase
        end
    end
    
    // 第一级流水线：位计数器控制
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            bit_cnt_stage1 <= 3'b000;
        end else begin
            case(state_stage1)
                3'b000: begin
                    if (start_detected)
                        bit_cnt_stage1 <= 3'b000;
                end
                3'b001: begin // 地址接收阶段
                    if (scl_i_reg && bit_cnt_stage1 != 3'b111)
                        bit_cnt_stage1 <= bit_cnt_stage1 + 1;
                end
                3'b010: begin // ACK阶段
                    bit_cnt_stage1 <= 3'b000;
                end
                3'b011: begin // 数据接收阶段
                    if (scl_i_reg && bit_cnt_stage1 != 3'b111)
                        bit_cnt_stage1 <= bit_cnt_stage1 + 1;
                end
                default: ;
            endcase
        end
    end
    
    // 第一级流水线：移位寄存器控制
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            shift_stage1 <= 8'h00;
        end else begin
            if ((state_stage1 == 3'b001 || state_stage1 == 3'b011) && 
                scl_i_reg && bit_cnt_stage1 != 3'b111) begin
                shift_stage1 <= {shift_stage1[6:0], sda_i_reg};
            end
        end
    end
    
    // 第一级流水线：地址匹配检测
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            addr_match_stage1 <= 1'b0;
        end else begin
            if (state_stage1 == 3'b001 && scl_i_reg && bit_cnt_stage1 == 3'b111) begin
                addr_match_stage1 <= (shift_stage1[7:1] == addr_i);
            end
        end
    end
    
    // 第一级流水线：有效数据标志
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            valid_stage1 <= 1'b0;
        end else begin
            if (state_stage1 == 3'b011 && scl_i_reg && bit_cnt_stage1 == 3'b111)
                valid_stage1 <= 1'b1;
            else if (state_stage1 == 3'b100 || state_stage1 == 3'b000)
                valid_stage1 <= 1'b0;
        end
    end
    
    // 第二级流水线：状态和控制信号传递
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            state_stage2 <= 3'b000;
            shift_stage2 <= 8'h00;
            bit_cnt_stage2 <= 3'b000;
            valid_stage2 <= 1'b0;
            addr_match_stage2 <= 1'b0;
            start_detected_stage2 <= 1'b0;
        end else begin
            state_stage2 <= state_stage1;
            shift_stage2 <= shift_stage1;
            bit_cnt_stage2 <= bit_cnt_stage1;
            valid_stage2 <= valid_stage1;
            addr_match_stage2 <= addr_match_stage1;
            start_detected_stage2 <= start_detected_stage1;
        end
    end
    
    // 输出控制：SDA输出使能
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            sda_oe <= 1'b1;
        end else begin
            case(state_stage2)
                3'b000, 3'b001, 3'b011: begin
                    sda_oe <= 1'b1; // 监听模式
                end
                3'b010: begin // ACK阶段
                    sda_oe <= addr_match_stage2 ? 1'b0 : 1'b1;
                end
                default: begin
                    sda_oe <= 1'b1;
                end
            endcase
        end
    end
    
    // 输出控制：SCL输出使能和输出值
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            scl_oe <= 1'b1;
            scl_o <= 1'b1;
        end else begin
            scl_oe <= 1'b1; // 始终为高阻态（从机不控制SCL）
            scl_o <= 1'b1;  // 默认高电平
        end
    end
    
    // 输出控制：SDA输出值
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            sda_o <= 1'b1;
        end else begin
            if (state_stage2 == 3'b010 && addr_match_stage2)
                sda_o <= 1'b0; // ACK信号
            else
                sda_o <= 1'b1;
        end
    end
    
    // 数据输出和有效标志
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            data_o <= 8'h00;
            valid_o <= 1'b0;
        end else begin
            if (state_stage2 == 3'b100 && valid_stage2) begin
                data_o <= shift_stage2;
                valid_o <= 1'b1;
            end else begin
                valid_o <= 1'b0;
            end
        end
    end
endmodule