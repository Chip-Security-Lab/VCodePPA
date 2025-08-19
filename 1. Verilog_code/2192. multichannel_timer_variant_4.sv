//SystemVerilog
module multichannel_timer #(
    parameter CHANNELS = 4,
    parameter DATA_WIDTH = 16
)(
    input wire clock,
    input wire reset,
    input wire [CHANNELS-1:0] channel_en,
    input wire [DATA_WIDTH-1:0] timeout_values [CHANNELS-1:0],
    output reg [CHANNELS-1:0] timeout_flags,
    output reg [$clog2(CHANNELS)-1:0] active_channel
);
    reg [DATA_WIDTH-1:0] counters [CHANNELS-1:0];
    reg [CHANNELS-1:0] timeout_condition;
    reg [CHANNELS-1:0] update_needed;
    integer i;
    
    // 预计算比较结果和更新需求，降低关键路径深度
    always @(*) begin
        for (i = 0; i < CHANNELS; i = i + 1) begin
            timeout_condition[i] = channel_en[i] && (counters[i] >= timeout_values[i]);
            update_needed[i] = channel_en[i] && !timeout_condition[i];
        end
    end
    
    always @(posedge clock) begin
        if (reset) begin
            for (i = 0; i < CHANNELS; i = i + 1) begin
                counters[i] <= {DATA_WIDTH{1'b0}};
            end
            timeout_flags <= {CHANNELS{1'b0}};
            active_channel <= {$clog2(CHANNELS){1'b0}};
        end else begin
            // 默认状态下保持timeout_flags不变
            // 减少不必要的更新操作
            
            // 优先处理timeout条件
            for (i = 0; i < CHANNELS; i = i + 1) begin
                if (timeout_condition[i]) begin
                    counters[i] <= {DATA_WIDTH{1'b0}};
                    timeout_flags[i] <= 1'b1;
                    active_channel <= i[$clog2(CHANNELS)-1:0];
                end else if (update_needed[i]) begin
                    counters[i] <= counters[i] + 1'b1;
                    timeout_flags[i] <= 1'b0;
                end
            end
        end
    end
endmodule