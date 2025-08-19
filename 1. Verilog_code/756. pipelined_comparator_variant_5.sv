//SystemVerilog
module pipelined_comparator #(
    parameter WIDTH = 64
)(
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] data_x,
    input wire [WIDTH-1:0] data_y,
    output reg equal,
    output reg greater,
    output reg less
);

    // Stage 1: Register inputs and compare using carry-save
    reg [WIDTH-1:0] x_r, y_r;
    reg [WIDTH-1:0] diff_r;
    reg carry_r;
    
    // Stage 2: Intermediate results
    reg [WIDTH-1:0] diff_s2;
    reg carry_s2;
    
    // Stage 1: Register and compute difference
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x_r <= 0;
            y_r <= 0;
            diff_r <= 0;
            carry_r <= 0;
        end else begin
            x_r <= data_x;
            y_r <= data_y;
            {carry_r, diff_r} <= data_x - data_y;
        end
    end
    
    // Stage 2: Pipeline results
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            diff_s2 <= 0;
            carry_s2 <= 0;
        end else begin
            diff_s2 <= diff_r;
            carry_s2 <= carry_r;
        end
    end
    
    // Stage 3: Final comparison
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {equal, greater, less} <= 0;
        end else begin
            equal <= (diff_s2 == 0);
            greater <= !carry_s2 && (diff_s2 != 0);
            less <= carry_s2;
        end
    end
endmodule