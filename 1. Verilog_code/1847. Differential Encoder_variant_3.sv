//SystemVerilog
module differential_encoder (
    input  wire       clock,
    input  wire       reset,
    input  wire       enable,
    input  wire       data_input,
    output reg        diff_encoded
);
    reg prev_encoded;
    reg next_encoded;
    
    // 预计算控制信号
    wire reset_enabled = reset & enable;
    wire normal_operation = ~reset & enable;
    wire hold_state = ~reset & ~enable;
    
    // 优化组合逻辑路径
    always @(*) begin
        case ({reset, enable})
            2'b01: next_encoded = data_input ^ prev_encoded;
            2'b10, 2'b11: next_encoded = 1'b0;
            default: next_encoded = diff_encoded;
        endcase
    end
    
    // 时序逻辑优化
    always @(posedge clock) begin
        if (reset) begin
            diff_encoded <= 1'b0;
            prev_encoded <= 1'b0;
        end else if (enable) begin
            diff_encoded <= next_encoded;
            prev_encoded <= next_encoded;
        end
    end
endmodule