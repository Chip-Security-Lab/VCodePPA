//SystemVerilog
//-----------------------------------------------------------------------------
// 顶层模块：时钟门控系统
//-----------------------------------------------------------------------------
module ClockGating #(
    parameter SYNC_STAGES = 2
)(
    input  wire clk,
    input  wire rst_n,
    input  wire enable,
    input  wire test_mode,
    output wire gated_clk
);
    // 内部连线
    wire clk_buf;
    wire rst_n_buf;
    wire test_mode_buf;
    wire enable_synced;
    wire enable_synced_buf;
    wire clock_gate_ctrl;
    wire clock_gate_ctrl_buf;
    wire enable_in_prebuf;
    wire test_mode_prebuf;

    // 将输入信号预处理寄存器前移
    reg enable_prebuf_reg;
    reg test_mode_prebuf_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_prebuf_reg <= 1'b0;
            test_mode_prebuf_reg <= 1'b0;
        end else begin
            enable_prebuf_reg <= enable;
            test_mode_prebuf_reg <= test_mode;
        end
    end
    
    assign enable_in_prebuf = enable_prebuf_reg;
    assign test_mode_prebuf = test_mode_prebuf_reg;

    // 时钟缓冲
    ClockBuffer u_clk_buf (
        .clk_in (clk),
        .clk_out(clk_buf)
    );

    // 复位缓冲
    ResetBuffer u_rst_buf (
        .rst_n_in (rst_n),
        .clk      (clk_buf),
        .rst_n_out(rst_n_buf)
    );

    // 测试模式缓冲 - 移除寄存器
    TestModeBuffer u_test_buf (
        .test_mode_in (test_mode_prebuf),
        .clk          (clk_buf),
        .rst_n        (rst_n_buf),
        .test_mode_out(test_mode_buf)
    );

    // 实例化同步器子模块
    EnableSynchronizer #(
        .SYNC_STAGES(SYNC_STAGES)
    ) u_enable_sync (
        .clk           (clk_buf),
        .rst_n         (rst_n_buf),
        .enable_in     (enable_in_prebuf),
        .enable_synced (enable_synced)
    );

    // 使能信号缓冲 - 优化控制路径
    EnableBuffer u_enable_buf (
        .enable_in (enable_synced),
        .clk       (clk_buf),
        .rst_n     (rst_n_buf),
        .enable_out(enable_synced_buf)
    );

    // 门控控制器
    GateController u_gate_ctrl (
        .clk            (clk_buf),
        .rst_n          (rst_n_buf),
        .enable_synced  (enable_synced_buf),
        .clock_gate_ctrl(clock_gate_ctrl)
    );

    // 门控控制信号缓冲 - 前移寄存器逻辑
    GateCtrlBuffer u_gate_buf (
        .gate_ctrl_in (clock_gate_ctrl),
        .clk          (clk_buf),
        .rst_n        (rst_n_buf),
        .gate_ctrl_out(clock_gate_ctrl_buf)
    );

    // 时钟输出多路复用器 - 移除输出寄存器，优化关键路径
    ClockOutputMux u_clk_mux (
        .clk            (clk_buf),
        .clock_gate_ctrl(clock_gate_ctrl_buf),
        .test_mode      (test_mode_buf),
        .gated_clk      (gated_clk)
    );

endmodule

//-----------------------------------------------------------------------------
// 缓冲器模块
//-----------------------------------------------------------------------------
module ClockBuffer (
    input  wire clk_in,
    output wire clk_out
);
    // 移除寄存器，减少时钟路径延迟
    assign clk_out = clk_in;
endmodule

module ResetBuffer (
    input  wire rst_n_in,
    input  wire clk,
    output wire rst_n_out
);
    reg rst_n_reg1, rst_n_reg2;
    
    // 分割重定时，减少关键路径
    always @(posedge clk or negedge rst_n_in) begin
        if (!rst_n_in) 
            rst_n_reg1 <= 1'b0;
        else 
            rst_n_reg1 <= 1'b1;
    end
    
    always @(posedge clk) begin
        rst_n_reg2 <= rst_n_reg1;
    end
    
    assign rst_n_out = rst_n_reg2;
endmodule

module TestModeBuffer (
    input  wire test_mode_in,
    input  wire clk,
    input  wire rst_n,
    output wire test_mode_out
);
    // 简化处理逻辑，直接连接输入
    assign test_mode_out = test_mode_in;
endmodule

module EnableBuffer (
    input  wire enable_in,
    input  wire clk,
    input  wire rst_n,
    output wire enable_out
);
    // 前后分离寄存器，优化路径延迟
    reg enable_stage1, enable_stage2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage1 <= 1'b0;
            enable_stage2 <= 1'b0;
        end else begin
            enable_stage1 <= enable_in;
            enable_stage2 <= enable_stage1;
        end
    end
    
    assign enable_out = enable_stage2;
endmodule

module GateCtrlBuffer (
    input  wire gate_ctrl_in,
    input  wire clk,
    input  wire rst_n,
    output wire gate_ctrl_out
);
    wire gate_ctrl_pre;
    
    // 前移寄存器到组合逻辑前
    assign gate_ctrl_pre = gate_ctrl_in;
    
    // 细分处理阶段
    reg gate_ctrl_reg1, gate_ctrl_reg2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gate_ctrl_reg1 <= 1'b0;
        end else begin
            gate_ctrl_reg1 <= gate_ctrl_pre;
        end
    end
    
    always @(posedge clk) begin
        gate_ctrl_reg2 <= gate_ctrl_reg1;
    end
    
    assign gate_ctrl_out = gate_ctrl_reg2;
endmodule

//-----------------------------------------------------------------------------
// 子模块：使能信号同步器
//-----------------------------------------------------------------------------
module EnableSynchronizer #(
    parameter SYNC_STAGES = 2
)(
    input  wire clk,
    input  wire rst_n,
    input  wire enable_in,
    output wire enable_synced
);
    // 为改善时序，保留同步逻辑，但采用流水线结构
    reg [SYNC_STAGES:0] enable_sync_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_sync_reg <= {(SYNC_STAGES+1){1'b0}};
        end else begin
            enable_sync_reg <= {enable_sync_reg[SYNC_STAGES-1:0], enable_in};
        end
    end

    assign enable_synced = enable_sync_reg[SYNC_STAGES];
endmodule

//-----------------------------------------------------------------------------
// 子模块：门控控制器
//-----------------------------------------------------------------------------
module GateController (
    input  wire clk,
    input  wire rst_n,
    input  wire enable_synced,
    output reg  clock_gate_ctrl
);
    // 优化控制路径，改用正边沿减少冲突
    reg enable_latched;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_latched <= 1'b0;
        end else begin
            enable_latched <= enable_synced;
        end
    end
    
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clock_gate_ctrl <= 1'b0;
        end else begin
            clock_gate_ctrl <= enable_latched;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// 子模块：时钟输出多路复用器
//-----------------------------------------------------------------------------
module ClockOutputMux (
    input  wire clk,
    input  wire clock_gate_ctrl,
    input  wire test_mode,
    output wire gated_clk
);
    // 将控制逻辑前移，减少输出端的组合逻辑
    wire clk_gate;
    
    assign clk_gate = clock_gate_ctrl;
    assign gated_clk = test_mode ? clk : (clk & clk_gate);
endmodule