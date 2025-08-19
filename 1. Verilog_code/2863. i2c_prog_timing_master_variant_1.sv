//SystemVerilog
module i2c_prog_timing_master #(
    parameter DEFAULT_PRESCALER = 16'd100
)(
    input clk, reset_n,
    input [15:0] scl_prescaler,
    input [7:0] tx_data,
    input [6:0] slave_addr,
    input start_tx,
    output reg tx_done,
    inout scl, sda
);
    // 流水线阶段定义
    localparam STAGE_IDLE  = 3'd0,
               STAGE_SETUP = 3'd1,
               STAGE_START = 3'd2,
               STAGE_ADDR  = 3'd3,
               STAGE_DATA  = 3'd4,
               STAGE_STOP  = 3'd5;
               
    // 流水线寄存器
    reg [15:0] active_prescaler_stage1, active_prescaler_stage2;
    reg [15:0] clk_div_count_stage1, clk_div_count_stage2;
    reg scl_int_stage1, scl_int_stage2, sda_int_stage1, sda_int_stage2;
    reg scl_oe_stage1, scl_oe_stage2, sda_oe_stage1, sda_oe_stage2;
    reg [2:0] state_stage1, state_stage2;
    reg [7:0] tx_data_stage1, tx_data_stage2;
    reg [6:0] slave_addr_stage1, slave_addr_stage2;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    reg ready_stage2;
    
    // 预计算比较条件
    wire half_period_reached;
    wire cycle_end;
    wire idle_to_active;
    
    // I2C输出分配
    assign scl = scl_oe_stage2 ? scl_int_stage2 : 1'bz;
    assign sda = sda_oe_stage2 ? sda_int_stage2 : 1'bz;
    
    // 优化比较逻辑
    assign half_period_reached = (clk_div_count_stage1 < (active_prescaler_stage1 >> 1));
    assign cycle_end = (clk_div_count_stage1 >= (active_prescaler_stage1 - 16'd1));
    assign idle_to_active = (state_stage1 == STAGE_IDLE) && start_tx;
    
    // 第一阶段流水线 - 设置和控制
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            active_prescaler_stage1 <= DEFAULT_PRESCALER;
            state_stage1 <= STAGE_IDLE;
            valid_stage1 <= 1'b0;
            tx_data_stage1 <= 8'h0;
            slave_addr_stage1 <= 7'h0;
            scl_oe_stage1 <= 1'b0;
            sda_oe_stage1 <= 1'b0;
            scl_int_stage1 <= 1'b1;
            sda_int_stage1 <= 1'b1;
            clk_div_count_stage1 <= 16'h0;
        end
        else begin
            if (idle_to_active) begin
                active_prescaler_stage1 <= |scl_prescaler ? scl_prescaler : DEFAULT_PRESCALER;
                state_stage1 <= STAGE_SETUP;
                valid_stage1 <= 1'b1;
                tx_data_stage1 <= tx_data;
                slave_addr_stage1 <= slave_addr;
            end
            else if (ready_stage2) begin
                // 当第二阶段准备好时，更新第一阶段状态
                case (state_stage1)
                    STAGE_SETUP: state_stage1 <= valid_stage1 ? STAGE_START : state_stage1;
                    STAGE_START: state_stage1 <= valid_stage1 ? STAGE_ADDR : state_stage1;
                    STAGE_ADDR:  state_stage1 <= valid_stage1 ? STAGE_DATA : state_stage1;
                    STAGE_DATA:  state_stage1 <= valid_stage1 ? STAGE_STOP : state_stage1;
                    STAGE_STOP:  begin
                        if (valid_stage1) begin
                            state_stage1 <= STAGE_IDLE;
                            valid_stage1 <= 1'b0;
                        end
                    end
                    default: state_stage1 <= state_stage1;
                endcase
                
                // 根据状态设置控制信号
                case (state_stage1)
                    STAGE_SETUP: begin
                        scl_oe_stage1 <= 1'b1;
                        sda_oe_stage1 <= 1'b1;
                        scl_int_stage1 <= 1'b1;
                        sda_int_stage1 <= 1'b1;
                    end
                    STAGE_START: begin
                        scl_int_stage1 <= 1'b1;
                        sda_int_stage1 <= 1'b0;
                    end
                    STAGE_ADDR: begin
                        scl_int_stage1 <= half_period_reached;
                        sda_int_stage1 <= slave_addr_stage1[6]; // MSB first
                    end
                    STAGE_DATA: begin
                        scl_int_stage1 <= half_period_reached;
                        sda_int_stage1 <= tx_data_stage1[7]; // MSB first
                    end
                    STAGE_STOP: begin
                        scl_int_stage1 <= 1'b1;
                        sda_int_stage1 <= 1'b0;
                    end
                    default: begin
                        scl_int_stage1 <= 1'b1;
                        sda_int_stage1 <= 1'b1;
                    end
                endcase
                
                // 更新时钟分频计数器 - 优化比较逻辑
                clk_div_count_stage1 <= cycle_end ? 16'h0 : (clk_div_count_stage1 + 16'd1);
            end
        end
    end
    
    // 第二阶段流水线 - 执行I2C操作
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            active_prescaler_stage2 <= DEFAULT_PRESCALER;
            state_stage2 <= STAGE_IDLE;
            valid_stage2 <= 1'b0;
            tx_data_stage2 <= 8'h0;
            slave_addr_stage2 <= 7'h0;
            scl_oe_stage2 <= 1'b0;
            sda_oe_stage2 <= 1'b0;
            scl_int_stage2 <= 1'b1;
            sda_int_stage2 <= 1'b1;
            clk_div_count_stage2 <= 16'h0;
            ready_stage2 <= 1'b1;
            tx_done <= 1'b0;
        end
        else begin
            ready_stage2 <= 1'b1; // 默认准备接收下一阶段数据
            
            if (valid_stage1) begin
                // 从第一阶段接收数据
                active_prescaler_stage2 <= active_prescaler_stage1;
                state_stage2 <= state_stage1;
                valid_stage2 <= valid_stage1;
                tx_data_stage2 <= tx_data_stage1;
                slave_addr_stage2 <= slave_addr_stage1;
                scl_oe_stage2 <= scl_oe_stage1;
                sda_oe_stage2 <= sda_oe_stage1;
                scl_int_stage2 <= scl_int_stage1;
                sda_int_stage2 <= sda_int_stage1;
                clk_div_count_stage2 <= clk_div_count_stage1;
                
                // 状态转移时的特殊操作 - 优化判断条件
                tx_done <= (state_stage1 == STAGE_STOP && state_stage2 != STAGE_STOP) ? 1'b1 :
                          ((state_stage1 == STAGE_IDLE && state_stage2 == STAGE_STOP) ? 1'b0 : tx_done);
            end
        end
    end
    
endmodule