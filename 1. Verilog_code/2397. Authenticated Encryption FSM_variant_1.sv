//SystemVerilog
module auth_encrypt_fsm #(parameter DATA_WIDTH = 16) (
    input wire clk, rst_l,
    input wire start, data_valid,
    input wire [DATA_WIDTH-1:0] data_in, key, nonce,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg busy, done, auth_ok
);
    // State encoding
    localparam IDLE     = 3'b000;
    localparam INIT     = 3'b001;
    localparam PROCESS  = 3'b010;
    localparam FINALIZE = 3'b011;
    localparam VERIFY   = 3'b100;
    localparam COMPLETE = 3'b101;
    
    reg [2:0] state, next_state;
    reg [DATA_WIDTH-1:0] running_auth;
    
    // 合并了所有同步逻辑到一个always块
    always @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            auth_ok <= 0;
            running_auth <= 0;
            data_out <= 0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    busy <= 0;
                    done <= 0;
                    if (start) busy <= 1;
                end
                INIT: running_auth <= nonce ^ key;
                PROCESS: if (data_valid) begin
                    data_out <= data_in ^ key;
                    running_auth <= running_auth ^ data_in;
                end
                VERIFY: auth_ok <= (running_auth == data_in);
                COMPLETE: begin
                    busy <= 0;
                    done <= 1;
                end
                default: begin
                    // 保持输出稳定
                end
            endcase
        end
    end
    
    // 保留组合逻辑在单独的always块中，增强可读性并避免组合环路
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:     if (start) next_state = INIT;
            INIT:     next_state = PROCESS;
            PROCESS:  if (!data_valid) next_state = FINALIZE;
            FINALIZE: next_state = VERIFY;
            VERIFY:   next_state = COMPLETE;
            COMPLETE: next_state = IDLE;
            default:  next_state = IDLE;
        endcase
    end
endmodule