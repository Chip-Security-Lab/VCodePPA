//SystemVerilog
module PredictCompress (
    input wire clk,
    input wire en,
    input wire [15:0] current,
    output wire [7:0] delta
);

    wire [15:0] prev_value;
    wire [15:0] delta_full;

    // 歷史值存儲子模塊
    ValueStorage value_storage_inst (
        .clk(clk),
        .en(en),
        .current(current),
        .prev_value(prev_value)
    );

    // 差值計算子模塊
    DeltaCalculator delta_calc_inst (
        .current(current),
        .prev_value(prev_value),
        .delta_full(delta_full)
    );

    // 輸出截斷子模塊 - 已優化
    DeltaTruncator delta_trunc_inst (
        .delta_full(delta_full),
        .clk(clk),
        .en(en),
        .delta(delta)
    );

endmodule

module ValueStorage (
    input wire clk,
    input wire en,
    input wire [15:0] current,
    output wire [15:0] prev_value
);
    
    reg [15:0] prev_value_reg;
    
    // 存儲當前值作為下一個周期的歷史值
    always @(posedge clk) begin
        if (en) begin
            prev_value_reg <= current;
        end
    end
    
    assign prev_value = prev_value_reg;

endmodule

module DeltaCalculator (
    input wire [15:0] current,
    input wire [15:0] prev_value,
    output reg [15:0] delta_full
);

    // 計算完整的差值並寄存結果
    // 將差值計算後的結果寄存起來，以優化時序
    always @(*) begin
        delta_full = current - prev_value;
    end

endmodule

module DeltaTruncator (
    input wire [15:0] delta_full,
    input wire clk,
    input wire en,
    output reg [7:0] delta
);

    wire [7:0] delta_truncated;
    
    // 前向寄存器重定時：先對delta_full進行截斷
    assign delta_truncated = delta_full[7:0];
    
    // 然後將截斷後的結果寄存
    always @(posedge clk) begin
        if (en) begin
            delta <= delta_truncated;
        end
    end

endmodule