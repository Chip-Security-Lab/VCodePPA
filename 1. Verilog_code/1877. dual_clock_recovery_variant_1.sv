//SystemVerilog
module dual_clock_recovery (
    // Source domain
    input wire src_clk,
    input wire src_rst_n,
    input wire [7:0] src_data,
    input wire src_valid,
    // Destination domain
    input wire dst_clk,
    input wire dst_rst_n,
    output reg [7:0] dst_data,
    output reg dst_valid
);
    // Source domain registers
    reg [7:0] src_data_reg;
    reg src_toggle;
    
    // Destination domain registers
    reg [2:0] dst_sync;
    reg [7:0] dst_data_capture;
    
    // Source domain logic
    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            src_data_reg <= 8'h0;
            src_toggle <= 1'b0;
        end
        else begin
            case (src_valid)
                1'b1: begin
                    src_data_reg <= src_data;
                    src_toggle <= ~src_toggle;
                end
                default: begin
                    src_data_reg <= src_data_reg;
                    src_toggle <= src_toggle;
                end
            endcase
        end
    end
    
    // Destination domain synchronizer
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            dst_sync <= 3'b0;
            dst_data_capture <= 8'h0;
            dst_data <= 8'h0;
            dst_valid <= 1'b0;
        end
        else begin
            dst_sync <= {dst_sync[1:0], src_toggle};
            
            case (dst_sync[2] != dst_sync[1])
                1'b1: begin
                    dst_data_capture <= src_data_reg;
                    dst_data <= dst_data_capture;
                    dst_valid <= 1'b1;
                end
                1'b0: begin
                    dst_data_capture <= dst_data_capture;
                    dst_data <= dst_data;
                    dst_valid <= 1'b0;
                end
            endcase
        end
    end
endmodule