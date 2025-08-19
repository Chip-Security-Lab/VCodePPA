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
    
    // 预计算下一个状态值，减少关键路径延迟
    wire [DATA_WIDTH-1:0] next_amplitude_up = amplitude + 1'b1;
    wire [DATA_WIDTH-1:0] next_amplitude_down = amplitude - 1'b1;
    
    // 使用更高效的比较逻辑
    wire at_max = &amplitude;
    wire at_min = ~|amplitude;
    
    always @(posedge clk_i) begin
        if (sync_rst_i) begin
            amplitude <= {DATA_WIDTH{1'b0}};
            up_down <= 1'b1;
        end else if (enable_i) begin
            // 优化比较链和判断逻辑
            case (up_down)
                1'b1: begin
                    amplitude <= next_amplitude_up;
                    if (at_max) up_down <= 1'b0;
                end
                1'b0: begin
                    amplitude <= next_amplitude_down;
                    if (at_min) up_down <= 1'b1;
                end
            endcase
        end
    end
    
    assign wave_o = amplitude;
endmodule