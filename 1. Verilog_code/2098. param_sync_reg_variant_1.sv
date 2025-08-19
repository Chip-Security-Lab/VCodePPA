//SystemVerilog
module param_sync_reg #(parameter WIDTH=4) (
    input clk1,
    input clk2,
    input rst,
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] dout
);
    // Stage 1: Capture din on clk1
    reg [WIDTH-1:0] din_stage1;
    always @(posedge clk1 or posedge rst) begin
        if (rst)
            din_stage1 <= {WIDTH{1'b0}};
        else
            din_stage1 <= din;
    end

    // Stage 2: Pipeline register in clk1 domain
    reg [WIDTH-1:0] din_stage2;
    always @(posedge clk1 or posedge rst) begin
        if (rst)
            din_stage2 <= {WIDTH{1'b0}};
        else
            din_stage2 <= din_stage1;
    end

    // Stage 3: Synchronizer register in clk2 domain (first stage)
    reg [WIDTH-1:0] sync_stage1;
    always @(posedge clk2 or posedge rst) begin
        if (rst)
            sync_stage1 <= {WIDTH{1'b0}};
        else
            sync_stage1 <= din_stage2;
    end

    // Stage 4: Synchronizer register in clk2 domain (second stage)
    reg [WIDTH-1:0] sync_stage2;
    always @(posedge clk2 or posedge rst) begin
        if (rst)
            sync_stage2 <= {WIDTH{1'b0}};
        else
            sync_stage2 <= sync_stage1;
    end

    assign dout = sync_stage2;
endmodule