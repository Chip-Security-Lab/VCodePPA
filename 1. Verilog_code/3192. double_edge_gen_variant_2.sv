//SystemVerilog
module double_edge_gen (
    input  wire clk_in,
    input  wire rst_n,
    output wire clk_out
);

    // Pipeline stage 1 - Phase generation
    reg phase_signal_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 - Edge detection
    reg phase_signal_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 - Output generation
    reg clk_out_reg;
    reg valid_stage3;

    // Stage 1: Phase generation with reset
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            phase_signal_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            phase_signal_stage1 <= ~phase_signal_stage1;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Edge detection
    always @(negedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            phase_signal_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            phase_signal_stage2 <= phase_signal_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Output generation
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            clk_out_reg <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            clk_out_reg <= phase_signal_stage2;
            valid_stage3 <= valid_stage2;
        end
    end

    // Output assignment with valid signal
    assign clk_out = valid_stage3 ? clk_out_reg : 1'b0;

endmodule