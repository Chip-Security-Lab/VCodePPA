//SystemVerilog
module param_crossbar #(
    parameter PORTS = 4,
    parameter WIDTH = 8
)(
    input wire clock, reset,
    input wire [WIDTH-1:0] in [0:PORTS-1],
    input wire [$clog2(PORTS)-1:0] sel [0:PORTS-1],
    input wire enable,
    output reg [WIDTH-1:0] out [0:PORTS-1]
);
    // Stage 1 signals
    reg [WIDTH-1:0] stage1_data [0:PORTS-1];
    reg [$clog2(PORTS)-1:0] stage1_sel [0:PORTS-1];
    reg stage1_valid;
    
    // Stage 2 signals
    reg [WIDTH-1:0] stage2_data [0:PORTS-1];
    reg stage2_valid;
    
    // Pipeline Stage 1: Input registration and selection preparation
    pipeline_reg_stage #(
        .PORTS(PORTS),
        .WIDTH(WIDTH),
        .SEL_WIDTH($clog2(PORTS))
    ) stage1 (
        .clock(clock),
        .reset(reset),
        .enable(enable),
        .in_data(in),
        .in_sel(sel),
        .out_data(stage1_data),
        .out_sel(stage1_sel),
        .out_valid(stage1_valid)
    );
    
    // Pipeline Stage 2: Crossbar switching
    crossbar_switch_stage #(
        .PORTS(PORTS),
        .WIDTH(WIDTH)
    ) stage2 (
        .clock(clock),
        .reset(reset),
        .in_valid(stage1_valid),
        .in_data(stage1_data),
        .in_sel(stage1_sel),
        .out_data(stage2_data),
        .out_valid(stage2_valid)
    );
    
    // Final Stage: Output registration
    output_reg_stage #(
        .PORTS(PORTS),
        .WIDTH(WIDTH)
    ) stage3 (
        .clock(clock),
        .reset(reset),
        .in_valid(stage2_valid),
        .in_data(stage2_data),
        .out_data(out)
    );
endmodule

// Pipeline register stage module
module pipeline_reg_stage #(
    parameter PORTS = 4,
    parameter WIDTH = 8,
    parameter SEL_WIDTH = 2
)(
    input wire clock, reset,
    input wire enable,
    input wire [WIDTH-1:0] in_data [0:PORTS-1],
    input wire [SEL_WIDTH-1:0] in_sel [0:PORTS-1],
    output reg [WIDTH-1:0] out_data [0:PORTS-1],
    output reg [SEL_WIDTH-1:0] out_sel [0:PORTS-1],
    output reg out_valid
);
    integer i;
    
    always @(posedge clock) begin
        if (reset) begin
            for (i = 0; i < PORTS; i = i + 1) begin
                out_data[i] <= {WIDTH{1'b0}};
                out_sel[i] <= {SEL_WIDTH{1'b0}};
            end
            out_valid <= 1'b0;
        end else begin
            if (enable) begin
                for (i = 0; i < PORTS; i = i + 1) begin
                    out_data[i] <= in_data[i];
                    out_sel[i] <= in_sel[i];
                end
                out_valid <= 1'b1;
            end else begin
                out_valid <= 1'b0;
            end
        end
    end
endmodule

// Crossbar switching module
module crossbar_switch_stage #(
    parameter PORTS = 4,
    parameter WIDTH = 8
)(
    input wire clock, reset,
    input wire in_valid,
    input wire [WIDTH-1:0] in_data [0:PORTS-1],
    input wire [$clog2(PORTS)-1:0] in_sel [0:PORTS-1],
    output reg [WIDTH-1:0] out_data [0:PORTS-1],
    output reg out_valid
);
    integer i;
    
    always @(posedge clock) begin
        if (reset) begin
            for (i = 0; i < PORTS; i = i + 1) begin
                out_data[i] <= {WIDTH{1'b0}};
            end
            out_valid <= 1'b0;
        end else if (in_valid) begin
            for (i = 0; i < PORTS; i = i + 1) begin
                out_data[i] <= in_data[in_sel[i]];
            end
            out_valid <= 1'b1;
        end else begin
            out_valid <= 1'b0;
        end
    end
endmodule

// Output register stage module
module output_reg_stage #(
    parameter PORTS = 4,
    parameter WIDTH = 8
)(
    input wire clock, reset,
    input wire in_valid,
    input wire [WIDTH-1:0] in_data [0:PORTS-1],
    output reg [WIDTH-1:0] out_data [0:PORTS-1]
);
    integer i;
    
    always @(posedge clock) begin
        if (reset) begin
            for (i = 0; i < PORTS; i = i + 1) begin
                out_data[i] <= {WIDTH{1'b0}};
            end
        end else if (in_valid) begin
            for (i = 0; i < PORTS; i = i + 1) begin
                out_data[i] <= in_data[i];
            end
        end
    end
endmodule