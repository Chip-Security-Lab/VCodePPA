//SystemVerilog
module quad_phase_gen #(
    parameter PHASE_NUM = 4
)(
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    output reg valid_out,
    output reg [PHASE_NUM-1:0] phase_clks
);

    // Local parameters
    localparam INIT_PHASE = {{(PHASE_NUM-1){1'b0}}, 1'b1};
    localparam PIPELINE_STAGES = 2; // Number of pipeline stages
    
    // Pipeline registers
    reg [PHASE_NUM-1:0] phase_clks_stage1;
    reg [PHASE_NUM-1:0] phase_clks_stage2;
    reg valid_stage1;
    reg valid_stage2;
    
    // Pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_clks_stage1 <= INIT_PHASE;
            valid_stage1 <= 1'b0;
        end else begin
            phase_clks_stage1 <= {phase_clks[PHASE_NUM-2:0], phase_clks[PHASE_NUM-1]};
            valid_stage1 <= valid_in;
        end
    end
    
    // Pipeline stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_clks_stage2 <= INIT_PHASE;
            valid_stage2 <= 1'b0;
        end else begin
            phase_clks_stage2 <= phase_clks_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_clks <= INIT_PHASE;
            valid_out <= 1'b0;
        end else begin
            phase_clks <= phase_clks_stage2;
            valid_out <= valid_stage2;
        end
    end

endmodule