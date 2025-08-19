//SystemVerilog
module ITRC_Grouped #(
    parameter GROUPS = 4,
    parameter GROUP_WIDTH = 4
)(
    input clk,
    input rst_n,
    input [GROUPS*GROUP_WIDTH-1:0] int_src,
    input [GROUPS-1:0] group_en,
    output reg [GROUPS-1:0] group_int
);

    // Buffer registers for high fanout signals
    reg [GROUPS-1:0] group_en_buf;
    reg [GROUPS*GROUP_WIDTH-1:0] int_src_buf;
    
    // First stage: Buffer input signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            group_en_buf <= {GROUPS{1'b0}};
            int_src_buf <= {(GROUPS*GROUP_WIDTH){1'b0}};
        end else begin
            group_en_buf <= group_en;
            int_src_buf <= int_src;
        end
    end

    // Second stage: Group logic with buffered signals
    genvar g;
    generate
        for (g=0; g<GROUPS; g=g+1) begin : gen_group
            wire [GROUP_WIDTH-1:0] group_src = int_src_buf[g*GROUP_WIDTH +: GROUP_WIDTH];
            reg group_or_result;
            reg group_or_result_pipe;
            reg group_en_pipe;
            
            // OR reduction with registered intermediate
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    group_or_result <= 1'b0;
                    group_or_result_pipe <= 1'b0;
                    group_en_pipe <= 1'b0;
                end else begin
                    group_or_result <= |group_src;
                    group_or_result_pipe <= group_or_result;
                    group_en_pipe <= group_en_buf[g];
                end
            end
            
            // Final AND with buffered enable
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    group_int[g] <= 1'b0;
                end else begin
                    group_int[g] <= group_en_pipe && group_or_result_pipe;
                end
            end
        end
    endgenerate

endmodule