//SystemVerilog - IEEE 1364-2005
module pulse_div #(parameter DIV_FACTOR = 6) (
    input i_clk, i_rst_n, i_en,
    output o_pulse
);
    localparam CNT_WIDTH = $clog2(DIV_FACTOR);
    
    // Stage 1 registers - Counter control
    reg [CNT_WIDTH-1:0] counter_stage1;
    reg valid_stage1;
    reg en_stage1;
    
    // Stage 2 registers - Pulse generation
    reg pulse_pre_stage2;
    reg valid_stage2;
    reg en_stage2;
    
    // Stage 1: Counter management and valid signal propagation
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            counter_stage1 <= {CNT_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
            en_stage1 <= 1'b0;
        end else begin
            en_stage1 <= i_en;
            valid_stage1 <= 1'b1; // Always valid after reset
            
            if (i_en) begin
                if (counter_stage1 == DIV_FACTOR-1) begin
                    counter_stage1 <= {CNT_WIDTH{1'b0}};
                end else begin
                    counter_stage1 <= counter_stage1 + 1'b1;
                end
            end
        end
    end
    
    // Stage 2: Pulse generation logic
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            pulse_pre_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            en_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            en_stage2 <= en_stage1;
            
            if (valid_stage1 && en_stage1) begin
                pulse_pre_stage2 <= (counter_stage1 == DIV_FACTOR-1);
            end else begin
                pulse_pre_stage2 <= 1'b0;
            end
        end
    end
    
    // Output assignment with final pipeline stage output
    assign o_pulse = pulse_pre_stage2 & en_stage2 & valid_stage2;
    
endmodule