module multibit_toggle_sync #(parameter WIDTH = 4) (
    input wire src_clk, dst_clk, reset,
    input wire [WIDTH-1:0] data_src,
    input wire update,
    output reg [WIDTH-1:0] data_dst
);
    reg toggle_src;
    reg [WIDTH-1:0] data_captured;
    reg [2:0] sync_toggle_dst;
    
    // Source domain
    always @(posedge src_clk) begin
        if (reset) begin
            toggle_src <= 1'b0;
            data_captured <= {WIDTH{1'b0}};
        end else if (update) begin
            toggle_src <= ~toggle_src;
            data_captured <= data_src;
        end
    end
    
    // Destination domain
    always @(posedge dst_clk) begin
        if (reset) begin
            sync_toggle_dst <= 3'b0;
            data_dst <= {WIDTH{1'b0}};
        end else begin
            sync_toggle_dst <= {sync_toggle_dst[1:0], toggle_src};
            if (sync_toggle_dst[2] != sync_toggle_dst[1])
                data_dst <= data_captured;
        end
    end
endmodule