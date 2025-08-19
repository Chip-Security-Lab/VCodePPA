//SystemVerilog
module binary_to_onehot_sync #(parameter ADDR_WIDTH = 4) (
    input                       clk,
    input                       rst_n,
    input                       enable,
    input      [ADDR_WIDTH-1:0] binary_in,
    output reg [2**ADDR_WIDTH-1:0] onehot_out
);
    // 定义控制状态变量
    reg [1:0] ctrl_state;
    
    // 编码控制状态
    localparam RESET_STATE = 2'b00;
    localparam ENABLE_STATE = 2'b01;
    localparam HOLD_STATE = 2'b10;
    
    // 生成控制状态
    always @(*) begin
        if (!rst_n)
            ctrl_state = RESET_STATE;
        else if (enable)
            ctrl_state = ENABLE_STATE;
        else
            ctrl_state = HOLD_STATE;
    end
    
    // 使用case语句处理不同状态
    always @(posedge clk) begin
        case (ctrl_state)
            RESET_STATE: 
                onehot_out <= {(2**ADDR_WIDTH){1'b0}};
            ENABLE_STATE: 
                onehot_out <= {{(2**ADDR_WIDTH-1){1'b0}}, 1'b1} << binary_in;
            HOLD_STATE: 
                onehot_out <= onehot_out;
            default: 
                onehot_out <= {(2**ADDR_WIDTH){1'b0}};
        endcase
    end
endmodule