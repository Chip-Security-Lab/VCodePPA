//SystemVerilog
module cascade_timer (
    input wire clk, reset, enable, cascade_in,
    output wire cascade_out,
    output wire [15:0] count_val
);
    // Stage 1: Edge detection
    reg cascade_in_d1;
    reg enable_stage1;
    reg valid_stage1;
    reg tick_stage1;
    
    always @(posedge clk) begin
        if (reset) begin
            cascade_in_d1 <= 1'b0;
            enable_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            tick_stage1 <= 1'b0;
        end else begin
            cascade_in_d1 <= cascade_in;
            enable_stage1 <= enable;
            valid_stage1 <= 1'b1;
            tick_stage1 <= cascade_in & ~cascade_in_d1;
        end
    end
    
    // Stage 2: Counter increment preparation
    reg tick_stage2;
    reg enable_stage2;
    reg valid_stage2;
    reg [15:0] counter_stage2;
    reg increment_stage2;
    
    always @(posedge clk) begin
        if (reset) begin
            tick_stage2 <= 1'b0;
            enable_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            counter_stage2 <= 16'h0000;
            increment_stage2 <= 1'b0;
        end else begin
            tick_stage2 <= tick_stage1;
            enable_stage2 <= enable_stage1;
            valid_stage2 <= valid_stage1;
            counter_stage2 <= count_val;
            increment_stage2 <= enable_stage1 && tick_stage1 && valid_stage1;
        end
    end
    
    // Stage 3: Counter update
    reg [15:0] counter_stage3;
    reg tick_stage3;
    reg valid_stage3;
    reg overflow_stage3;
    
    always @(posedge clk) begin
        if (reset) begin
            counter_stage3 <= 16'h0000;
            tick_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
            overflow_stage3 <= 1'b0;
        end else begin
            counter_stage3 <= increment_stage2 ? counter_stage2 + 16'h0001 : counter_stage2;
            tick_stage3 <= tick_stage2;
            valid_stage3 <= valid_stage2;
            overflow_stage3 <= increment_stage2 && (counter_stage2 == 16'hFFFF);
        end
    end
    
    // Stage 4: Output generation
    reg cascade_out_reg;
    reg [15:0] count_val_reg;
    
    always @(posedge clk) begin
        if (reset) begin
            cascade_out_reg <= 1'b0;
            count_val_reg <= 16'h0000;
        end else if (valid_stage3) begin
            cascade_out_reg <= overflow_stage3 && tick_stage3;
            count_val_reg <= counter_stage3;
        end
    end
    
    // Final outputs
    assign cascade_out = cascade_out_reg;
    assign count_val = count_val_reg;
    
endmodule