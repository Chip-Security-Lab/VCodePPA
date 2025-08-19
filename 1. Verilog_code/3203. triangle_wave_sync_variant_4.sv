//SystemVerilog
module triangle_wave_sync #(
    parameter DATA_WIDTH = 8
)(
    input clk_i,
    input sync_rst_i,
    input enable_i,
    output [DATA_WIDTH-1:0] wave_o
);
    reg [DATA_WIDTH-1:0] amplitude;
    reg up_down;
    
    // 定义控制状态编码
    localparam [1:0] RESET = 2'b00,
                     COUNT_UP = 2'b10,
                     COUNT_DOWN = 2'b11;
    
    // 组合状态变量
    wire [1:0] state = {up_down, enable_i};
    
    always @(posedge clk_i) begin
        case ({sync_rst_i, state})
            {1'b1, 2'bxx}: begin  // 复位状态
                amplitude <= {DATA_WIDTH{1'b0}};
                up_down <= 1'b1;
            end
            {1'b0, COUNT_UP}: begin  // 向上计数
                if (&amplitude) begin
                    up_down <= 1'b0;
                end else begin
                    amplitude <= amplitude + 1'b1;
                end
            end
            {1'b0, COUNT_DOWN}: begin  // 向下计数
                if (amplitude == {DATA_WIDTH{1'b0}}) begin
                    up_down <= 1'b1;
                end else begin
                    amplitude <= amplitude - 1'b1;
                end
            end
            default: begin  // enable_i为0时保持状态不变
                amplitude <= amplitude;
                up_down <= up_down;
            end
        endcase
    end
    
    assign wave_o = amplitude;
endmodule