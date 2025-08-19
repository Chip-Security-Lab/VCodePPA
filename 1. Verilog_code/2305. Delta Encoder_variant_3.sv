//SystemVerilog
module delta_encoder #(
    parameter WIDTH = 12
)(
    input                   clk_i,
    input                   en_i,
    input                   rst_i,
    input      [WIDTH-1:0]  data_i,
    output reg [WIDTH-1:0]  delta_o,
    output reg              valid_o
);
    reg [WIDTH-1:0] prev_sample;
    reg [WIDTH-1:0] delta_value;
    
    // 数据采样处理逻辑
    always @(posedge clk_i) begin
        if (rst_i) begin
            prev_sample <= {WIDTH{1'b0}};
        end else if (en_i) begin
            prev_sample <= data_i;
        end
    end
    
    // 增量计算逻辑
    always @(posedge clk_i) begin
        if (rst_i) begin
            delta_o <= {WIDTH{1'b0}};
        end else if (en_i) begin
            delta_o <= data_i - prev_sample;
        end
    end
    
    // 有效信号控制逻辑
    always @(posedge clk_i) begin
        if (rst_i) begin
            valid_o <= 1'b0;
        end else begin
            valid_o <= en_i;
        end
    end
    
endmodule