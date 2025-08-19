//SystemVerilog
//------------------------------------------------------------------------------
// 顶层模块：动态优先级中断控制器
//------------------------------------------------------------------------------
module int_ctrl_dyn_prio #(
    parameter N = 4
)(
    input wire clk,
    input wire [N-1:0] int_req,
    input wire [N-1:0] prio_reg,
    output wire [N-1:0] grant
);

    // 优化：直接在顶层处理掩码和授权逻辑，减少模块间信号传递开销
    wire [N-1:0] priority_masked_requests;
    
    // 优化后的掩码处理 - 合并到顶层
    assign priority_masked_requests = int_req & prio_reg;
    
    // 优化后的授权生成 - 一次性处理
    assign grant = priority_masked_requests & (~(priority_masked_requests - 1) & priority_masked_requests);

endmodule

//------------------------------------------------------------------------------
// 子模块：优先级掩码处理器 (保留但不使用，可移除)
//------------------------------------------------------------------------------
module priority_mask #(
    parameter N = 4
)(
    input wire [N-1:0] int_req,
    input wire [N-1:0] prio_reg,
    output wire [N-1:0] masked_req
);
    
    // 简化掩码操作
    assign masked_req = int_req & prio_reg;
    
endmodule

//------------------------------------------------------------------------------
// 子模块：授权信号生成器 (保留但不使用，可移除)
//------------------------------------------------------------------------------
module grant_generator #(
    parameter N = 4
)(
    input wire [N-1:0] masked_req,
    output wire [N-1:0] grant
);
    
    // 优化：使用位操作提取最高优先级，避免使用循环
    // 该表达式使用减1和与操作提取最低位的1
    assign grant = masked_req & (~(masked_req - 1) & masked_req);
    
endmodule