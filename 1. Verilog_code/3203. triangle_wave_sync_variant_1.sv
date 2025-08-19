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
    
    // 优化边界检测逻辑
    wire at_max = amplitude == {DATA_WIDTH{1'b1}};
    wire at_min = amplitude == {DATA_WIDTH{1'b0}};
    wire should_change_direction = (up_down & at_max) | (~up_down & at_min);
    
    // 优化计数器逻辑
    wire [DATA_WIDTH-1:0] amplitude_inc = amplitude + 1'b1;
    wire [DATA_WIDTH-1:0] amplitude_dec = amplitude - 1'b1;
    wire [DATA_WIDTH-1:0] next_amplitude = up_down ? amplitude_inc : amplitude_dec;
    
    always @(posedge clk_i) begin
        if (sync_rst_i) begin
            amplitude <= {DATA_WIDTH{1'b0}};
            up_down <= 1'b1;
        end else if (enable_i) begin
            amplitude <= next_amplitude;
            if (should_change_direction) begin
                up_down <= ~up_down;
            end
        end
    end
    
    assign wave_o = amplitude;
endmodule