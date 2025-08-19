//SystemVerilog
// Shift-and-add multiplier module
module ShiftAddMultiplier #(
    parameter WIDTH = 4
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] multiplicand,
    input start,
    output reg done,
    output reg [WIDTH-1:0] result
);
    reg [WIDTH-1:0] shift_reg;
    reg [1:0] count;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 0;
            result <= 0;
            count <= 0;
            done <= 0;
        end else begin
            if (start) begin
                if (!done) begin
                    if (count == 0) begin
                        shift_reg <= multiplicand;
                        result <= 0;
                        count <= count + 1;
                    end else if (count == 1) begin
                        if (shift_reg[0]) begin
                            result <= result + multiplicand;
                        end
                        shift_reg <= shift_reg >> 1;
                        count <= count + 1;
                    end else if (count == 2) begin
                        if (shift_reg[0]) begin
                            result <= result + (multiplicand << 1);
                        end
                        shift_reg <= shift_reg >> 1;
                        count <= count + 1;
                    end else if (count == 3) begin
                        if (shift_reg[0]) begin
                            result <= result + (multiplicand << 2);
                        end
                        shift_reg <= shift_reg >> 1;
                        count <= count + 1;
                    end else begin
                        if (shift_reg[0]) begin
                            result <= result + (multiplicand << 3);
                        end
                        done <= 1;
                    end
                end
            end else begin
                done <= 0;
            end
        end
    end
endmodule

// Group processing module
module GroupProcessor #(
    parameter GROUP_WIDTH = 4
)(
    input clk,
    input rst_n,
    input [GROUP_WIDTH-1:0] group_src,
    input group_en,
    output reg group_int
);
    wire mult_done;
    wire [GROUP_WIDTH-1:0] mult_result;
    reg start_mult;
    
    ShiftAddMultiplier #(
        .WIDTH(GROUP_WIDTH)
    ) multiplier (
        .clk(clk),
        .rst_n(rst_n),
        .multiplicand(group_src),
        .start(start_mult),
        .done(mult_done),
        .result(mult_result)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_mult <= 0;
            group_int <= 0;
        end else begin
            if (group_en) begin
                if (!mult_done) begin
                    start_mult <= 1;
                end else begin
                    start_mult <= 0;
                    group_int <= (|mult_result);
                end
            end else begin
                start_mult <= 0;
                group_int <= 0;
            end
        end
    end
endmodule

// Top-level module
module ITRC_Grouped #(
    parameter GROUPS = 4,
    parameter GROUP_WIDTH = 4
)(
    input clk,
    input rst_n,
    input [GROUPS*GROUP_WIDTH-1:0] int_src,
    input [GROUPS-1:0] group_en,
    output [GROUPS-1:0] group_int
);
    genvar g;
    generate
        for (g=0; g<GROUPS; g=g+1) begin : gen_group
            wire [GROUP_WIDTH-1:0] group_src = int_src[g*GROUP_WIDTH +: GROUP_WIDTH];
            
            GroupProcessor #(
                .GROUP_WIDTH(GROUP_WIDTH)
            ) processor (
                .clk(clk),
                .rst_n(rst_n),
                .group_src(group_src),
                .group_en(group_en[g]),
                .group_int(group_int[g])
            );
        end
    endgenerate
endmodule