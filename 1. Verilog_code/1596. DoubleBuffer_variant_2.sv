//SystemVerilog
module DoubleBuffer #(parameter W=12) (
    input clk,
    input rst_n,
    input load,
    input [W-1:0] data_in,
    output [W-1:0] data_out
);

// Pipeline stage registers
reg [W-1:0] buf1_stage1;
reg [W-1:0] buf1_stage2;
reg [W-1:0] buf2_stage1;
reg [W-1:0] buf2_stage2;

// Control signals
reg load_stage1;
reg load_stage2;

// Output assignment
assign data_out = buf2_stage2;

// Pipeline stage 1
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        buf1_stage1 <= {W{1'b0}};
        load_stage1 <= 1'b0;
    end else begin
        buf1_stage1 <= data_in;
        load_stage1 <= load;
    end
end

// Pipeline stage 2
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        buf1_stage2 <= {W{1'b0}};
        buf2_stage1 <= {W{1'b0}};
        load_stage2 <= 1'b0;
    end else begin
        buf1_stage2 <= buf1_stage1;
        buf2_stage1 <= buf1_stage2;
        load_stage2 <= load_stage1;
    end
end

// Pipeline stage 3
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        buf2_stage2 <= {W{1'b0}};
    end else if (load_stage2) begin
        buf2_stage2 <= buf2_stage1;
    end
end

endmodule