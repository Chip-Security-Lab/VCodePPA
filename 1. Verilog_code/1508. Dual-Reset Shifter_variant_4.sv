//SystemVerilog
// IEEE 1364-2005 Verilog
module dual_reset_shifter #(parameter WIDTH = 8) (
    input wire clk, sync_rst, async_rst, enable, data_in,
    output reg [WIDTH-1:0] data_out
);
    // 寄存器预计算控制信号
    reg [1:0] ctrl_reg;
    reg data_in_reg;
    reg [WIDTH-2:0] data_out_internal;
    
    // 将控制逻辑提前寄存，减少关键路径
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            ctrl_reg <= 2'b00;
            data_in_reg <= 1'b0;
        end
        else begin
            ctrl_reg <= {sync_rst, enable};
            data_in_reg <= data_in;
        end
    end
    
    // 重新组织数据路径，通过后向重定时优化
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            data_out_internal <= {(WIDTH-1){1'b0}};
            data_out[WIDTH-1:1] <= {(WIDTH-1){1'b0}};
            data_out[0] <= 1'b0;
        end
        else begin
            case (ctrl_reg)
                2'b10, 
                2'b11: begin
                    data_out_internal <= {(WIDTH-1){1'b0}};
                    data_out[WIDTH-1:1] <= {(WIDTH-1){1'b0}};
                    data_out[0] <= 1'b0;
                end
                2'b01: begin
                    data_out_internal <= data_out[WIDTH-2:0];
                    data_out[WIDTH-1:1] <= data_out_internal;
                    data_out[0] <= data_in_reg;
                end
                2'b00: begin
                    data_out_internal <= data_out[WIDTH-2:0];
                    data_out[WIDTH-1:1] <= data_out_internal;
                    data_out[0] <= data_out[0];
                end
                default: begin
                    data_out_internal <= data_out[WIDTH-2:0];
                    data_out[WIDTH-1:1] <= data_out_internal;
                    data_out[0] <= data_out[0];
                end
            endcase
        end
    end
endmodule