//SystemVerilog
module axi_stream_adapter #(parameter DW=32) (
    input clk, resetn,
    input [DW-1:0] tdata,
    input tvalid,
    output reg tready,
    output reg [DW-1:0] rdata,
    output reg rvalid
);
    // 增加中间寄存器进行后向重定时
    reg data_valid;
    reg [DW-1:0] data_reg;
    
    always @(posedge clk) begin
        if(!resetn) begin
            // 复位逻辑
            tready <= 1'b1;
            data_valid <= 1'b0;
            data_reg <= {DW{1'b0}};
            rvalid <= 1'b0;
            rdata <= {DW{1'b0}};
        end else begin
            // 输入数据处理逻辑
            if(tvalid & tready) begin
                data_reg <= tdata;
                data_valid <= 1'b1;
                tready <= 1'b0;
            end else begin
                data_valid <= 1'b0;
                tready <= 1'b1;
            end
            
            // 输出数据处理逻辑
            rvalid <= data_valid;
            if(data_valid) begin
                rdata <= data_reg;
            end
        end
    end
endmodule