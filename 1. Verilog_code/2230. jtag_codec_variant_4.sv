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
    
    // Buffer registers for next_state to reduce fanout
    reg [3:0] next_state_buf1;
    reg [3:0] next_state_buf2;
    
    // State transition logic with buffered next_state
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            current_state <= TEST_LOGIC_RESET;
            next_state_buf1 <= TEST_LOGIC_RESET;
            next_state_buf2 <= TEST_LOGIC_RESET;
        end else begin
            current_state <= next_state;
            next_state_buf1 <= next_state;
            next_state_buf2 <= next_state;
        end
    end
    
    // Next state determination based on TMS
    always @* begin
        case (current_state)
            TEST_LOGIC_RESET: begin
                if (tms) begin
                    next_state = TEST_LOGIC_RESET;
                end else begin
                    next_state = RUN_TEST_IDLE;
                end
            end
            
            RUN_TEST_IDLE: begin
                if (tms) begin
                    next_state = SELECT_DR_SCAN;
                end else begin
                    next_state = RUN_TEST_IDLE;
                end
            end
            
            SELECT_DR_SCAN: begin
                if (tms) begin
                    next_state = SELECT_IR_SCAN;
                end else begin
                    next_state = CAPTURE_DR;
                end
            end
            
            CAPTURE_DR: begin
                if (tms) begin
                    next_state = EXIT1_DR;
                end else begin
                    next_state = SHIFT_DR;
                end
            end
            
            SHIFT_DR: begin
                if (tms) begin
                    next_state = EXIT1_DR;
                end else begin
                    next_state = SHIFT_DR;
                end
            end
            
            EXIT1_DR: begin
                if (tms) begin
                    next_state = UPDATE_DR;
                end else begin
                    next_state = PAUSE_DR;
                end
            end
            
            PAUSE_DR: begin
                if (tms) begin
                    next_state = EXIT2_DR;
                end else begin
                    next_state = PAUSE_DR;
                end
            end
            
            EXIT2_DR: begin
                if (tms) begin
                    next_state = UPDATE_DR;
                end else begin
                    next_state = SHIFT_DR;
                end
            end
            
            UPDATE_DR: begin
                if (tms) begin
                    next_state = SELECT_DR_SCAN;
                end else begin
                    next_state = RUN_TEST_IDLE;
                end
            end
            
            SELECT_IR_SCAN: begin
                if (tms) begin
                    next_state = TEST_LOGIC_RESET;
                end else begin
                    next_state = CAPTURE_IR;
                end
            end
            
            CAPTURE_IR: begin
                if (tms) begin
                    next_state = EXIT1_IR;
                end else begin
                    next_state = SHIFT_IR;
                end
            end
            
            SHIFT_IR: begin
                if (tms) begin
                    next_state = EXIT1_IR;
                end else begin
                    next_state = SHIFT_IR;
                end
            end
            
            EXIT1_IR: begin
                if (tms) begin
                    next_state = UPDATE_IR;
                end else begin
                    next_state = PAUSE_IR;
                end
            end
            
            PAUSE_IR: begin
                if (tms) begin
                    next_state = EXIT2_IR;
                end else begin
                    next_state = PAUSE_IR;
                end
            end
            
            EXIT2_IR: begin
                if (tms) begin
                    next_state = UPDATE_IR;
                end else begin
                    next_state = SHIFT_IR;
                end
            end
            
            UPDATE_IR: begin
                if (tms) begin
                    next_state = SELECT_DR_SCAN;
                end else begin
                    next_state = RUN_TEST_IDLE;
                end
            end
            
            default: begin
                next_state = TEST_LOGIC_RESET;
            end
        endcase
    end
    
    // Output signal generation based on buffered state to reduce load
    always @* begin
        // Default values
        capture_dr = 1'b0;
        shift_dr = 1'b0;
        update_dr = 1'b0;
        capture_ir = 1'b0;
        shift_ir = 1'b0;
        update_ir = 1'b0;
        tdo = 1'b0;
        tdo_oe = 1'b0;
        
        if (next_state_buf1 == CAPTURE_DR) begin
            capture_dr = 1'b1;
        end else if (next_state_buf1 == SHIFT_DR) begin
            shift_dr = 1'b1;
            tdo_oe = 1'b1;
        end else if (next_state_buf1 == UPDATE_DR) begin
            update_dr = 1'b1;
        end else if (next_state_buf1 == CAPTURE_IR) begin
            capture_ir = 1'b1;
        end else if (next_state_buf1 == SHIFT_IR) begin
            shift_ir = 1'b1;
            tdo_oe = 1'b1;
        end else if (next_state_buf1 == UPDATE_IR) begin
            update_ir = 1'b1;
        end
    end
    
endmodule