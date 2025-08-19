//SystemVerilog
module ITRC_EdgeDetect_Pipeline #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_src,
    output reg [WIDTH-1:0] int_out,
    output reg int_valid
);
    reg [WIDTH-1:0] prev_state_stage1, prev_state_stage2;
    reg [WIDTH-1:0] edge_detect_stage1, edge_detect_stage2;
    wire [WIDTH-1:0] edge_detect_comb;
    
    // Pre-compute edge detection
    assign edge_detect_comb = int_src & ~prev_state_stage1;
    
    // Pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_state_stage1 <= {WIDTH{1'b0}};
        end else begin
            prev_state_stage1 <= int_src;
        end
    end

    // Pipeline stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_state_stage2 <= {WIDTH{1'b0}};
            edge_detect_stage1 <= {WIDTH{1'b0}};
            int_out <= {WIDTH{1'b0}};
            int_valid <= 1'b0;
        end else begin
            prev_state_stage2 <= prev_state_stage1;
            edge_detect_stage1 <= edge_detect_comb;
            int_out <= edge_detect_stage1;
            int_valid <= |edge_detect_stage1;
        end
    end
endmodule