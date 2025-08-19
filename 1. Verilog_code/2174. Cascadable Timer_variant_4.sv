//SystemVerilog
//IEEE 1364-2005 Verilog
module cascade_timer (
    input wire clk, reset, enable, cascade_in,
    output wire cascade_out,
    output wire [15:0] count_val
);
    // Stage 1: Edge detection and tick generation
    reg cascade_in_d1;
    reg tick_stage1;
    reg valid_stage1;
    
    // Stage 2: Counter calculation
    reg [15:0] counter_stage2;
    reg valid_stage2;
    
    // Stage 3: Output generation
    reg [15:0] counter_stage3;
    reg valid_stage3;
    reg cascade_out_stage3;
    reg [15:0] count_val_stage3;
    
    // Stage 1: Edge detection logic
    always @(posedge clk) begin
        if (reset) begin
            cascade_in_d1 <= 1'b0;
            tick_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            cascade_in_d1 <= cascade_in;
            tick_stage1 <= cascade_in & ~cascade_in_d1;
            valid_stage1 <= 1'b1;  // Data is valid after reset
        end
    end
    
    // Stage 2: Counter logic
    always @(posedge clk) begin
        if (reset) begin
            counter_stage2 <= 16'h0000;
            valid_stage2 <= 1'b0;
        end
        else begin
            valid_stage2 <= valid_stage1;
            if (valid_stage1) begin
                if (enable & tick_stage1) begin
                    counter_stage2 <= counter_stage2 + 16'h0001;
                end
            end
        end
    end
    
    // Stage 3: Output generation
    always @(posedge clk) begin
        if (reset) begin
            counter_stage3 <= 16'h0000;
            valid_stage3 <= 1'b0;
            cascade_out_stage3 <= 1'b0;
            count_val_stage3 <= 16'h0000;
        end
        else begin
            valid_stage3 <= valid_stage2;
            counter_stage3 <= counter_stage2;
            
            if (valid_stage2) begin
                // Generate cascade_out signal
                cascade_out_stage3 <= (counter_stage2 == 16'hFFFF) & tick_stage1;
                
                // Buffer the counter value
                count_val_stage3 <= counter_stage2;
            end
        end
    end
    
    // Assign outputs from stage 3
    assign cascade_out = cascade_out_stage3;
    assign count_val = count_val_stage3;
    
endmodule