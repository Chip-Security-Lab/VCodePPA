//SystemVerilog
//----------------------------------------------
// Top-level module: quadrature_clk_gen
//----------------------------------------------
module quadrature_clk_gen #(
    parameter RESET_ACTIVE_LOW = 1,
    parameter PIPELINE_STAGES = 3
)(
    input wire reference_clk,
    input wire reset_n,
    input wire enable,
    output wire I_clk,  // In-phase clock
    output wire Q_clk   // Quadrature clock (90° phase shift)
);
    // Pipeline control signals
    reg [PIPELINE_STAGES-1:0] valid_pipeline;
    
    // Internal signals
    wire toggle_signal;
    wire toggle_stage1, toggle_stage2;
    
    // Clock toggle generator submodule
    toggle_generator #(
        .RESET_ACTIVE_LOW(RESET_ACTIVE_LOW),
        .PIPELINE_STAGES(PIPELINE_STAGES)
    ) toggle_gen_inst (
        .clk(reference_clk),
        .reset_n(reset_n),
        .enable(enable),
        .valid_pipeline(valid_pipeline),
        .toggle_out(toggle_signal),
        .toggle_stage1(toggle_stage1),
        .toggle_stage2(toggle_stage2)
    );
    
    // In-phase clock generator submodule
    i_clock_generator #(
        .RESET_ACTIVE_LOW(RESET_ACTIVE_LOW),
        .PIPELINE_STAGES(PIPELINE_STAGES)
    ) i_clk_gen_inst (
        .clk(reference_clk),
        .reset_n(reset_n),
        .toggle_in(toggle_signal),
        .toggle_stage1(toggle_stage1),
        .toggle_stage2(toggle_stage2),
        .valid_pipeline(valid_pipeline),
        .i_clk_out(I_clk)
    );
    
    // Quadrature clock generator submodule
    q_clock_generator #(
        .RESET_ACTIVE_LOW(RESET_ACTIVE_LOW),
        .PIPELINE_STAGES(PIPELINE_STAGES)
    ) q_clk_gen_inst (
        .clk(reference_clk),
        .reset_n(reset_n),
        .toggle_in(toggle_signal),
        .toggle_stage1(toggle_stage1),
        .toggle_stage2(toggle_stage2),
        .valid_pipeline(valid_pipeline),
        .q_clk_out(Q_clk)
    );
    
    // Valid pipeline control logic
    always @(posedge reference_clk or negedge reset_n) begin
        if (!reset_n) begin
            valid_pipeline <= {PIPELINE_STAGES{1'b0}};
        end else if (enable) begin
            valid_pipeline <= {valid_pipeline[PIPELINE_STAGES-2:0], 1'b1};
        end
    end
    
endmodule

//----------------------------------------------
// Toggle signal generator module (pipelined)
//----------------------------------------------
module toggle_generator #(
    parameter RESET_ACTIVE_LOW = 1,
    parameter PIPELINE_STAGES = 3
)(
    input wire clk,
    input wire reset_n,
    input wire enable,
    input wire [PIPELINE_STAGES-1:0] valid_pipeline,
    output reg toggle_out,
    output reg toggle_stage1,
    output reg toggle_stage2
);
    // Reset polarity handling
    wire reset_active = RESET_ACTIVE_LOW ? ~reset_n : reset_n;
    
    // Pipeline registers for toggle logic
    reg toggle_compute;
    
    // Stage 1: Compute toggle value
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            toggle_compute <= 1'b0;
        end else if (enable && valid_pipeline[0]) begin
            toggle_compute <= ~toggle_compute;
        end
    end
    
    // Stage 2: Pipeline register 1
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            toggle_stage1 <= 1'b0;
        end else if (valid_pipeline[1]) begin
            toggle_stage1 <= toggle_compute;
        end
    end
    
    // Stage 3: Pipeline register 2
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            toggle_stage2 <= 1'b0;
        end else if (valid_pipeline[2]) begin
            toggle_stage2 <= toggle_stage1;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            toggle_out <= 1'b0;
        end else if (valid_pipeline[PIPELINE_STAGES-1]) begin
            toggle_out <= toggle_stage2;
        end
    end
endmodule

//----------------------------------------------
// In-phase clock generator module (pipelined)
//----------------------------------------------
module i_clock_generator #(
    parameter RESET_ACTIVE_LOW = 1,
    parameter PIPELINE_STAGES = 3
)(
    input wire clk,
    input wire reset_n,
    input wire toggle_in,
    input wire toggle_stage1,
    input wire toggle_stage2,
    input wire [PIPELINE_STAGES-1:0] valid_pipeline,
    output reg i_clk_out
);
    // Reset polarity handling
    wire reset_active = RESET_ACTIVE_LOW ? ~reset_n : reset_n;
    
    // Pipeline registers for I clock
    reg i_clk_stage1, i_clk_stage2;
    reg toggle_active_stage1, toggle_active_stage2;
    
    // Stage 1: Compute toggle activation
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            toggle_active_stage1 <= 1'b0;
        end else if (valid_pipeline[0]) begin
            toggle_active_stage1 <= toggle_stage1;
        end
    end
    
    // Stage 2: Prepare I clock transition
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            i_clk_stage1 <= 1'b0;
            toggle_active_stage2 <= 1'b0;
        end else if (valid_pipeline[1]) begin
            toggle_active_stage2 <= toggle_active_stage1;
            if (toggle_active_stage1) begin
                i_clk_stage1 <= ~i_clk_stage1;
            end
        end
    end
    
    // Stage 3: Final I clock stage
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            i_clk_stage2 <= 1'b0;
        end else if (valid_pipeline[2]) begin
            i_clk_stage2 <= i_clk_stage1;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            i_clk_out <= 1'b0;
        end else if (valid_pipeline[PIPELINE_STAGES-1]) begin
            i_clk_out <= i_clk_stage2;
        end
    end
endmodule

//----------------------------------------------
// Quadrature clock generator module (pipelined)
//----------------------------------------------
module q_clock_generator #(
    parameter RESET_ACTIVE_LOW = 1,
    parameter PIPELINE_STAGES = 3
)(
    input wire clk,
    input wire reset_n,
    input wire toggle_in,
    input wire toggle_stage1,
    input wire toggle_stage2,
    input wire [PIPELINE_STAGES-1:0] valid_pipeline,
    output reg q_clk_out
);
    // Reset polarity handling
    wire reset_active = RESET_ACTIVE_LOW ? ~reset_n : reset_n;
    
    // Pipeline registers for Q clock (quadrature)
    reg q_clk_stage1, q_clk_stage2;
    reg toggle_active_stage1, toggle_active_stage2;
    
    // Clock domain crossing for quadrature phase
    reg toggle_sync;
    
    // Synchronize toggle to negative edge
    always @(negedge clk or negedge reset_n) begin
        if (!reset_n) begin
            toggle_sync <= 1'b0;
        end else begin
            toggle_sync <= toggle_stage1;
        end
    end
    
    // Stage 1: Compute toggle activation (negative edge clock domain)
    always @(negedge clk or negedge reset_n) begin
        if (!reset_n) begin
            toggle_active_stage1 <= 1'b0;
        end else if (valid_pipeline[0]) begin
            toggle_active_stage1 <= toggle_sync;
        end
    end
    
    // Stage 2: Prepare Q clock transition (negative edge clock domain)
    always @(negedge clk or negedge reset_n) begin
        if (!reset_n) begin
            q_clk_stage1 <= 1'b0;
            toggle_active_stage2 <= 1'b0;
        end else if (valid_pipeline[1]) begin
            toggle_active_stage2 <= toggle_active_stage1;
            if (toggle_active_stage1) begin
                q_clk_stage1 <= ~q_clk_stage1;
            end
        end
    end
    
    // Stage 3: Final Q clock stage (negative edge clock domain)
    always @(negedge clk or negedge reset_n) begin
        if (!reset_n) begin
            q_clk_stage2 <= 1'b0;
        end else if (valid_pipeline[2]) begin
            q_clk_stage2 <= q_clk_stage1;
        end
    end
    
    // Output stage (negative edge clock domain)
    always @(negedge clk or negedge reset_n) begin
        if (!reset_n) begin
            q_clk_out <= 1'b0;
        end else if (valid_pipeline[PIPELINE_STAGES-1]) begin
            q_clk_out <= q_clk_stage2;
        end
    end
endmodule