//SystemVerilog
module decoder_dual_port (
    input [3:0] rd_addr, wr_addr,
    output reg [15:0] rd_sel, wr_sel
);
    // 为读地址和写地址解码生成选择信号
    always @(*) begin
        // 读地址解码
        if (rd_addr[0] == 1'b0) begin
            // 初始值 - 第0位为1
            if (rd_addr[1] == 1'b0) begin
                // 不需要移动2位
                if (rd_addr[2] == 1'b0) begin
                    // 不需要移动4位
                    if (rd_addr[3] == 1'b0) begin
                        // 不需要移动8位
                        rd_sel = 16'b0000000000000001;
                    end else begin
                        // 移动8位
                        rd_sel = 16'b0000000100000000;
                    end
                end else begin
                    // 移动4位
                    if (rd_addr[3] == 1'b0) begin
                        // 不需要移动8位
                        rd_sel = 16'b0000000000010000;
                    end else begin
                        // 移动8位
                        rd_sel = 16'b0001000000000000;
                    end
                end
            end else begin
                // 移动2位
                if (rd_addr[2] == 1'b0) begin
                    // 不需要移动4位
                    if (rd_addr[3] == 1'b0) begin
                        // 不需要移动8位
                        rd_sel = 16'b0000000000000100;
                    end else begin
                        // 移动8位
                        rd_sel = 16'b0000010000000000;
                    end
                end else begin
                    // 移动4位
                    if (rd_addr[3] == 1'b0) begin
                        // 不需要移动8位
                        rd_sel = 16'b0000000001000000;
                    end else begin
                        // 移动8位
                        rd_sel = 16'b0100000000000000;
                    end
                end
            end
        end else begin
            // 初始值 - 第1位为1
            if (rd_addr[1] == 1'b0) begin
                // 不需要移动2位
                if (rd_addr[2] == 1'b0) begin
                    // 不需要移动4位
                    if (rd_addr[3] == 1'b0) begin
                        // 不需要移动8位
                        rd_sel = 16'b0000000000000010;
                    end else begin
                        // 移动8位
                        rd_sel = 16'b0000001000000000;
                    end
                end else begin
                    // 移动4位
                    if (rd_addr[3] == 1'b0) begin
                        // 不需要移动8位
                        rd_sel = 16'b0000000000100000;
                    end else begin
                        // 移动8位
                        rd_sel = 16'b0010000000000000;
                    end
                end
            end else begin
                // 移动2位
                if (rd_addr[2] == 1'b0) begin
                    // 不需要移动4位
                    if (rd_addr[3] == 1'b0) begin
                        // 不需要移动8位
                        rd_sel = 16'b0000000000001000;
                    end else begin
                        // 移动8位
                        rd_sel = 16'b0000100000000000;
                    end
                end else begin
                    // 移动4位
                    if (rd_addr[3] == 1'b0) begin
                        // 不需要移动8位
                        rd_sel = 16'b0000000010000000;
                    end else begin
                        // 移动8位
                        rd_sel = 16'b1000000000000000;
                    end
                end
            end
        end

        // 写地址解码
        if (wr_addr[0] == 1'b0) begin
            // 初始值 - 第0位为1
            if (wr_addr[1] == 1'b0) begin
                // 不需要移动2位
                if (wr_addr[2] == 1'b0) begin
                    // 不需要移动4位
                    if (wr_addr[3] == 1'b0) begin
                        // 不需要移动8位
                        wr_sel = 16'b0000000000000001;
                    end else begin
                        // 移动8位
                        wr_sel = 16'b0000000100000000;
                    end
                end else begin
                    // 移动4位
                    if (wr_addr[3] == 1'b0) begin
                        // 不需要移动8位
                        wr_sel = 16'b0000000000010000;
                    end else begin
                        // 移动8位
                        wr_sel = 16'b0001000000000000;
                    end
                end
            end else begin
                // 移动2位
                if (wr_addr[2] == 1'b0) begin
                    // 不需要移动4位
                    if (wr_addr[3] == 1'b0) begin
                        // 不需要移动8位
                        wr_sel = 16'b0000000000000100;
                    end else begin
                        // 移动8位
                        wr_sel = 16'b0000010000000000;
                    end
                end else begin
                    // 移动4位
                    if (wr_addr[3] == 1'b0) begin
                        // 不需要移动8位
                        wr_sel = 16'b0000000001000000;
                    end else begin
                        // 移动8位
                        wr_sel = 16'b0100000000000000;
                    end
                end
            end
        end else begin
            // 初始值 - 第1位为1
            if (wr_addr[1] == 1'b0) begin
                // 不需要移动2位
                if (wr_addr[2] == 1'b0) begin
                    // 不需要移动4位
                    if (wr_addr[3] == 1'b0) begin
                        // 不需要移动8位
                        wr_sel = 16'b0000000000000010;
                    end else begin
                        // 移动8位
                        wr_sel = 16'b0000001000000000;
                    end
                end else begin
                    // 移动4位
                    if (wr_addr[3] == 1'b0) begin
                        // 不需要移动8位
                        wr_sel = 16'b0000000000100000;
                    end else begin
                        // 移动8位
                        wr_sel = 16'b0010000000000000;
                    end
                end
            end else begin
                // 移动2位
                if (wr_addr[2] == 1'b0) begin
                    // 不需要移动4位
                    if (wr_addr[3] == 1'b0) begin
                        // 不需要移动8位
                        wr_sel = 16'b0000000000001000;
                    end else begin
                        // 移动8位
                        wr_sel = 16'b0000100000000000;
                    end
                end else begin
                    // 移动4位
                    if (wr_addr[3] == 1'b0) begin
                        // 不需要移动8位
                        wr_sel = 16'b0000000010000000;
                    end else begin
                        // 移动8位
                        wr_sel = 16'b1000000000000000;
                    end
                end
            end
        end
    end
endmodule