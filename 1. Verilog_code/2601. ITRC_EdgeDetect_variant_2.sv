//SystemVerilog
module ITRC_EdgeDetect #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_src,
    output reg [WIDTH-1:0] int_out,
    output reg int_valid
);
    reg [WIDTH-1:0] prev_state;
    wire [WIDTH-1:0] edge_detect;
    wire [WIDTH-1:0] edge_detect_buf;

    // Buffer for high fanout signal
    reg [WIDTH-1:0] edge_detect_reg;

    assign edge_detect = int_src & ~prev_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_state <= {WIDTH{1'b0}};
            int_out <= {WIDTH{1'b0}};
            int_valid <= 1'b0;
            edge_detect_reg <= {WIDTH{1'b0}};
        end else begin
            prev_state <= int_src;
            edge_detect_reg <= edge_detect; // Buffering the edge_detect signal
            int_out <= edge_detect_reg;
            int_valid <= |edge_detect_reg;
        end
    end
endmodule