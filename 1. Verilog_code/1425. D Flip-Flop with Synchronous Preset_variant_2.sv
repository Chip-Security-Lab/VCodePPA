//SystemVerilog
// Top-level module with increased pipeline depth
module d_ff_sync_preset (
    input wire clk,
    input wire preset,
    input wire d,
    output wire q
);
    // Internal pipeline signals
    wire mux_out_stage1;
    wire reg_stage1_out;
    wire reg_stage2_out;
    
    // Instantiate input mux (stage 1)
    input_mux input_selector (
        .preset(preset),
        .d(d),
        .mux_out(mux_out_stage1)
    );
    
    // Pipeline stage 1
    pipeline_stage1 reg_stage1 (
        .clk(clk),
        .data_in(mux_out_stage1),
        .data_out(reg_stage1_out)
    );
    
    // Pipeline stage 2
    pipeline_stage2 reg_stage2 (
        .clk(clk),
        .data_in(reg_stage1_out),
        .data_out(reg_stage2_out)
    );
    
    // Pipeline stage 3 (final stage)
    pipeline_stage3 reg_stage3 (
        .clk(clk),
        .data_in(reg_stage2_out),
        .data_out(q)
    );
    
endmodule

// Input multiplexer module - handles preset logic (unchanged)
module input_mux (
    input wire preset,
    input wire d,
    output wire mux_out
);
    // Implement the multiplexer logic
    assign mux_out = preset ? 1'b1 : d;
endmodule

// Pipeline stage 1 - first register stage
module pipeline_stage1 (
    input wire clk,
    input wire data_in,
    output reg data_out
);
    // Stage 1 register logic
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule

// Pipeline stage 2 - intermediate register stage
module pipeline_stage2 (
    input wire clk,
    input wire data_in,
    output reg data_out
);
    // Stage 2 register logic
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule

// Pipeline stage 3 - final register stage
module pipeline_stage3 (
    input wire clk,
    input wire data_in,
    output reg data_out
);
    // Stage 3 register logic
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule