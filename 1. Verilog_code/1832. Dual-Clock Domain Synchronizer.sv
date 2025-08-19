module cross_domain_sync #(parameter BUS_WIDTH = 16) (
    // Source domain signals
    input  wire                  src_clk,
    input  wire                  src_rst,
    input  wire [BUS_WIDTH-1:0]  src_data,
    input  wire                  src_valid,
    output reg                   src_ready,
    
    // Destination domain signals
    input  wire                  dst_clk,
    input  wire                  dst_rst,
    output reg  [BUS_WIDTH-1:0]  dst_data,
    output reg                   dst_valid,
    input  wire                  dst_ready
);
    // Sync flags between domains
    reg src_toggle_flag;
    reg [2:0] dst_sync_flag;
    
    // Source domain logic
    always @(posedge src_clk or posedge src_rst) begin
        if (src_rst) begin
            src_toggle_flag <= 1'b0;
            src_ready <= 1'b1;
        end else if (src_valid && src_ready) begin
            src_toggle_flag <= ~src_toggle_flag;
            src_ready <= 1'b0;
        end else if (dst_sync_flag[2] == src_toggle_flag) begin
            src_ready <= 1'b1;
        end
    end
    
    // Destination domain logic
    always @(posedge dst_clk or posedge dst_rst) begin
        if (dst_rst) begin
            dst_sync_flag <= 3'b000;
            dst_valid <= 1'b0;
            dst_data <= {BUS_WIDTH{1'b0}};
        end else begin
            dst_sync_flag <= {dst_sync_flag[1:0], src_toggle_flag};
            
            if (dst_sync_flag[2] != dst_sync_flag[1] && !dst_valid) begin
                dst_data <= src_data;
                dst_valid <= 1'b1;
            end else if (dst_valid && dst_ready) begin
                dst_valid <= 1'b0;
            end
        end
    end
endmodule