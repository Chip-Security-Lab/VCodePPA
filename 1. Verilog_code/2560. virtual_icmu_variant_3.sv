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
    integer g, i;
    
    localparam IDLE = 3'b000;
    localparam SAVE_CONTEXT = 3'b001;
    localparam SWITCH_PENDING = 3'b011;
    localparam RESTORE_CONTEXT = 3'b111;
    localparam SWITCH_DONE = 3'b110;

    // Reset and initialization logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (g = 0; g < GUESTS; g = g + 1) begin
                virt_int_pending[g] <= {INTS_PER_GUEST{1'b0}};
                virt_int_mask[g] <= {INTS_PER_GUEST{1'b1}};
                guest_int_id[g] <= 3'd0;
            end
            int_pending_guest <= {GUESTS{1'b0}};
            guest_switch_done <= 1'b0;
            current_state <= IDLE;
        end
    end

    // Interrupt pending update logic
    always @(posedge clk) begin
        if (rst_n) begin
            for (g = 0; g < GUESTS; g = g + 1) begin
                virt_int_pending[g] <= virt_int_pending[g] | 
                    phys_int[g*INTS_PER_GUEST +: INTS_PER_GUEST];
            end
        end
    end

    // Interrupt pending status and ID update logic
    always @(posedge clk) begin
        if (rst_n) begin
            for (g = 0; g < GUESTS; g = g + 1) begin
                int_pending_guest[g] <= |(virt_int_pending[g] & ~virt_int_mask[g]);
                
                if (|(virt_int_pending[g] & ~virt_int_mask[g])) begin
                    guest_int_id[g] <= priority_encode(
                        virt_int_pending[g] & ~virt_int_mask[g]);
                end
            end
        end
    end

    // State machine logic
    always @(posedge clk) begin
        if (rst_n) begin
            case (current_state)
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