//SystemVerilog
module jtag_codec (
    input wire tck, tms, tdi, trst_n,
    output reg tdo, tdo_oe,
    output reg capture_dr, shift_dr, update_dr,
    output reg capture_ir, shift_ir, update_ir
);
    // TAP controller states - one-hot encoding
    localparam TEST_LOGIC_RESET = 16'b0000000000000001,
               RUN_TEST_IDLE    = 16'b0000000000000010,
               SELECT_DR_SCAN   = 16'b0000000000000100,
               CAPTURE_DR       = 16'b0000000000001000,
               SHIFT_DR         = 16'b0000000000010000,
               EXIT1_DR         = 16'b0000000000100000,
               PAUSE_DR         = 16'b0000000001000000,
               EXIT2_DR         = 16'b0000000010000000,
               UPDATE_DR        = 16'b0000000100000000,
               SELECT_IR_SCAN   = 16'b0000001000000000,
               CAPTURE_IR       = 16'b0000010000000000,
               SHIFT_IR         = 16'b0000100000000000,
               EXIT1_IR         = 16'b0001000000000000,
               PAUSE_IR         = 16'b0010000000000000,
               EXIT2_IR         = 16'b0100000000000000,
               UPDATE_IR        = 16'b1000000000000000;
               
    reg [15:0] current_state;
    reg [15:0] next_state_logic;
    reg tms_ff;
    
    // Registering input TMS signal to improve timing
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n)
            tms_ff <= 1'b0;
        else
            tms_ff <= tms;
    end
    
    // Next state determination based on registered TMS
    always @* begin
        case (current_state)
            TEST_LOGIC_RESET: next_state_logic = tms_ff ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
            RUN_TEST_IDLE:    next_state_logic = tms_ff ? SELECT_DR_SCAN  : RUN_TEST_IDLE;
            SELECT_DR_SCAN:   next_state_logic = tms_ff ? SELECT_IR_SCAN  : CAPTURE_DR;
            CAPTURE_DR:       next_state_logic = tms_ff ? EXIT1_DR        : SHIFT_DR;
            SHIFT_DR:         next_state_logic = tms_ff ? EXIT1_DR        : SHIFT_DR;
            EXIT1_DR:         next_state_logic = tms_ff ? UPDATE_DR       : PAUSE_DR;
            PAUSE_DR:         next_state_logic = tms_ff ? EXIT2_DR        : PAUSE_DR;
            EXIT2_DR:         next_state_logic = tms_ff ? UPDATE_DR       : SHIFT_DR;
            UPDATE_DR:        next_state_logic = tms_ff ? SELECT_DR_SCAN  : RUN_TEST_IDLE;
            SELECT_IR_SCAN:   next_state_logic = tms_ff ? TEST_LOGIC_RESET : CAPTURE_IR;
            CAPTURE_IR:       next_state_logic = tms_ff ? EXIT1_IR        : SHIFT_IR;
            SHIFT_IR:         next_state_logic = tms_ff ? EXIT1_IR        : SHIFT_IR;
            EXIT1_IR:         next_state_logic = tms_ff ? UPDATE_IR       : PAUSE_IR;
            PAUSE_IR:         next_state_logic = tms_ff ? EXIT2_IR        : PAUSE_IR;
            EXIT2_IR:         next_state_logic = tms_ff ? UPDATE_IR       : SHIFT_IR;
            UPDATE_IR:        next_state_logic = tms_ff ? SELECT_DR_SCAN  : RUN_TEST_IDLE;
            default:          next_state_logic = TEST_LOGIC_RESET;
        endcase
    end
    
    // State transition logic
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) 
            current_state <= TEST_LOGIC_RESET;
        else 
            current_state <= next_state_logic;
    end
    
    // Output signal generation - registering all outputs for better timing
    reg [5:0] control_signals;
    reg tdo_oe_internal;
    
    always @* begin
        // Default values packed in a vector for more efficient processing
        control_signals = 6'b000000; // {capture_dr, shift_dr, update_dr, capture_ir, shift_ir, update_ir}
        tdo_oe_internal = 1'b0;
        
        // Set outputs based on state
        case (current_state)
            CAPTURE_DR: control_signals[5] = 1'b1; // capture_dr
            SHIFT_DR:   begin 
                control_signals[4] = 1'b1; // shift_dr
                tdo_oe_internal = 1'b1; 
            end
            UPDATE_DR:  control_signals[3] = 1'b1; // update_dr
            CAPTURE_IR: control_signals[2] = 1'b1; // capture_ir
            SHIFT_IR:   begin 
                control_signals[1] = 1'b1; // shift_ir
                tdo_oe_internal = 1'b1; 
            end
            UPDATE_IR:  control_signals[0] = 1'b1; // update_ir
        endcase
    end
    
    // Registering all output signals to improve timing
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            capture_dr <= 1'b0;
            shift_dr   <= 1'b0;
            update_dr  <= 1'b0;
            capture_ir <= 1'b0;
            shift_ir   <= 1'b0;
            update_ir  <= 1'b0;
            tdo_oe     <= 1'b0;
            tdo        <= 1'b0;
        end else begin
            capture_dr <= control_signals[5];
            shift_dr   <= control_signals[4];
            update_dr  <= control_signals[3];
            capture_ir <= control_signals[2];
            shift_ir   <= control_signals[1];
            update_ir  <= control_signals[0];
            tdo_oe     <= tdo_oe_internal;
            // tdo would be assigned here based on actual data
        end
    end
    
endmodule