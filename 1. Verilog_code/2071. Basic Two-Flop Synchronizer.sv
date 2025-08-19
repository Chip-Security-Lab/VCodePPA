module two_flop_sync #(parameter WIDTH = 8) (
    input wire clk_dst,
    input wire rst_n,
    input wire [WIDTH-1:0] data_src,
    output reg [WIDTH-1:0] data_dst
);
    reg [WIDTH-1:0] meta;
    
    always @(posedge clk_dst or negedge rst_n) begin
        if (!rst_n) begin
            meta <= {WIDTH{1'b0}};
            data_dst <= {WIDTH{1'b0}};
        end else begin
            meta <= data_src;
            data_dst <= meta;
        end
    end
endmodule