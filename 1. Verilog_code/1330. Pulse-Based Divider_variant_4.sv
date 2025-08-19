//SystemVerilog
module pulse_div #(parameter DIV_FACTOR = 6) (
    input i_clk, i_rst_n, i_en,
    output o_pulse
);
    localparam CNT_WIDTH = $clog2(DIV_FACTOR);
    
    // Stage 1: Counter logic
    reg [CNT_WIDTH-1:0] counter_stage1;
    reg i_en_stage1;
    reg counter_at_max_stage1;
    reg valid_stage1;
    
    // Stage 2: Pulse preparation
    reg counter_at_max_stage2;
    reg valid_stage2;
    reg i_en_stage2;
    
    // Stage 3: Output pulse generation
    reg pulse_stage3;
    reg valid_stage3;
    reg i_en_stage3;
    
    // Stage 1: Counter logic and maximum detection
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            counter_stage1 <= {CNT_WIDTH{1'b0}};
            counter_at_max_stage1 <= 1'b0;
            i_en_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            i_en_stage1 <= i_en;
            valid_stage1 <= i_en;
            
            if (i_en) begin
                // Calculate next counter value
                if (counter_stage1 == DIV_FACTOR-1) begin
                    counter_stage1 <= {CNT_WIDTH{1'b0}};
                end else begin
                    counter_stage1 <= counter_stage1 + 1'b1;
                end
                
                // Detect maximum value
                counter_at_max_stage1 <= (counter_stage1 == DIV_FACTOR-1);
            end
        end
    end
    
    // Stage 2: Forward signals and prepare pulse
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            counter_at_max_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            i_en_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            i_en_stage2 <= i_en_stage1;
            counter_at_max_stage2 <= counter_at_max_stage1;
        end
    end
    
    // Stage 3: Generate final pulse
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            pulse_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
            i_en_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            i_en_stage3 <= i_en_stage2;
            
            if (valid_stage2) begin
                pulse_stage3 <= counter_at_max_stage2;
            end else begin
                pulse_stage3 <= 1'b0;
            end
        end
    end
    
    // Output assignment with enable qualification
    assign o_pulse = pulse_stage3 & i_en_stage3;
endmodule