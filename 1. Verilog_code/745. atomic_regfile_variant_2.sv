//SystemVerilog
module atomic_regfile_pipeline #(
    parameter DW = 64,
    parameter AW = 3
)(
    input clk,
    input start,
    input [AW-1:0] addr,
    input [DW-1:0] modify_mask,
    input [DW-1:0] modify_val,
    output [DW-1:0] original_val,
    output busy
);
    // 内存和状态寄存器
    reg [DW-1:0] mem [0:(1<<AW)-1];  // 使用参数化大小
    reg [1:0] state_stage1, state_stage2; // 两级状态寄存器
    reg [DW-1:0] temp_stage1, temp_stage2; // 两级临时寄存器
    reg [AW-1:0] addr_reg_stage1, addr_reg_stage2; // 两级地址寄存器

    // 使用参数化的比较逻辑而非硬编码值
    localparam IDLE = 2'b00;
    localparam READ = 2'b01;
    localparam WRITE = 2'b10;

    // 简化的busy信号逻辑
    assign busy = (state_stage1 != IDLE || state_stage2 != IDLE);
    
    // 直接输出临时寄存器
    assign original_val = temp_stage2;

    always @(posedge clk) begin
        // Stage 1
        case(state_stage1)
            IDLE: begin
                if (start) begin
                    temp_stage1 <= mem[addr];
                    addr_reg_stage1 <= addr;  // 存储地址以防止在多周期操作期间发生变化
                    state_stage1 <= READ;
                end
            end
            
            READ: begin
                state_stage1 <= WRITE;
            end
            
            WRITE: begin
                state_stage1 <= IDLE;
            end
            
            default: begin
                state_stage1 <= IDLE;  // 安全机制
            end
        endcase

        // Stage 2
        case(state_stage2)
            IDLE: begin
                if (state_stage1 == READ) begin
                    temp_stage2 <= (temp_stage1 & ~modify_mask) | (modify_val & modify_mask);
                    addr_reg_stage2 <= addr_reg_stage1; // 传递地址
                    state_stage2 <= WRITE;
                end
            end
            
            WRITE: begin
                mem[addr_reg_stage2] <= temp_stage2; // 写回内存
                state_stage2 <= IDLE;
            end
            
            default: begin
                state_stage2 <= IDLE;  // 安全机制
            end
        endcase
    end
endmodule