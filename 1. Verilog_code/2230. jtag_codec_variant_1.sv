//SystemVerilog
module jtag_codec (
    input wire tck, tms, tdi, trst_n,
    output reg tdo, tdo_oe,
    output reg capture_dr, shift_dr, update_dr,
    output reg capture_ir, shift_ir, update_ir
);
    // TAP controller states
    localparam TEST_LOGIC_RESET = 4'h0, RUN_TEST_IDLE = 4'h1,
               SELECT_DR_SCAN = 4'h2, CAPTURE_DR = 4'h3,
               SHIFT_DR = 4'h4, EXIT1_DR = 4'h5,
               PAUSE_DR = 4'h6, EXIT2_DR = 4'h7,
               UPDATE_DR = 4'h8, SELECT_IR_SCAN = 4'h9,
               CAPTURE_IR = 4'hA, SHIFT_IR = 4'hB,
               EXIT1_IR = 4'hC, PAUSE_IR = 4'hD,
               EXIT2_IR = 4'hE, UPDATE_IR = 4'hF;
               
    reg [3:0] current_state, next_state;
    
    // 创建TMS信号的缓冲器，减少扇出负载
    reg tms_buf1, tms_buf2, tms_buf3;
    
    // 为高扇出状态创建多个缓冲寄存器，分散负载
    reg [3:0] next_state_buf1, next_state_buf2, next_state_buf3;
    reg test_logic_reset_signal1, test_logic_reset_signal2;
    reg run_test_idle_signal1, run_test_idle_signal2;
    reg select_dr_scan_signal1, select_dr_scan_signal2;
    reg shift_dr_signal1, shift_dr_signal2;
    
    // 缓冲TMS信号
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            tms_buf1 <= 1'b0;
            tms_buf2 <= 1'b0;
            tms_buf3 <= 1'b0;
        end else begin
            tms_buf1 <= tms;
            tms_buf2 <= tms;
            tms_buf3 <= tms;
        end
    end
    
    // 状态转换逻辑
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            current_state <= TEST_LOGIC_RESET;
            next_state_buf1 <= TEST_LOGIC_RESET;
            next_state_buf2 <= TEST_LOGIC_RESET;
            next_state_buf3 <= TEST_LOGIC_RESET;
        end else begin
            current_state <= next_state;
            next_state_buf1 <= next_state;
            next_state_buf2 <= next_state;
            next_state_buf3 <= next_state;
        end
    end
    
    // 高扇出状态信号的缓冲
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            test_logic_reset_signal1 <= 1'b1;
            test_logic_reset_signal2 <= 1'b1;
            run_test_idle_signal1 <= 1'b0;
            run_test_idle_signal2 <= 1'b0;
            select_dr_scan_signal1 <= 1'b0;
            select_dr_scan_signal2 <= 1'b0;
            shift_dr_signal1 <= 1'b0;
            shift_dr_signal2 <= 1'b0;
        end else begin
            test_logic_reset_signal1 <= (current_state == TEST_LOGIC_RESET);
            test_logic_reset_signal2 <= (current_state == TEST_LOGIC_RESET);
            run_test_idle_signal1 <= (current_state == RUN_TEST_IDLE);
            run_test_idle_signal2 <= (current_state == RUN_TEST_IDLE);
            select_dr_scan_signal1 <= (current_state == SELECT_DR_SCAN);
            select_dr_scan_signal2 <= (current_state == SELECT_DR_SCAN);
            shift_dr_signal1 <= (current_state == SHIFT_DR);
            shift_dr_signal2 <= (current_state == SHIFT_DR);
        end
    end
    
    // 基于TMS的下一状态确定
    // 使用缓冲的TMS信号减少扇出负载
    always @* begin
        case (current_state)
            TEST_LOGIC_RESET: next_state = tms_buf1 ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
            RUN_TEST_IDLE: next_state = tms_buf1 ? SELECT_DR_SCAN : RUN_TEST_IDLE;
            SELECT_DR_SCAN: next_state = tms_buf1 ? SELECT_IR_SCAN : CAPTURE_DR;
            CAPTURE_DR: next_state = tms_buf2 ? EXIT1_DR : SHIFT_DR;
            SHIFT_DR: next_state = tms_buf2 ? EXIT1_DR : SHIFT_DR;
            EXIT1_DR: next_state = tms_buf2 ? UPDATE_DR : PAUSE_DR;
            PAUSE_DR: next_state = tms_buf2 ? EXIT2_DR : PAUSE_DR;
            EXIT2_DR: next_state = tms_buf2 ? UPDATE_DR : SHIFT_DR;
            UPDATE_DR: next_state = tms_buf3 ? SELECT_DR_SCAN : RUN_TEST_IDLE;
            SELECT_IR_SCAN: next_state = tms_buf3 ? TEST_LOGIC_RESET : CAPTURE_IR;
            CAPTURE_IR: next_state = tms_buf3 ? EXIT1_IR : SHIFT_IR;
            SHIFT_IR: next_state = tms_buf3 ? EXIT1_IR : SHIFT_IR;
            EXIT1_IR: next_state = tms_buf3 ? UPDATE_IR : PAUSE_IR;
            PAUSE_IR: next_state = tms_buf3 ? EXIT2_IR : PAUSE_IR;
            EXIT2_IR: next_state = tms_buf3 ? UPDATE_IR : SHIFT_IR;
            UPDATE_IR: next_state = tms_buf3 ? SELECT_DR_SCAN : RUN_TEST_IDLE;
            default: next_state = TEST_LOGIC_RESET;
        endcase
    end
    
    // 基于状态生成的输出信号
    // 使用不同的缓冲信号为不同的输出组平衡负载
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            {capture_dr, shift_dr, update_dr} <= 3'b000;
            {capture_ir, shift_ir, update_ir} <= 3'b000;
            {tdo, tdo_oe} <= 2'b00;
        end else begin
            // DR控制信号 - 使用next_state_buf1
            capture_dr <= (next_state_buf1 == CAPTURE_DR);
            shift_dr <= shift_dr_signal1;  // 使用缓冲的shift_dr信号
            update_dr <= (next_state_buf1 == UPDATE_DR);
            
            // IR控制信号 - 使用next_state_buf2
            capture_ir <= (next_state_buf2 == CAPTURE_IR);
            shift_ir <= (next_state_buf2 == SHIFT_IR);
            update_ir <= (next_state_buf2 == UPDATE_IR);
            
            // TDO输出信号 - 使用next_state_buf3和缓冲的状态信号
            tdo <= (shift_dr_signal2 || (next_state_buf3 == SHIFT_IR)) ? tdi : 1'b0;
            tdo_oe <= (shift_dr_signal2 || (next_state_buf3 == SHIFT_IR));
        end
    end
endmodule