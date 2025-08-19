//SystemVerilog IEEE 1364-2005
module counting_ring_counter(
    input wire clock,
    input wire reset,
    output reg [3:0] ring_out,
    output reg [1:0] position
);
    // Pipeline stage 1 registers
    reg [3:0] ring_stage1;
    reg [1:0] position_stage1;
    
    // Pipeline stage 2 registers
    reg [3:0] ring_stage2;
    reg [1:0] position_stage2;
    
    // Pipeline stage 3 registers (added)
    reg [3:0] ring_stage3;
    reg [1:0] position_stage3;
    
    // Pipeline stage 4 registers (added)
    reg [3:0] ring_stage4;
    reg [1:0] position_stage4;
    
    // Pipeline valid signals
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    
    // Intermediate computation signals
    reg [3:0] next_ring;
    reg [1:0] next_position;
    
    // Stage 1: Prepare next values calculation
    always @(posedge clock) begin
        if (reset) begin
            next_ring <= 4'b0000;
            next_position <= 2'b00;
            valid_stage1 <= 1'b0;
        end
        else begin
            next_ring <= ring_out;
            next_position <= position;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Compute rotation
    always @(posedge clock) begin
        if (reset) begin
            ring_stage2 <= 4'b0000;
            position_stage2 <= 2'b00;
            valid_stage2 <= 1'b0;
        end
        else begin
            // First part of computation - prepare rotation
            ring_stage2 <= {next_ring[2:0], next_ring[3]};
            position_stage2 <= next_position;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Compute position
    always @(posedge clock) begin
        if (reset) begin
            ring_stage3 <= 4'b0000;
            position_stage3 <= 2'b00;
            valid_stage3 <= 1'b0;
        end
        else begin
            ring_stage3 <= ring_stage2;
            // Second part of computation - increment position
            position_stage3 <= position_stage2 + 1'b1;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Stage 4: Final processing
    always @(posedge clock) begin
        if (reset) begin
            ring_stage4 <= 4'b0000;
            position_stage4 <= 2'b00;
            valid_stage4 <= 1'b0;
        end
        else begin
            ring_stage4 <= ring_stage3;
            position_stage4 <= position_stage3;
            valid_stage4 <= valid_stage3;
        end
    end
    
    // Output stage: Register final outputs
    always @(posedge clock) begin
        if (reset) begin
            ring_out <= 4'b0001;
            position <= 2'b00;
        end
        else if (valid_stage4) begin
            ring_out <= ring_stage4;
            position <= position_stage4;
        end
    end
endmodule