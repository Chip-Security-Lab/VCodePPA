//SystemVerilog
module var_freq_osc(
    input main_clk,
    input rst_n,
    input [7:0] freq_sel,
    output reg out_clk
);
    // Stage 1: Calculate max_count
    reg [7:0] freq_sel_stage1;
    reg [15:0] max_count_stage1;
    reg valid_stage1;

    // Stage 2: Compare and update
    reg [15:0] counter;
    reg [15:0] max_count_stage2;
    reg valid_stage2;
    
    // Pipeline Stage 1: Calculate max_count
    always @(posedge main_clk or negedge rst_n) begin
        if (!rst_n) begin
            freq_sel_stage1 <= 8'd0;
            max_count_stage1 <= 16'd0;
            valid_stage1 <= 1'b0;
        end else begin
            freq_sel_stage1 <= freq_sel;
            max_count_stage1 <= {8'h00, ~freq_sel} + 16'd1;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Pipeline Stage 2: Counter comparison and update
    always @(posedge main_clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 16'd0;
            max_count_stage2 <= 16'd0;
            valid_stage2 <= 1'b0;
            out_clk <= 1'b0;
        end else begin
            max_count_stage2 <= max_count_stage1;
            valid_stage2 <= valid_stage1;
            
            if (valid_stage2) begin
                if (counter >= max_count_stage2 - 1) begin
                    counter <= 16'd0;
                    out_clk <= ~out_clk;
                end else begin
                    counter <= counter + 1'b1;
                end
            end
        end
    end
endmodule