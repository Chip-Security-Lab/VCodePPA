//SystemVerilog
//IEEE 1364-2005 Verilog
module axi_stream_buf #(parameter DW=64) (
    input clk, rst_n,
    input tvalid_in, tready_out,
    output tvalid_out, tready_in,
    input [DW-1:0] tdata_in,
    output reg [DW-1:0] tdata_out
);
    // 内部状态信号
    reg buf_valid;
    
    // 优化后的组合逻辑信号
    wire transfer_in;
    wire transfer_out;
    
    // 优化后的组合逻辑部分
    assign tready_in = ~buf_valid | tready_out;
    assign tvalid_out = buf_valid;
    
    // 优化后的条件信号
    assign transfer_in = tvalid_in & tready_in;
    assign transfer_out = tvalid_out & tready_out;
    
    // 优化的时序逻辑部分 - 合并数据和有效位控制
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            buf_valid <= 1'b0;
            tdata_out <= {DW{1'b0}};
        end
        else begin
            if(transfer_in) begin
                tdata_out <= tdata_in;
                if(!transfer_out) begin
                    buf_valid <= 1'b1;
                end
            end
            else if(transfer_out) begin
                buf_valid <= 1'b0;
            end
        end
    end
endmodule