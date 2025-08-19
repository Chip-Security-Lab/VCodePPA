//SystemVerilog
// Top-level module: Hierarchical reset detector
module cascaded_reset_detector(
    input wire clk,
    input wire rst_n,
    input wire [3:0] reset_triggers, // Active high
    input wire [3:0] stage_enables,
    output wire [3:0] stage_resets,
    output wire system_reset
);

    wire [3:0] stage_status_internal;

    // Stage 1: Detects direct reset input with enable
    reset_stage #(
        .STAGE_IDX(0)
    ) stage0 (
        .clk(clk),
        .rst_n(rst_n),
        .reset_trigger(reset_triggers[0]),
        .prev_stage_status(1'b0),
        .stage_enable(stage_enables[0]),
        .stage_status(stage_status_internal[0])
    );

    // Stage 2: Depends on stage 1 or its own trigger
    reset_stage #(
        .STAGE_IDX(1)
    ) stage1 (
        .clk(clk),
        .rst_n(rst_n),
        .reset_trigger(reset_triggers[1]),
        .prev_stage_status(stage_status_internal[0]),
        .stage_enable(stage_enables[1]),
        .stage_status(stage_status_internal[1])
    );

    // Stage 3: Depends on stage 2 or its own trigger
    reset_stage #(
        .STAGE_IDX(2)
    ) stage2 (
        .clk(clk),
        .rst_n(rst_n),
        .reset_trigger(reset_triggers[2]),
        .prev_stage_status(stage_status_internal[1]),
        .stage_enable(stage_enables[2]),
        .stage_status(stage_status_internal[2])
    );

    // Stage 4: Depends on stage 3 or its own trigger
    reset_stage #(
        .STAGE_IDX(3)
    ) stage3 (
        .clk(clk),
        .rst_n(rst_n),
        .reset_trigger(reset_triggers[3]),
        .prev_stage_status(stage_status_internal[2]),
        .stage_enable(stage_enables[3]),
        .stage_status(stage_status_internal[3])
    );

    // Output assignment
    assign stage_resets = stage_status_internal;

    // System reset generator: OR reduction of all stage statuses
    system_reset_or system_reset_inst (
        .stage_status(stage_status_internal),
        .system_reset(system_reset)
    );

endmodule

//-----------------------------------------------------------------------------
// reset_stage: Parameterized single reset stage with enable and dependency
//-----------------------------------------------------------------------------
module reset_stage #(
    parameter integer STAGE_IDX = 0
)(
    input  wire clk,
    input  wire rst_n,
    input  wire reset_trigger,
    input  wire prev_stage_status,
    input  wire stage_enable,
    output reg  stage_status
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage_status <= 1'b0;
        end else begin
            case ({stage_enable, STAGE_IDX == 0})
                2'b10: stage_status <= reset_trigger | prev_stage_status; // STAGE_IDX != 0, enable
                2'b11: stage_status <= reset_trigger;                    // STAGE_IDX == 0, enable
                default: stage_status <= 1'b0;
            endcase
        end
    end

endmodule

//-----------------------------------------------------------------------------
// system_reset_or: OR reduction of all stage statuses to generate system reset
//-----------------------------------------------------------------------------
module system_reset_or(
    input  wire [3:0] stage_status,
    output wire       system_reset
);
    assign system_reset = |stage_status;
endmodule