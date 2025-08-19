//SystemVerilog
module RoundRobinITRC #(parameter WIDTH=8) (
    input wire clock, reset,
    input wire [WIDTH-1:0] interrupts,
    output reg service_req,
    output reg [2:0] service_id
);
    reg [2:0] current_position_stage1, current_position_stage2;
    reg [WIDTH-1:0] interrupt_mask_stage1, interrupt_mask_stage2;
    reg [WIDTH-1:0] masked_interrupts_stage1;
    reg service_req_stage1;
    
    // Stage 1: Reset logic
    always @(posedge clock) begin
        if (reset) begin
            current_position_stage1 <= 0;
            current_position_stage2 <= 0;
            service_req_stage1 <= 0;
            service_req <= 0;
            service_id <= 0;
            interrupt_mask_stage1 <= 0;
            interrupt_mask_stage2 <= 0;
            masked_interrupts_stage1 <= 0;
        end
    end
    
    // Stage 1: Interrupt mask generation
    always @(posedge clock) begin
        if (!reset) begin
            case (current_position_stage1)
                0: interrupt_mask_stage1 <= 8'b11111111;
                1: interrupt_mask_stage1 <= 8'b11111110;
                2: interrupt_mask_stage1 <= 8'b11111100;
                3: interrupt_mask_stage1 <= 8'b11111000;
                4: interrupt_mask_stage1 <= 8'b11110000;
                5: interrupt_mask_stage1 <= 8'b11100000;
                6: interrupt_mask_stage1 <= 8'b11000000;
                7: interrupt_mask_stage1 <= 8'b10000000;
                default: interrupt_mask_stage1 <= 8'b11111111;
            endcase
        end
    end
    
    // Stage 1: Interrupt processing
    always @(posedge clock) begin
        if (!reset) begin
            masked_interrupts_stage1 <= interrupts & interrupt_mask_stage1;
            service_req_stage1 <= |interrupts;
        end
    end
    
    // Stage 2: Pipeline registers
    always @(posedge clock) begin
        if (!reset) begin
            interrupt_mask_stage2 <= interrupt_mask_stage1;
            current_position_stage2 <= current_position_stage1;
            service_req <= service_req_stage1;
        end
    end
    
    // Stage 2: Service ID calculation
    always @(posedge clock) begin
        if (!reset && |masked_interrupts_stage1) begin
            case (1'b1)
                masked_interrupts_stage1[0]: begin
                    service_id <= 0;
                    current_position_stage2 <= 1;
                end
                masked_interrupts_stage1[1]: begin
                    service_id <= 1;
                    current_position_stage2 <= 2;
                end
                masked_interrupts_stage1[2]: begin
                    service_id <= 2;
                    current_position_stage2 <= 3;
                end
                masked_interrupts_stage1[3]: begin
                    service_id <= 3;
                    current_position_stage2 <= 4;
                end
                masked_interrupts_stage1[4]: begin
                    service_id <= 4;
                    current_position_stage2 <= 5;
                end
                masked_interrupts_stage1[5]: begin
                    service_id <= 5;
                    current_position_stage2 <= 6;
                end
                masked_interrupts_stage1[6]: begin
                    service_id <= 6;
                    current_position_stage2 <= 7;
                end
                masked_interrupts_stage1[7]: begin
                    service_id <= 7;
                    current_position_stage2 <= 0;
                end
                default: current_position_stage2 <= 0;
            endcase
        end
    end
endmodule