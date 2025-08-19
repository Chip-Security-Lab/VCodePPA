//SystemVerilog
module dram_ctrl_pipelined #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32
)(
    input clk,
    input rst_n,
    input cmd_valid,
    input [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg ready
);
    // 使用one-hot编码定义状态，提高状态比较效率
    localparam [2:0] IDLE = 3'b001,
                     ACTIVE = 3'b010,
                     READ = 3'b100,
                     PRECHARGE = 3'b011;
    
    // 流水线寄存器 - 状态和控制信号
    reg [2:0] current_state_stage1;
    reg [2:0] current_state_stage2;
    reg [2:0] current_state_stage3;
    
    // 流水线寄存器 - 地址
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg [ADDR_WIDTH-1:0] addr_stage2;
    
    // 流水线寄存器 - 计时器
    reg [3:0] timer_stage1;
    reg [3:0] timer_stage2;
    
    // 流水线寄存器 - 有效信号
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    
    // 预计算状态转换条件
    wire timer_zero_stage1 = (timer_stage1 == 4'd0);
    wire timer_zero_stage2 = (timer_stage2 == 4'd0);
    wire is_idle_stage3 = (current_state_stage3 == IDLE);
    
    // 流水线阶段1: 命令解码和状态转换
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            current_state_stage1 <= IDLE;
            timer_stage1 <= 4'd0;
            valid_stage1 <= 1'b0;
            addr_stage1 <= {ADDR_WIDTH{1'b0}};
        end else begin
            // 状态机逻辑优化
            case(current_state_stage1)
                IDLE: begin
                    if(cmd_valid) begin
                        current_state_stage1 <= ACTIVE;
                        timer_stage1 <= 4'd3;  // tRCD=3
                        valid_stage1 <= 1'b1;
                        addr_stage1 <= addr;
                    end else begin
                        valid_stage1 <= 1'b0;
                    end
                end
                
                ACTIVE: begin
                    if(timer_zero_stage1) begin
                        current_state_stage1 <= READ;
                    end else begin
                        timer_stage1 <= timer_stage1 - 4'd1;
                    end
                    valid_stage1 <= 1'b1;
                end
                
                READ: begin
                    current_state_stage1 <= PRECHARGE;
                    timer_stage1 <= 4'd2; // tRP=2
                    valid_stage1 <= 1'b1;
                end
                
                PRECHARGE: begin
                    if(timer_zero_stage1) begin
                        current_state_stage1 <= IDLE;
                    end else begin
                        timer_stage1 <= timer_stage1 - 4'd1;
                    end
                    valid_stage1 <= 1'b1;
                end
                
                default: current_state_stage1 <= IDLE;
            endcase
        end
    end
    
    // 流水线阶段2: 状态转换和数据准备
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            current_state_stage2 <= IDLE;
            timer_stage2 <= 4'd0;
            valid_stage2 <= 1'b0;
            addr_stage2 <= {ADDR_WIDTH{1'b0}};
        end else begin
            current_state_stage2 <= current_state_stage1;
            timer_stage2 <= timer_stage1;
            valid_stage2 <= valid_stage1;
            addr_stage2 <= addr_stage1;
        end
    end
    
    // 流水线阶段3: 数据输出和状态完成
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            current_state_stage3 <= IDLE;
            valid_stage3 <= 1'b0;
            data_out <= {DATA_WIDTH{1'b0}};
            ready <= 1'b1;
        end else begin
            current_state_stage3 <= current_state_stage2;
            valid_stage3 <= valid_stage2;
            
            // 数据输出逻辑
            if(valid_stage2 && current_state_stage2 == READ) begin
                data_out <= {DATA_WIDTH{1'b1}}; // 示例数据
            end
            
            // 就绪信号逻辑
            ready <= is_idle_stage3;
        end
    end
endmodule