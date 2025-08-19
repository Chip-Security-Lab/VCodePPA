//SystemVerilog
module fsm_reset_sequencer(
    input wire clk,
    input wire trigger,
    output reg [3:0] reset_signals
);

    // Pipeline state registers
    reg [1:0] state_stage1;
    reg [1:0] state_stage2;
    reg [1:0] state_stage3;
    
    // Pipeline valid signals
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    
    // Pipeline reset signals
    reg [3:0] reset_stage1;
    reg [3:0] reset_stage2;
    reg [3:0] reset_stage3;
    
    // First pipeline stage: Initialize and detect trigger
    always @(posedge clk) begin
        if (trigger) begin
            state_stage1 <= 2'b00;
            reset_stage1 <= 4'b1111;
            valid_stage1 <= 1'b1;
        end else if (valid_stage1) begin
            case (state_stage1)
                2'b00: begin state_stage1 <= 2'b01; reset_stage1 <= 4'b0111; end
                2'b01: begin state_stage1 <= 2'b10; reset_stage1 <= 4'b0011; end
                2'b10: begin state_stage1 <= 2'b11; reset_stage1 <= 4'b0001; end
                2'b11: begin state_stage1 <= 2'b11; reset_stage1 <= 4'b0000; end
            endcase
        end
    end
    
    // Second pipeline stage
    always @(posedge clk) begin
        state_stage2 <= state_stage1;
        reset_stage2 <= reset_stage1;
        valid_stage2 <= valid_stage1;
    end
    
    // Third pipeline stage
    always @(posedge clk) begin
        state_stage3 <= state_stage2;
        reset_stage3 <= reset_stage2;
        valid_stage3 <= valid_stage2;
    end
    
    // Output assignment
    always @(posedge clk) begin
        if (valid_stage3)
            reset_signals <= reset_stage3;
        else if (trigger)
            reset_signals <= 4'b1111;
    end
    
    // Initialize the pipeline valid signals
    initial begin
        valid_stage1 = 1'b0;
        valid_stage2 = 1'b0;
        valid_stage3 = 1'b0;
    end

endmodule