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
               
    reg [3:0] current_state;
    reg [3:0] next_state;
    
    // 寄存化输入信号
    reg tms_reg;
    
    // 重定时：提前计算下一状态的输出信号值
    reg capture_dr_pre, shift_dr_pre, update_dr_pre;
    reg capture_ir_pre, shift_ir_pre, update_ir_pre;
    reg tdo_oe_pre;
    
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            tms_reg <= 1'b0;
            current_state <= TEST_LOGIC_RESET;
        end else begin
            tms_reg <= tms;
            current_state <= next_state;
        end
    end
    
    // 组合逻辑计算下一状态
    always @* begin
        case (current_state)
            TEST_LOGIC_RESET: next_state = tms_reg ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
            RUN_TEST_IDLE: next_state = tms_reg ? SELECT_DR_SCAN : RUN_TEST_IDLE;
            SELECT_DR_SCAN: next_state = tms_reg ? SELECT_IR_SCAN : CAPTURE_DR;
            CAPTURE_DR: next_state = tms_reg ? EXIT1_DR : SHIFT_DR;
            SHIFT_DR: next_state = tms_reg ? EXIT1_DR : SHIFT_DR;
            EXIT1_DR: next_state = tms_reg ? UPDATE_DR : PAUSE_DR;
            PAUSE_DR: next_state = tms_reg ? EXIT2_DR : PAUSE_DR;
            EXIT2_DR: next_state = tms_reg ? UPDATE_DR : SHIFT_DR;
            UPDATE_DR: next_state = tms_reg ? SELECT_DR_SCAN : RUN_TEST_IDLE;
            SELECT_IR_SCAN: next_state = tms_reg ? TEST_LOGIC_RESET : CAPTURE_IR;
            CAPTURE_IR: next_state = tms_reg ? EXIT1_IR : SHIFT_IR;
            SHIFT_IR: next_state = tms_reg ? EXIT1_IR : SHIFT_IR;
            EXIT1_IR: next_state = tms_reg ? UPDATE_IR : PAUSE_IR;
            PAUSE_IR: next_state = tms_reg ? EXIT2_IR : PAUSE_IR;
            EXIT2_IR: next_state = tms_reg ? UPDATE_IR : SHIFT_IR;
            UPDATE_IR: next_state = tms_reg ? SELECT_DR_SCAN : RUN_TEST_IDLE;
            default: next_state = TEST_LOGIC_RESET;
        endcase
        
        // 后向重定时：将输出逻辑从时序块移到组合逻辑中预计算
        capture_dr_pre = (next_state == CAPTURE_DR);
        shift_dr_pre = (next_state == SHIFT_DR);
        update_dr_pre = (next_state == UPDATE_DR);
        capture_ir_pre = (next_state == CAPTURE_IR);
        shift_ir_pre = (next_state == SHIFT_IR);
        update_ir_pre = (next_state == UPDATE_IR);
        tdo_oe_pre = (next_state == SHIFT_DR) || (next_state == SHIFT_IR);
    end
    
    // 将输出寄存器向后拉移，直接寄存预计算的控制信号
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            capture_dr <= 1'b0;
            shift_dr <= 1'b0;
            update_dr <= 1'b0;
            capture_ir <= 1'b0;
            shift_ir <= 1'b0;
            update_ir <= 1'b0;
            tdo_oe <= 1'b0;
            tdo <= 1'b0;
        end else begin
            capture_dr <= capture_dr_pre;
            shift_dr <= shift_dr_pre;
            update_dr <= update_dr_pre;
            capture_ir <= capture_ir_pre;
            shift_ir <= shift_ir_pre;
            update_ir <= update_ir_pre;
            tdo_oe <= tdo_oe_pre;
            // TDO logic would be implemented here based on the shifted data
        end
    end
endmodule