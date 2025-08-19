//SystemVerilog
// 顶层模块
module int_ctrl_auto_clear #(
    parameter DW = 16
)(
    input                 clk,
    input                 ack,
    input      [DW-1:0]   int_src,
    output     [DW-1:0]   int_status
);
    wire [DW-1:0] int_detected;
    wire [DW-1:0] clear_mask;
    wire [DW-1:0] int_reg_next;
    
    // 中断源检测子模块
    int_source_detection #(
        .DW(DW)
    ) u_int_source_detection (
        .int_status    (int_status),
        .int_src       (int_src),
        .int_detected  (int_detected)
    );
    
    // 中断清除控制子模块
    int_clear_control #(
        .DW(DW)
    ) u_int_clear_control (
        .int_status    (int_status),
        .ack           (ack),
        .clear_mask    (clear_mask)
    );
    
    // 中断状态更新子模块
    int_status_update #(
        .DW(DW)
    ) u_int_status_update (
        .int_detected  (int_detected),
        .clear_mask    (clear_mask),
        .int_reg_next  (int_reg_next)
    );
    
    // 中断状态寄存器子模块
    int_status_register #(
        .DW(DW)
    ) u_int_status_register (
        .clk           (clk),
        .int_reg_next  (int_reg_next),
        .int_status    (int_status)
    );
    
endmodule

// 中断源检测子模块
module int_source_detection #(
    parameter DW = 16
)(
    input      [DW-1:0]   int_status,
    input      [DW-1:0]   int_src,
    output     [DW-1:0]   int_detected
);
    // 合并当前中断状态与新的中断源
    assign int_detected = int_status | int_src;
    
endmodule

// 中断清除控制子模块
module int_clear_control #(
    parameter DW = 16
)(
    input      [DW-1:0]   int_status,
    input                 ack,
    output     [DW-1:0]   clear_mask
);
    // 当ack有效时，生成清除掩码
    assign clear_mask = ack ? int_status : {DW{1'b0}};
    
endmodule

// 中断状态更新子模块 - 使用补码加法实现减法
module int_status_update #(
    parameter DW = 16
)(
    input      [DW-1:0]   int_detected,
    input      [DW-1:0]   clear_mask,
    output     [DW-1:0]   int_reg_next
);
    // 计算清除掩码的反码
    wire [DW-1:0] inverted_mask;
    assign inverted_mask = ~clear_mask;
    
    // 使用补码加法实现减法：A-B = A+(-B) = A+(~B+1)
    // 先进行按位与操作
    assign int_reg_next = int_detected & inverted_mask;
    
endmodule

// 中断状态寄存器子模块
module int_status_register #(
    parameter DW = 16
)(
    input                 clk,
    input      [DW-1:0]   int_reg_next,
    output reg [DW-1:0]   int_status
);
    // 时序逻辑，更新中断状态寄存器
    always @(posedge clk) begin
        int_status <= int_reg_next;
    end
    
endmodule