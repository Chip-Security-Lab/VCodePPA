//SystemVerilog
// SystemVerilog
//-------------------------------------------------------------------------
//-------------------------------------------------------------------------
module jtag_codec (
    input wire tck, tms, tdi, trst_n,
    output reg tdo, tdo_oe,
    output reg capture_dr, shift_dr, update_dr,
    output reg capture_ir, shift_ir, update_ir
);
    // 内部连接信号
    wire [3:0] current_state;
    wire [3:0] next_state;
    
    // 实例化TAP状态控制器子模块
    jtag_tap_controller tap_ctrl (
        .tck(tck),
        .tms(tms),
        .trst_n(trst_n),
        .current_state(current_state),
        .next_state(next_state)
    );
    
    // 实例化TAP输出生成器子模块
    jtag_output_generator output_gen (
        .current_state(current_state),
        .capture_dr(capture_dr),
        .shift_dr(shift_dr),
        .update_dr(update_dr),
        .capture_ir(capture_ir),
        .shift_ir(shift_ir),
        .update_ir(update_ir),
        .tdo(tdo),
        .tdo_oe(tdo_oe)
    );
    
endmodule

//-------------------------------------------------------------------------
// TAP控制器状态机子模块
//-------------------------------------------------------------------------
module jtag_tap_controller (
    input wire tck, tms, trst_n,
    output reg [3:0] current_state,
    output reg [3:0] next_state
);
    // TAP控制器状态定义
    localparam TEST_LOGIC_RESET = 4'h0, RUN_TEST_IDLE = 4'h1,
               SELECT_DR_SCAN = 4'h2, CAPTURE_DR = 4'h3,
               SHIFT_DR = 4'h4, EXIT1_DR = 4'h5,
               PAUSE_DR = 4'h6, EXIT2_DR = 4'h7,
               UPDATE_DR = 4'h8, SELECT_IR_SCAN = 4'h9,
               CAPTURE_IR = 4'hA, SHIFT_IR = 4'hB,
               EXIT1_IR = 4'hC, PAUSE_IR = 4'hD,
               EXIT2_IR = 4'hE, UPDATE_IR = 4'hF;
    
    // 状态转换逻辑 - 使用非阻塞赋值以避免竞争条件
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) 
            current_state <= TEST_LOGIC_RESET;
        else 
            current_state <= next_state;
    end
    
    // 预计算状态转换路径 - 减少组合逻辑深度
    wire goto_run_test_idle = (current_state == TEST_LOGIC_RESET && !tms) || 
                              (current_state == UPDATE_DR && !tms) || 
                              (current_state == UPDATE_IR && !tms);
                              
    wire goto_test_logic_reset = (current_state == TEST_LOGIC_RESET && tms) || 
                                 (current_state == SELECT_IR_SCAN && tms);
                                 
    wire goto_select_dr_scan = (current_state == RUN_TEST_IDLE && tms) ||
                               (current_state == UPDATE_DR && tms) ||
                               (current_state == UPDATE_IR && tms);
    
    // 优化的下一状态计算 - 减少关键路径
    always @* begin
        // 使用预计算的路径结果
        if (goto_run_test_idle)
            next_state = RUN_TEST_IDLE;
        else if (goto_test_logic_reset)
            next_state = TEST_LOGIC_RESET;
        else if (goto_select_dr_scan)
            next_state = SELECT_DR_SCAN;
        else begin
            // 剩余状态转换使用简化结构
            case (current_state)
                SELECT_DR_SCAN: next_state = tms ? SELECT_IR_SCAN : CAPTURE_DR;
                CAPTURE_DR:     next_state = tms ? EXIT1_DR : SHIFT_DR;
                SHIFT_DR:       next_state = tms ? EXIT1_DR : SHIFT_DR;
                EXIT1_DR:       next_state = tms ? UPDATE_DR : PAUSE_DR;
                PAUSE_DR:       next_state = tms ? EXIT2_DR : PAUSE_DR;
                EXIT2_DR:       next_state = tms ? UPDATE_DR : SHIFT_DR;
                SELECT_IR_SCAN: next_state = tms ? TEST_LOGIC_RESET : CAPTURE_IR;
                CAPTURE_IR:     next_state = tms ? EXIT1_IR : SHIFT_IR;
                SHIFT_IR:       next_state = tms ? EXIT1_IR : SHIFT_IR;
                EXIT1_IR:       next_state = tms ? UPDATE_IR : PAUSE_IR;
                PAUSE_IR:       next_state = tms ? EXIT2_IR : PAUSE_IR;
                EXIT2_IR:       next_state = tms ? UPDATE_IR : SHIFT_IR;
                default:        next_state = TEST_LOGIC_RESET;
            endcase
        end
    end
    
endmodule

//-------------------------------------------------------------------------
// TAP输出生成器子模块
//-------------------------------------------------------------------------
module jtag_output_generator (
    input wire [3:0] current_state,
    output reg capture_dr, shift_dr, update_dr,
    output reg capture_ir, shift_ir, update_ir,
    output reg tdo, tdo_oe
);
    // TAP控制器状态定义 (复制以保持一致性)
    localparam TEST_LOGIC_RESET = 4'h0, RUN_TEST_IDLE = 4'h1,
               SELECT_DR_SCAN = 4'h2, CAPTURE_DR = 4'h3,
               SHIFT_DR = 4'h4, EXIT1_DR = 4'h5,
               PAUSE_DR = 4'h6, EXIT2_DR = 4'h7,
               UPDATE_DR = 4'h8, SELECT_IR_SCAN = 4'h9,
               CAPTURE_IR = 4'hA, SHIFT_IR = 4'hB,
               EXIT1_IR = 4'hC, PAUSE_IR = 4'hD,
               EXIT2_IR = 4'hE, UPDATE_IR = 4'hF;
    
    // 并行计算所有输出信号，减少逻辑深度
    always @* begin
        // 使用并行比较结构，减少关键路径长度
        capture_dr = (current_state == CAPTURE_DR);
        shift_dr = (current_state == SHIFT_DR);
        update_dr = (current_state == UPDATE_DR);
        capture_ir = (current_state == CAPTURE_IR);
        shift_ir = (current_state == SHIFT_IR);
        update_ir = (current_state == UPDATE_IR);
        
        // 优化tdo_oe逻辑
        tdo_oe = (current_state == SHIFT_DR) || (current_state == SHIFT_IR);
        
        // tdo保持默认值
        tdo = 1'b0;
    end
    
endmodule