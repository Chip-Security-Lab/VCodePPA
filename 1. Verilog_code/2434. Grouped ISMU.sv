module grouped_ismu(
    input clk, rstn,
    input [15:0] int_sources,
    input [3:0] group_mask,
    output reg [3:0] group_int
);
    wire [3:0] group0, group1, group2, group3;
    
    assign group0 = int_sources[3:0];
    assign group1 = int_sources[7:4];
    assign group2 = int_sources[11:8];
    assign group3 = int_sources[15:12];
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            group_int <= 4'h0;
        else begin
            group_int[0] <= ~group_mask[0] & (|group0);
            group_int[1] <= ~group_mask[1] & (|group1);
            group_int[2] <= ~group_mask[2] & (|group2);
            group_int[3] <= ~group_mask[3] & (|group3);
        end
    end
endmodule