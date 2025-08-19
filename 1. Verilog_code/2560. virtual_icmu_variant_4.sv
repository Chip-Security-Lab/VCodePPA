//SystemVerilog
module virtual_icmu #(
    parameter GUESTS = 2,
    parameter INTS_PER_GUEST = 8
)(
    input clk, rst_n,
    input [INTS_PER_GUEST*GUESTS-1:0] phys_int,
    input [1:0] active_guest,
    input guest_switch_req,
    output reg [2:0] guest_int_id [0:GUESTS-1],
    output reg [GUESTS-1:0] int_pending_guest,
    output reg guest_switch_done
);

    reg [INTS_PER_GUEST-1:0] virt_int_pending [0:GUESTS-1];
    reg [INTS_PER_GUEST-1:0] virt_int_mask [0:GUESTS-1];
    reg [2:0] current_state;
    reg [2:0] current_state_buf;
    reg [GUESTS-1:0] int_pending_guest_buf;
    reg [INTS_PER_GUEST-1:0] virt_int_pending_buf [0:GUESTS-1];
    reg [INTS_PER_GUEST-1:0] virt_int_mask_buf [0:GUESTS-1];
    reg [2:0] guest_int_id_buf [0:GUESTS-1];
    
    // Buffer registers for high fanout signals
    reg [INTS_PER_GUEST-1:0] virt_int_pending_buf_stage1 [0:GUESTS-1];
    reg [INTS_PER_GUEST-1:0] virt_int_mask_buf_stage1 [0:GUESTS-1];
    reg [2:0] guest_int_id_buf_stage1 [0:GUESTS-1];
    reg [GUESTS-1:0] int_pending_guest_buf_stage1;
    
    integer g, i;
    
    localparam IDLE = 3'b000;
    localparam SAVE_CONTEXT = 3'b001;
    localparam SWITCH_PENDING = 3'b010;
    localparam RESTORE_CONTEXT = 3'b011;
    localparam SWITCH_DONE = 3'b100;

    // Reset logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (g = 0; g < GUESTS; g = g + 1) begin
                virt_int_pending[g] <= {INTS_PER_GUEST{1'b0}};
                virt_int_mask[g] <= {INTS_PER_GUEST{1'b1}};
                guest_int_id[g] <= 3'd0;
                virt_int_pending_buf[g] <= {INTS_PER_GUEST{1'b0}};
                virt_int_mask_buf[g] <= {INTS_PER_GUEST{1'b1}};
                guest_int_id_buf[g] <= 3'd0;
                virt_int_pending_buf_stage1[g] <= {INTS_PER_GUEST{1'b0}};
                virt_int_mask_buf_stage1[g] <= {INTS_PER_GUEST{1'b1}};
                guest_int_id_buf_stage1[g] <= 3'd0;
            end
            int_pending_guest <= {GUESTS{1'b0}};
            int_pending_guest_buf <= {GUESTS{1'b0}};
            int_pending_guest_buf_stage1 <= {GUESTS{1'b0}};
            guest_switch_done <= 1'b0;
            current_state <= IDLE;
            current_state_buf <= IDLE;
        end
    end

    // Physical interrupt processing with buffering
    always @(posedge clk) begin
        if (rst_n) begin
            for (g = 0; g < GUESTS; g = g + 1) begin
                virt_int_pending_buf_stage1[g] <= virt_int_pending[g] | 
                    phys_int[g*INTS_PER_GUEST +: INTS_PER_GUEST];
            end
        end
    end

    // Interrupt checking and encoding with buffering
    always @(posedge clk) begin
        if (rst_n) begin
            for (g = 0; g < GUESTS; g = g + 1) begin
                int_pending_guest_buf_stage1[g] <= |(virt_int_pending_buf_stage1[g] & ~virt_int_mask[g]);
                if (|(virt_int_pending_buf_stage1[g] & ~virt_int_mask[g])) begin
                    guest_int_id_buf_stage1[g] <= priority_encode(
                        virt_int_pending_buf_stage1[g] & ~virt_int_mask[g]);
                end
            end
        end
    end

    // Output updates with buffering
    always @(posedge clk) begin
        if (rst_n) begin
            for (g = 0; g < GUESTS; g = g + 1) begin
                virt_int_pending_buf[g] <= virt_int_pending_buf_stage1[g];
                guest_int_id_buf[g] <= guest_int_id_buf_stage1[g];
            end
            int_pending_guest_buf <= int_pending_guest_buf_stage1;
        end
    end

    // Final output stage
    always @(posedge clk) begin
        if (rst_n) begin
            for (g = 0; g < GUESTS; g = g + 1) begin
                virt_int_pending[g] <= virt_int_pending_buf[g];
                guest_int_id[g] <= guest_int_id_buf[g];
            end
            int_pending_guest <= int_pending_guest_buf;
        end
    end

    // State machine
    always @(posedge clk) begin
        if (rst_n) begin
            current_state_buf <= current_state;
            case (current_state_buf)
                IDLE: begin
                    guest_switch_done <= 1'b0;
                    if (guest_switch_req)
                        current_state <= SAVE_CONTEXT;
                end
                
                SAVE_CONTEXT: begin
                    current_state <= SWITCH_PENDING;
                end
                
                SWITCH_PENDING: begin
                    current_state <= RESTORE_CONTEXT;
                end
                
                RESTORE_CONTEXT: begin
                    current_state <= SWITCH_DONE;
                end
                
                SWITCH_DONE: begin
                    guest_switch_done <= 1'b1;
                    current_state <= IDLE;
                end
                
                default: current_state <= IDLE;
            endcase
        end
    end
    
    function [2:0] priority_encode;
        input [INTS_PER_GUEST-1:0] pending;
        reg [2:0] result;
        integer j;
        begin
            result = 3'd0;
            for (j = INTS_PER_GUEST-1; j >= 0; j=j-1)
                if (pending[j]) result = j[2:0];
            priority_encode = result;
        end
    endfunction

endmodule