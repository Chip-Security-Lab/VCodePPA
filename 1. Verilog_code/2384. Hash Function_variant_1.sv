//SystemVerilog
// SystemVerilog
module hash_function #(parameter DATA_WIDTH = 32, HASH_WIDTH = 16) (
    input wire clk, rst_n, enable,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire last_block,
    output reg [HASH_WIDTH-1:0] hash_out,
    output reg hash_valid
);
    reg [HASH_WIDTH-1:0] hash_state;
    wire [HASH_WIDTH-1:0] data_xor;
    
    // Pre-compute XOR operation to reduce logic depth
    assign data_xor = data_in[15:0] ^ data_in[31:16];
    
    always @(posedge clk) begin
        // 定义控制变量用于case语句
        case ({rst_n, enable, last_block})
            3'b0_x_x: begin // 复位状态
                hash_state <= {HASH_WIDTH{1'b1}}; // Initial value
                hash_valid <= 1'b0;
            end
            3'b1_1_0: begin // 使能但不是最后一个块
                hash_state <= hash_state ^ data_xor;
                hash_valid <= 1'b0;
            end
            3'b1_1_1: begin // 使能且是最后一个块
                hash_state <= hash_state ^ data_xor;
                hash_valid <= 1'b1;
                hash_out <= hash_state ^ data_xor;
            end
            default: begin // 其他情况，保持状态不变
                hash_state <= hash_state;
                hash_valid <= hash_valid;
            end
        endcase
    end
endmodule