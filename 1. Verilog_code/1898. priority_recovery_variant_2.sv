//SystemVerilog
module priority_recovery (
    input wire clk,
    input wire enable,
    input wire [7:0] signals,
    output reg [2:0] recovered_idx,
    output reg valid
);
    // 分别计算有效信号和索引
    reg next_valid;
    reg [2:0] next_idx;
    
    // 独立的有效信号检测逻辑
    always @(*) begin
        next_valid = |signals;
    end
    
    // 独立的优先编码逻辑
    always @(*) begin
        if (signals[7]) 
            next_idx = 3'd7;
        else if (signals[6]) 
            next_idx = 3'd6;
        else if (signals[5]) 
            next_idx = 3'd5;
        else if (signals[4]) 
            next_idx = 3'd4;
        else if (signals[3]) 
            next_idx = 3'd3;
        else if (signals[2]) 
            next_idx = 3'd2;
        else if (signals[1]) 
            next_idx = 3'd1;
        else 
            next_idx = 3'd0;
    end
    
    // 独立的valid信号时序逻辑
    always @(posedge clk) begin
        if (enable)
            valid <= next_valid;
        else
            valid <= 1'b0;
    end
    
    // 独立的recovered_idx时序逻辑
    always @(posedge clk) begin
        if (enable)
            recovered_idx <= next_idx;
        // 非使能时保持不变
    end
endmodule