//SystemVerilog
module pulse_div #(parameter DIV_FACTOR = 6) (
    input i_clk, i_rst_n, i_en,
    output o_pulse
);
    localparam CNT_WIDTH = $clog2(DIV_FACTOR);
    
    // Pipeline stage 1 (counter computation and max detection)
    reg [CNT_WIDTH-1:0] counter_stage1;
    reg counter_max_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 (pulse generation)
    reg pulse_r_stage2;
    reg valid_stage2;
    
    // Stage 1: Counter increment and max detection logic
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            counter_stage1 <= {CNT_WIDTH{1'b0}};
            counter_max_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= i_en;
            
            if (i_en) begin
                if (counter_stage1 == DIV_FACTOR-1) begin
                    counter_stage1 <= {CNT_WIDTH{1'b0}};
                    counter_max_stage1 <= 1'b1;
                end else begin
                    counter_stage1 <= counter_stage1 + 1'b1;
                    counter_max_stage1 <= 1'b0;
                end
            end else begin
                counter_max_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 2: Pulse generation
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            pulse_r_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            
            if (valid_stage1) begin
                pulse_r_stage2 <= counter_max_stage1;
            end else begin
                pulse_r_stage2 <= 1'b0;
            end
        end
    end
    
    // Output assignment
    assign o_pulse = pulse_r_stage2 & valid_stage2;
endmodule