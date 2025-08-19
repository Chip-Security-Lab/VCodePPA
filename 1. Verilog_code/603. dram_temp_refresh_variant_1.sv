//SystemVerilog
// 温度系数计算子模块
module temp_coeff_calc #(
    parameter TEMP_COEFF = 50
)(
    input wire [7:0] temperature,
    output wire [15:0] temp_factor
);
    assign temp_factor = temperature * TEMP_COEFF;
endmodule

// 阈值计算子模块
module threshold_calc #(
    parameter BASE_CYCLES = 7800
)(
    input wire [15:0] temp_factor,
    output wire [15:0] threshold
);
    assign threshold = BASE_CYCLES + temp_factor;
endmodule

// 计数器子模块
module refresh_counter #(
    parameter CNT_WIDTH = 16
)(
    input wire clk,
    input wire [CNT_WIDTH-1:0] threshold,
    output reg refresh_req
);
    reg [CNT_WIDTH-1:0] counter;
    wire counter_at_threshold = (counter >= threshold);
    
    always @(posedge clk) begin
        refresh_req <= counter_at_threshold;
        counter <= counter_at_threshold ? {CNT_WIDTH{1'b0}} : counter + 1'b1;
    end
endmodule

// 顶层模块
module dram_temp_refresh #(
    parameter BASE_CYCLES = 7800,
    parameter TEMP_COEFF = 50
)(
    input wire clk,
    input wire [7:0] temperature,
    output wire refresh_req
);
    localparam CNT_WIDTH = $clog2(BASE_CYCLES + (255 * TEMP_COEFF)) + 1;
    
    wire [15:0] temp_factor;
    wire [15:0] threshold;
    
    temp_coeff_calc #(
        .TEMP_COEFF(TEMP_COEFF)
    ) temp_calc (
        .temperature(temperature),
        .temp_factor(temp_factor)
    );
    
    threshold_calc #(
        .BASE_CYCLES(BASE_CYCLES)
    ) thresh_calc (
        .temp_factor(temp_factor),
        .threshold(threshold)
    );
    
    refresh_counter #(
        .CNT_WIDTH(CNT_WIDTH)
    ) counter (
        .clk(clk),
        .threshold(threshold),
        .refresh_req(refresh_req)
    );
endmodule