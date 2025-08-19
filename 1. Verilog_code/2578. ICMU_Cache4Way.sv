module ICMU_Cache4Way #(
    parameter DW = 32,
    parameter TAG_W = 20,
    parameter INDEX_W = 8
)(
    input clk,
    input [TAG_W+INDEX_W-1:0] ctx_addr,
    input [DW-1:0] data_in,
    output [DW-1:0] data_out,
    input cache_en
);
    reg [DW-1:0] data_way [0:3][0:(1<<INDEX_W)-1];
    reg [TAG_W-1:0] tag_way [0:3][0:(1<<INDEX_W)-1];
    reg [1:0] lru [0:(1<<INDEX_W)-1];
    
    wire [INDEX_W-1:0] index = ctx_addr[INDEX_W-1:0];
    wire [TAG_W-1:0] tag = ctx_addr[TAG_W+INDEX_W-1:INDEX_W];
    reg [1:0] hit_way;
    reg hit_found;
    integer i;

    always @(posedge clk) begin
        if (cache_en) begin
            // Find matching way
            hit_found = 1'b0;
            hit_way = 2'b00;
            
            for (i = 0; i < 4; i=i+1) begin
                if (tag_way[i][index] == tag) begin
                    hit_way = i[1:0];
                    hit_found = 1'b1;
                end
            end
            
            if (hit_found) begin
                // Hit - update LRU
                lru[index] <= (lru[index] == hit_way) ? lru[index] : hit_way;
            end else begin
                // Miss - replace LRU
                data_way[lru[index]][index] <= data_in;
                tag_way[lru[index]][index] <= tag;
            end
        end
    end

    assign data_out = hit_found ? data_way[hit_way][index] : {DW{1'b0}};
endmodule