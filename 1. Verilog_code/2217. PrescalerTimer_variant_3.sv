//SystemVerilog - IEEE 1364-2005
module PrescalerTimer #(parameter PRESCALE=8) (
    input clk, rst_n,
    input enable,          // Input to enable timer operation
    output reg valid_out,  // Output valid signal 
    output reg tick
);
    // Calculate width based on parameter
    localparam WIDTH = $clog2(PRESCALE);
    
    // Pipeline stage registers
    reg [WIDTH-1:0] ps_cnt_stage1;
    reg terminal_count_stage1;
    reg valid_stage1, valid_stage2;
    
    // Pre-compute terminal count condition (stage 1)
    wire terminal_count = (ps_cnt_stage1 == PRESCALE-1);
    
    // Pipeline Stage 1 - Counter and terminal count detection
    always @(posedge clk) begin
        if (!rst_n) begin
            ps_cnt_stage1 <= {WIDTH{1'b0}};
            terminal_count_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            // Counter logic
            if (enable) begin
                ps_cnt_stage1 <= terminal_count ? {WIDTH{1'b0}} : ps_cnt_stage1 + 1'b1;
                terminal_count_stage1 <= terminal_count;
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Pipeline Stage 2 - Tick generation
    always @(posedge clk) begin
        if (!rst_n) begin
            tick <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            // Generate tick based on terminal count from stage 1
            tick <= valid_stage1 ? terminal_count_stage1 : 1'b0;
            valid_stage2 <= valid_stage1;
            valid_out <= valid_stage2;
        end
    end
endmodule