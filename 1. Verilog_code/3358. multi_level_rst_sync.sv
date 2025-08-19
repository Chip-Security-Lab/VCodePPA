module multi_level_rst_sync (
    input  wire clock,
    input  wire hard_rst_n,
    input  wire soft_rst_n,
    output wire system_rst_n,
    output wire periph_rst_n
);
    reg [1:0] hard_rst_sync;
    reg [1:0] soft_rst_sync;
    
    always @(posedge clock or negedge hard_rst_n) begin
        if (!hard_rst_n)
            hard_rst_sync <= 2'b00;
        else
            hard_rst_sync <= {hard_rst_sync[0], 1'b1};
    end
    
    always @(posedge clock or negedge soft_rst_n) begin
        if (!soft_rst_n || !hard_rst_sync[1])
            soft_rst_sync <= 2'b00;
        else
            soft_rst_sync <= {soft_rst_sync[0], 1'b1};
    end
    
    assign system_rst_n = hard_rst_sync[1];
    assign periph_rst_n = soft_rst_sync[1];
endmodule