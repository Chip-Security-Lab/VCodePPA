module bus_sync_valid #(parameter BUS_WIDTH = 16) (
    input wire src_clk, dst_clk, rst,
    input wire [BUS_WIDTH-1:0] data_in,
    input wire valid_in,
    output reg valid_out,
    output reg [BUS_WIDTH-1:0] data_out
);
    reg valid_toggle;
    reg [BUS_WIDTH-1:0] data_capture;
    reg [2:0] sync_valid;
    
    // Source domain
    always @(posedge src_clk) begin
        if (rst) begin
            valid_toggle <= 1'b0;
            data_capture <= {BUS_WIDTH{1'b0}};
        end else if (valid_in) begin
            valid_toggle <= ~valid_toggle;
            data_capture <= data_in;
        end
    end
    
    // Destination domain
    always @(posedge dst_clk) begin
        if (rst) begin
            sync_valid <= 3'b0;
            valid_out <= 1'b0;
            data_out <= {BUS_WIDTH{1'b0}};
        end else begin
            sync_valid <= {sync_valid[1:0], valid_toggle};
            valid_out <= sync_valid[2] ^ sync_valid[1];
            if (sync_valid[2] ^ sync_valid[1]) data_out <= data_capture;
        end
    end
endmodule