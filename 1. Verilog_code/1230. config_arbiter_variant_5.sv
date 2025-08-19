//SystemVerilog
module config_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    input [1:0] mode,  // 00-Fixed 01-RR 10-Prio 11-Random
    input [WIDTH-1:0] cfg_reg,
    output reg [WIDTH-1:0] grant_o
);

reg [$clog2(WIDTH)-1:0] ptr, ptr_next;
reg [WIDTH-1:0] mask, mask_next;
reg [WIDTH-1:0] req_reg;
reg [1:0] mode_reg;
reg [WIDTH-1:0] cfg_reg_reg;
reg [WIDTH-1:0] grant_pipe;
reg [WIDTH-1:0] fixed_grant, rr_grant, prio_grant, random_grant;
reg [WIDTH-1:0] req_masked [0:WIDTH-1]; // 预计算的掩码请求
reg [WIDTH-1:0] fixed_pre;  // 固定优先级预计算寄存器
integer i;

// 输入寄存器阶段 - 减少输入路径延迟
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        req_reg <= 0;
        mode_reg <= 0;
        cfg_reg_reg <= 0;
        fixed_pre <= 0;
    end else begin
        req_reg <= req_i;
        mode_reg <= mode;
        cfg_reg_reg <= cfg_reg;
        fixed_pre <= req_i & (~req_i + 1); // 提前一个周期计算固定优先级
    end
end

// 固定优先级模式 - 使用预计算结果减少关键路径
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fixed_grant <= 0;
    end else begin
        fixed_grant <= fixed_pre; // 直接使用预计算结果
    end
end

// 轮询模式逻辑 - 并行计算减少组合路径
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ptr <= 0;
        ptr_next <= 0;
        rr_grant <= 0;
        for (i = 0; i < WIDTH; i = i + 1)
            req_masked[i] <= 0;
    end else begin
        ptr <= ptr_next;
        
        // 预计算所有可能的掩码请求 - 平行化计算
        for (i = 0; i < WIDTH; i = i + 1)
            req_masked[i] <= req_reg & (1 << ((ptr+i)%WIDTH));
            
        // 轮询逻辑优化 - 减少条件判断链
        if (mode_reg == 2'b01) begin
            rr_grant <= 0;
            ptr_next <= ptr;
            
            // 优先级编码逻辑拆分 - 降低组合逻辑深度
            for (i = 0; i < WIDTH; i = i + 1) begin
                if (req_masked[i] != 0 && rr_grant == 0) begin
                    rr_grant <= req_masked[i];
                    ptr_next <= (ptr + i + 1) % WIDTH;
                end
            end
        end else begin
            rr_grant <= 0;
        end
    end
end

// 优先级模式结果 - 并行处理
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        prio_grant <= 0;
    end else begin
        prio_grant <= cfg_reg_reg & req_reg;
        
        // 确保至少有一位被选中
        if ((cfg_reg_reg & req_reg) == 0 && req_reg != 0)
            prio_grant <= req_reg & (~req_reg + 1); // 降级到固定优先级
    end
end

// 随机模式逻辑 - 减少复杂度
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mask <= {{(WIDTH-1){1'b0}}, 1'b1};
        mask_next <= {{(WIDTH-1){1'b0}}, 1'b1};
        random_grant <= 0;
    end else begin
        mask <= mask_next;
        mask_next <= {mask_next[WIDTH-2:0], mask_next[WIDTH-1]};
        
        // 确保随机模式下至少有一个授权
        if ((req_reg & mask_next) != 0) begin
            random_grant <= req_reg & mask_next;
        end else begin
            random_grant <= req_reg & (~req_reg + 1); // 降级到固定优先级
        end
    end
end

// 输出多路复用 - 减少选择器延迟
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        grant_pipe <= 0;
        grant_o <= 0;
    end else begin
        // 使用简化的case语句减少关键路径
        case(mode_reg)
            2'b00: grant_pipe <= fixed_grant;
            2'b01: grant_pipe <= rr_grant;
            2'b10: grant_pipe <= prio_grant;
            2'b11: grant_pipe <= random_grant;
        endcase
        
        // 确保至少有一个授权
        if (grant_pipe == 0 && req_reg != 0)
            grant_o <= req_reg & (~req_reg + 1); // 默认到最低位授权
        else
            grant_o <= grant_pipe;
    end
end

endmodule