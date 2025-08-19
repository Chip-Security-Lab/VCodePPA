module data_en_sync #(parameter DW=8) (
    input src_clk, dst_clk, rst,
    input [DW-1:0] data,
    input data_en,
    output reg [DW-1:0] synced_data
);
    reg en_sync0, en_sync1;
    reg [DW-1:0] data_latch;
    
    always @(posedge src_clk) begin
        if(data_en) data_latch <= data;
    end
    
    always @(posedge dst_clk) begin
        {en_sync1, en_sync0} <= {en_sync0, data_en};
        if(en_sync1) synced_data <= data_latch;
    end
endmodule