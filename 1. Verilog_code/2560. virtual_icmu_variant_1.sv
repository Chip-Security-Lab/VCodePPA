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
    integer g;
    
    localparam IDLE = 3'b000;
    localparam SAVE_CONTEXT = 3'b001;
    localparam SWITCH_PENDING = 3'b010;
    localparam RESTORE_CONTEXT = 3'b011;
    localparam SWITCH_DONE = 3'b100;
    
    wire [INTS_PER_GUEST-1:0] unmasked_int [0:GUESTS-1];
    wire [GUESTS-1:0] has_unmasked_int;
    
    genvar gv;
    generate
        for (gv = 0; gv < GUESTS; gv = gv + 1) begin : guest_logic
            assign unmasked_int[gv] = virt_int_pending[gv] & ~virt_int_mask[gv];
            assign has_unmasked_int[gv] = |unmasked_int[gv];
        end
    endgenerate
    
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
        end else begin
            for (g = 0; g < GUESTS; g = g + 1) begin
                virt_int_pending[g] <= virt_int_pending[g] | 
                    phys_int[g*INTS_PER_GUEST +: INTS_PER_GUEST];
                
                int_pending_guest[g] <= has_unmasked_int[g];
                
                if (has_unmasked_int[g]) begin
                    guest_int_id[g] <= priority_encode_optimized(unmasked_int[g]);
                end
            end
            
            if (current_state == IDLE) begin
                guest_switch_done <= 1'b0;
                if (guest_switch_req)
                    current_state <= SAVE_CONTEXT;
            end
            else if (current_state == SAVE_CONTEXT) begin
                current_state <= SWITCH_PENDING;
            end
            else if (current_state == SWITCH_PENDING) begin
                current_state <= RESTORE_CONTEXT;
            end
            else if (current_state == RESTORE_CONTEXT) begin
                current_state <= SWITCH_DONE;
            end
            else if (current_state == SWITCH_DONE) begin
                guest_switch_done <= 1'b1;
                current_state <= IDLE;
            end
            else begin
                current_state <= IDLE;
            end
        end
    end
    
    function [2:0] priority_encode_optimized;
        input [INTS_PER_GUEST-1:0] pending;
        reg [2:0] result;
        begin
            if (pending[7]) result = 3'd7;
            else if (pending[6]) result = 3'd6;
            else if (pending[5]) result = 3'd5;
            else if (pending[4]) result = 3'd4;
            else if (pending[3]) result = 3'd3;
            else if (pending[2]) result = 3'd2;
            else if (pending[1]) result = 3'd1;
            else if (pending[0]) result = 3'd0;
            else result = 3'd0;
            priority_encode_optimized = result;
        end
    endfunction
endmodule