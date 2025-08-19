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

    // Pipeline stage 1 registers
    reg [INTS_PER_GUEST-1:0] virt_int_pending_stage1 [0:GUESTS-1];
    reg [INTS_PER_GUEST-1:0] virt_int_mask_stage1 [0:GUESTS-1];
    reg [2:0] current_state_stage1;
    reg guest_switch_req_stage1;
    
    // Pipeline stage 2 registers
    reg [INTS_PER_GUEST-1:0] virt_int_pending_stage2 [0:GUESTS-1];
    reg [INTS_PER_GUEST-1:0] virt_int_mask_stage2 [0:GUESTS-1];
    reg [2:0] current_state_stage2;
    reg guest_switch_req_stage2;
    
    // Pipeline stage 3 registers
    reg [INTS_PER_GUEST-1:0] virt_int_pending_stage3 [0:GUESTS-1];
    reg [INTS_PER_GUEST-1:0] virt_int_mask_stage3 [0:GUESTS-1];
    reg [2:0] current_state_stage3;
    reg guest_switch_req_stage3;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    wire [2:0] inverted_mask_stage1;
    wire [2:0] sum_stage1;
    wire [2:0] carry_stage1;
    wire [2:0] sum_stage2;
    wire [2:0] carry_stage2;
    wire [2:0] sum_stage3;
    wire [2:0] carry_stage3;
    
    localparam IDLE = 3'b000;
    localparam SAVE_CONTEXT = 3'b001;
    localparam SWITCH_PENDING = 3'b010;
    localparam RESTORE_CONTEXT = 3'b011;
    localparam SWITCH_DONE = 3'b100;
    
    // Stage 1 logic
    assign inverted_mask_stage1 = ~virt_int_mask_stage1[0][2:0];
    assign carry_stage1[0] = 1'b0;
    assign carry_stage1[1] = (virt_int_pending_stage1[0][0] & inverted_mask_stage1[0]) | 
                           (carry_stage1[0] & (virt_int_pending_stage1[0][0] | inverted_mask_stage1[0]));
    assign carry_stage1[2] = (virt_int_pending_stage1[0][1] & inverted_mask_stage1[1]) | 
                           (carry_stage1[1] & (virt_int_pending_stage1[0][1] | inverted_mask_stage1[1]));
    
    assign sum_stage1[0] = virt_int_pending_stage1[0][0] ^ inverted_mask_stage1[0] ^ carry_stage1[0];
    assign sum_stage1[1] = virt_int_pending_stage1[0][1] ^ inverted_mask_stage1[1] ^ carry_stage1[1];
    assign sum_stage1[2] = virt_int_pending_stage1[0][2] ^ inverted_mask_stage1[2] ^ carry_stage1[2];
    
    // Stage 2 logic
    assign carry_stage2[0] = 1'b0;
    assign carry_stage2[1] = (virt_int_pending_stage2[0][0] & ~virt_int_mask_stage2[0][0]) | 
                           (carry_stage2[0] & (virt_int_pending_stage2[0][0] | ~virt_int_mask_stage2[0][0]));
    assign carry_stage2[2] = (virt_int_pending_stage2[0][1] & ~virt_int_mask_stage2[0][1]) | 
                           (carry_stage2[1] & (virt_int_pending_stage2[0][1] | ~virt_int_mask_stage2[0][1]));
    
    assign sum_stage2[0] = virt_int_pending_stage2[0][0] ^ ~virt_int_mask_stage2[0][0] ^ carry_stage2[0];
    assign sum_stage2[1] = virt_int_pending_stage2[0][1] ^ ~virt_int_mask_stage2[0][1] ^ carry_stage2[1];
    assign sum_stage2[2] = virt_int_pending_stage2[0][2] ^ ~virt_int_mask_stage2[0][2] ^ carry_stage2[2];
    
    // Stage 3 logic
    assign carry_stage3[0] = 1'b0;
    assign carry_stage3[1] = (virt_int_pending_stage3[0][0] & ~virt_int_mask_stage3[0][0]) | 
                           (carry_stage3[0] & (virt_int_pending_stage3[0][0] | ~virt_int_mask_stage3[0][0]));
    assign carry_stage3[2] = (virt_int_pending_stage3[0][1] & ~virt_int_mask_stage3[0][1]) | 
                           (carry_stage3[1] & (virt_int_pending_stage3[0][1] | ~virt_int_mask_stage3[0][1]));
    
    assign sum_stage3[0] = virt_int_pending_stage3[0][0] ^ ~virt_int_mask_stage3[0][0] ^ carry_stage3[0];
    assign sum_stage3[1] = virt_int_pending_stage3[0][1] ^ ~virt_int_mask_stage3[0][1] ^ carry_stage3[1];
    assign sum_stage3[2] = virt_int_pending_stage3[0][2] ^ ~virt_int_mask_stage3[0][2] ^ carry_stage3[2];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline stages
            for (integer g = 0; g < GUESTS; g = g + 1) begin
                virt_int_pending_stage1[g] <= {INTS_PER_GUEST{1'b0}};
                virt_int_mask_stage1[g] <= {INTS_PER_GUEST{1'b1}};
                virt_int_pending_stage2[g] <= {INTS_PER_GUEST{1'b0}};
                virt_int_mask_stage2[g] <= {INTS_PER_GUEST{1'b1}};
                virt_int_pending_stage3[g] <= {INTS_PER_GUEST{1'b0}};
                virt_int_mask_stage3[g] <= {INTS_PER_GUEST{1'b1}};
                guest_int_id[g] <= 3'd0;
            end
            int_pending_guest <= {GUESTS{1'b0}};
            guest_switch_done <= 1'b0;
            current_state_stage1 <= IDLE;
            current_state_stage2 <= IDLE;
            current_state_stage3 <= IDLE;
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            // Stage 1
            valid_stage1 <= 1'b1;
            guest_switch_req_stage1 <= guest_switch_req;
            for (integer g = 0; g < GUESTS; g = g + 1) begin
                virt_int_pending_stage1[g] <= virt_int_pending_stage1[g] | 
                    phys_int[g*INTS_PER_GUEST +: INTS_PER_GUEST];
                virt_int_mask_stage1[g] <= virt_int_mask_stage1[g];
            end
            
            // Stage 2
            if (valid_stage1) begin
                valid_stage2 <= 1'b1;
                guest_switch_req_stage2 <= guest_switch_req_stage1;
                for (integer g = 0; g < GUESTS; g = g + 1) begin
                    virt_int_pending_stage2[g] <= virt_int_pending_stage1[g];
                    virt_int_mask_stage2[g] <= virt_int_mask_stage1[g];
                end
                current_state_stage2 <= current_state_stage1;
            end
            
            // Stage 3
            if (valid_stage2) begin
                valid_stage3 <= 1'b1;
                guest_switch_req_stage3 <= guest_switch_req_stage2;
                for (integer g = 0; g < GUESTS; g = g + 1) begin
                    virt_int_pending_stage3[g] <= virt_int_pending_stage2[g];
                    virt_int_mask_stage3[g] <= virt_int_mask_stage2[g];
                end
                current_state_stage3 <= current_state_stage2;
            end
            
            // Output stage
            if (valid_stage3) begin
                for (integer g = 0; g < GUESTS; g = g + 1) begin
                    int_pending_guest[g] <= |sum_stage3;
                    if (|sum_stage3) begin
                        guest_int_id[g] <= priority_encode(sum_stage3);
                    end
                end
                
                case (current_state_stage3)
                    IDLE: begin
                        guest_switch_done <= 1'b0;
                        if (guest_switch_req_stage3)
                            current_state_stage1 <= SAVE_CONTEXT;
                        else
                            current_state_stage1 <= IDLE;
                    end
                    
                    SAVE_CONTEXT: begin
                        current_state_stage1 <= SWITCH_PENDING;
                    end
                    
                    SWITCH_PENDING: begin
                        current_state_stage1 <= RESTORE_CONTEXT;
                    end
                    
                    RESTORE_CONTEXT: begin
                        current_state_stage1 <= SWITCH_DONE;
                    end
                    
                    SWITCH_DONE: begin
                        guest_switch_done <= 1'b1;
                        current_state_stage1 <= IDLE;
                    end
                    
                    default: current_state_stage1 <= IDLE;
                endcase
            end
        end
    end
    
    function [2:0] priority_encode;
        input [2:0] pending;
        reg [2:0] result;
        integer j;
        begin
            result = 3'd0;
            for (j = 2; j >= 0; j=j-1)
                if (pending[j]) result = j[2:0];
            priority_encode = result;
        end
    endfunction
endmodule