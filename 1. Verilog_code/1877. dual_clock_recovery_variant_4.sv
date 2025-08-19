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
    // Source domain registers - 将数据寄存直接连到输入
    reg src_toggle;
    wire [7:0] src_data_reg;
    assign src_data_reg = src_data;
    
    // Destination domain registers
    reg [2:0] dst_sync;
    reg [7:0] dst_data_capture;
    reg toggle_detected;
    
    // Source domain logic - 优化后只对toggle信号进行寄存
    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            src_toggle <= 1'b0;
        end else if (src_valid) begin
            src_toggle <= ~src_toggle;
        end
    end
    
    // Destination domain synchronizer
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            dst_sync <= 3'b0;
            toggle_detected <= 1'b0;
        end else begin
            dst_sync <= {dst_sync[1:0], src_toggle};
            toggle_detected <= (dst_sync[2] != dst_sync[1]);
        end
    end
    
    // Destination domain data path - 分离数据捕获和有效信号生成逻辑
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            dst_data_capture <= 8'h0;
            dst_data <= 8'h0;
            dst_valid <= 1'b0;
        end else begin
            if (toggle_detected) begin
                dst_data_capture <= src_data_reg;
                dst_data <= dst_data_capture;
                dst_valid <= 1'b1;
            end else begin
                dst_valid <= 1'b0;
            end
        end
    end
endmodule