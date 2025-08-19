module cam_3_axi_stream (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [7:0] data_in,
    output wire tvalid,
    input wire tready,
    output wire [7:0] tdata,
    output wire tlast
);
    reg [7:0] stored_data;
    reg valid_reg;
    wire match;
    
    // 优化后的比较器实例化
    comparator_3 comp (
        .a(stored_data),
        .b(data_in),
        .match(match)
    );

    // 直接赋值简单信号
    assign tdata = stored_data;
    assign tlast = 1'b1;
    
    // 优化tvalid赋值，减少关键路径长度
    assign tvalid = valid_reg;

    // 优化控制逻辑，使用case结构
    always @(posedge clk) begin
        if (rst) begin
            stored_data <= 8'b0;
            valid_reg <= 1'b0;
        end else begin
            // 使用{write_en, tready}作为case条件
            case({write_en, tready})
                2'b11: begin  // write_en=1, tready=1
                    stored_data <= data_in;
                    valid_reg <= 1'b1;
                end
                2'b01: begin  // write_en=0, tready=1
                    valid_reg <= 1'b0;
                end
                default: begin
                    // 保持当前状态
                end
            endcase
        end
    end
endmodule

module comparator_3 (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire match  // 改为wire类型，消除不必要的always块
);
    // 直接赋值比较结果，减少逻辑层级
    assign match = (a == b);
endmodule