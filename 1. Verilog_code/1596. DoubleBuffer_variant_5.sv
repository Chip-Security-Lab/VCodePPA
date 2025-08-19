//SystemVerilog
// SystemVerilog

// First stage buffer module
module BufferStage #(parameter W=12) (
    input clk,
    input load,
    input [W-1:0] data_in,
    output reg [W-1:0] data_out
);

    always @(posedge clk) begin
        if (load) begin
            data_out <= data_in;
        end
    end

endmodule

// Control module for buffer operation
module BufferControl (
    input clk,
    input load,
    output reg load_stage1,
    output reg load_stage2
);

    always @(posedge clk) begin
        load_stage1 <= load;
        load_stage2 <= load;
    end

endmodule

// Top-level double buffer module
module DoubleBuffer #(parameter W=12) (
    input clk, 
    input load,
    input [W-1:0] data_in,
    output [W-1:0] data_out
);

    // Internal signals
    wire [W-1:0] stage1_out;
    wire load_stage1, load_stage2;

    // Control module instance
    BufferControl ctrl (
        .clk(clk),
        .load(load),
        .load_stage1(load_stage1),
        .load_stage2(load_stage2)
    );

    // First stage buffer instance
    BufferStage #(.W(W)) stage1 (
        .clk(clk),
        .load(load_stage1),
        .data_in(data_in),
        .data_out(stage1_out)
    );

    // Second stage buffer instance
    BufferStage #(.W(W)) stage2 (
        .clk(clk),
        .load(load_stage2),
        .data_in(stage1_out),
        .data_out(data_out)
    );

endmodule